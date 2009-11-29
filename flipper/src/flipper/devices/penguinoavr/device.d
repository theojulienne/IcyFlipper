module flipper.devices.penguinoavr.device;

import tango.io.Stdout;

import flipper.devices.device;
import flipper.devices.manager;

static this( ) {
	// all setup should be done in installDeviceClass()
	installDeviceClass( );
}

/* this function must be named installDeviceClass, in case
 * it is used by dynamic library loading at a later date
 */ 
extern (C) void installDeviceClass( ) {
	static DeviceManager.MatchUSB matcher = {
		name: "Penguino AVR",
		usbVendorId: 0x16D0,
		usbProductId: 0x04CA,
		classInfo: PenguinoAVRDevice.classinfo,
	};
	
	DeviceManager.addUSBDeviceMatch( matcher );
}

class PenguinoAVRDevice : Device {
	this( ) {
		Stdout.formatln( "Penguino AVR Device constructor" );
	}
	
	void usbDevice( USBDevice dev ) {
		Device.usbDevice( dev );
		
		Stdout.formatln( "Penguino AVR now has a USB device!" );
	}
	
	char[] name( ) {
		return "Penguino AVR";
	}
}
