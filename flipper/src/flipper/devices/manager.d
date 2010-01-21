module flipper.devices.manager;

import chisel.core.all;
import chisel.ui.all;

import flipper.devices.imports;
import flipper.devices.device;

version (Tango) {
	import tango.io.Stdout;
}

import usb.all;

interface FlipperDeviceNotify {
	void deviceWillRemove( Device device );
}

class DeviceManager {
	struct MatchUSB {
		char[] name;
		
		ushort usbVendorId;
		ushort usbProductId;
		
		ClassInfo classInfo;
	}
	
	// list of all USB devices able to be matched
	static DeviceManager.MatchUSB[] usbDeviceMatches;
	
	// current list of matched devices
	static Device[USBDevice] matchedDevices = null;
	
	static void cleanup( ) {
		foreach ( udev, dev; matchedDevices ) {
			delete dev;
		}
	}
	
	static void addUSBDeviceMatch( DeviceManager.MatchUSB usbMatch ) {
		usbDeviceMatches ~= usbMatch;
	}
	
	static void enumerateUSBDevices( ) {
		Device[USBDevice] disconnectedDevices;
		
		// make a copy of the current devices
		foreach ( usbdev, flipdev; matchedDevices ) {
			disconnectedDevices[usbdev] = flipdev;
		}
		
		foreach ( bus; USB.busses ) {
			foreach ( dev; bus.devices ) {
				auto desc = dev.descriptor;
				
				// if we already know about it, mark that it still exists
				if ( dev in matchedDevices ) {
					disconnectedDevices.remove( dev );
					continue;
				}
				
				foreach ( deviceMatch; usbDeviceMatches ) {
					ushort vendorId = deviceMatch.usbVendorId;
					ushort productId = deviceMatch.usbProductId;
					
					if ( desc.idVendor == vendorId || desc.idProduct == productId ) {
						
						version (Tango) Stdout.formatln( "Found match: {}!", deviceMatch.name );
						Device flipperDev = cast(Device)deviceMatch.classInfo.create( );
						flipperDev.usbDevice = dev;
						matchedDevices[dev] = flipperDev;
						
						break;
					}
				}
			}
		}
		
		FlipperDeviceNotify app = cast(FlipperDeviceNotify)Application.sharedApplication;
		
		foreach ( usbdev, flipdev; disconnectedDevices ) {
			version (Tango) Stdout.formatln( "Disconnected device: {}", flipdev );
			
			app.deviceWillRemove( flipdev );
			
			matchedDevices.remove( usbdev );
			flipdev.usbDisconnected( usbdev );
			delete flipdev;
		}
		
		generateIndexes( );
	}
	
	// a list of devices, in order (indexed)
	static Device[] deviceList;
	static void generateIndexes( ) {
		int i = 0;
		deviceList.length = matchedDevices.length;
		foreach ( usbdev, flipdev; matchedDevices ) {
			deviceList[i] = flipdev;
			i++;
		}
	}
}

// TreeView DataSource for DeviceManager's data
class DeviceManagerDataSource : TreeViewDataSource {
	uint numberOfChildrenOfItem( TreeView treeView, Object item ) {
		if ( item is null ) {
			return DeviceManager.deviceList.length;
		}
		
		return 0;
	}
	
	bool isItemExpandable( TreeView treeView, Object item ) {
		return numberOfChildrenOfItem( treeView, item ) > 0; // no restrictions
	}
	
	Object childAtIndex( TreeView treeView, Object parent, uint index ) {
		if ( parent is null ) {
			return DeviceManager.deviceList[index];
		}
		
		Device device = cast(Device)parent;
		
		return null; // shouldn't happen right now
	}
	
	CObject valueForTableColumn( TreeView treeView, Object item, TableColumn column ) {
		Device device = cast(Device)item;
		
		if ( device !is null ) {
			return String.fromUTF8( device.name );
		}
		
		assert( false );
	}
}
