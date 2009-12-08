module flipper.ui;

version (Tango) {
	import tango.io.Stdout;
	import tango.time.StopWatch;
} else {
	import std.date;
	import std.stdio;

	struct StopWatch {
        d_time start_time;
        
        void start( ) {
            start_time = getUTCtime( );
        }
        
        void stop( ) {
        
        }
        
        ulong microsec( ) {
            d_time curr_time = getUTCtime( );
            return (curr_time - start_time) * 1000000 / TicksPerSecond;
        }
    }

}

import usb.all;

import chisel.core.all;
import chisel.ui.all;

import flipper.devices.manager;
import flipper.devices.device;

class FlipperApp : Application {
	Window mainWindow;
	
	StackView stackView;
	
	TreeView deviceTree;
	
	//Frame deviceFrame;
	
	static const int WindowDefaultWidth = 700;
	static const int WindowDefaultHeight = 500;
	
	static const int DeviceTreeDefaultWidth = 180;
	
	this( ) {
		applicationName = "Flipper";
		
		mainWindow = new Window( "Flipper" );
		mainWindow.setSize( WindowDefaultWidth, WindowDefaultHeight );
		
		// create a splitter
		stackView = new StackView( StackDirection.Horizontal );
		stackView.padding = 16;
		
		// add a treeview to the left of the splitview
		auto deviceTreeFrame = new Frame( "Devices" );
		deviceTreeFrame.border = false;
		deviceTree = new TreeView( );
		deviceTree.dataSource = new DeviceManagerDataSource( );
		deviceTreeFrame.contentView = deviceTree;
		deviceTree.onSelectionChanged += &deviceSelectionChanged;
		stackView.addSubview( deviceTreeFrame );
		stackView.setSize( deviceTreeFrame, DeviceTreeDefaultWidth );
		
		auto col = new TableColumn( "Devices" );
		deviceTree.addTableColumn( col );
		deviceTree.outlineTableColumn = col;
		
		// add a frame to the right of the splitview
		//deviceFrame = new Frame( "Device Information" );
		//stackView.addSubview( deviceFrame );
		
		// attach the splitter as the contentView for the window
		mainWindow.contentView = stackView;
		
		// size the splitter's divider to a decent size for the tree
		//stackView.setProportion( deviceFrame, 1 );
		
		// attach window closer handler and make visible
		mainWindow.onClose += &onWindowClose;
		mainWindow.show( );
		
		// enumerate all devices, then enable the 0.5s enumeration routine
		doUSBEnumeration( );
		this.useIdleTask = true;
		lastEnumeration.start;
	}
	
	void onWindowClose( ) {
		stop( );
	}
	
	StopWatch lastEnumeration;
	const int EnumerationFrequencyUS = 2000000;
	
	void idleTask( ) {
		//printf( "idle\n" );
		if ( lastEnumeration.microsec > EnumerationFrequencyUS ) {
			doUSBEnumeration( );
		}
	}
	
	void doUSBEnumeration( ) {
		USB.findUSBBusses( );
		int devChange = USB.findDevices( );
		if ( devChange != 0 ) {
			DeviceManager.enumerateUSBDevices( );
			deviceTree.reloadData( );
		}
		
		lastEnumeration.stop( );
		lastEnumeration.start( );
	}
	
	Device selectedDevice;
	View currentDevicePanel;
	
	void deviceWillRemove( Device device ) {
		assert( device !is null );
		
		if ( selectedDevice is device ) {
			version (Tango) Stdout.formatln( "Active device has been disconnected!" );
			
			if ( currentDevicePanel !is null ) {
				currentDevicePanel.removeFromSuperview( );
				currentDevicePanel = null;
			}
			
			selectedDevice = null;
		}
	}
	
	void deviceSelectionChanged( Event e ) {
		auto rows = deviceTree.selectedRows;
		
		// hide the current panel
		if ( currentDevicePanel !is null ) {
			currentDevicePanel.removeFromSuperview( );
			currentDevicePanel = null;
		}
		
		if ( rows.length == 0 ) {
			return;
		}
		
		selectedDevice = cast(Device)rows[0];
		
		assert( currentDevicePanel is null );
		
		// get the board's information panel and add it to the view
		currentDevicePanel = selectedDevice.devicePanel( );
		stackView.addSubview( currentDevicePanel );
		stackView.setProportion( currentDevicePanel, 1 );
		
		version (Tango)
			Stdout.formatln( "Selection changed: {} (panel={})", selectedDevice, currentDevicePanel );
		else
			writefln( "Selection changed: %s", selectedDevice );
	}
}

int main( char[][] argv ) {
	
	ClassInfo inf = FlipperApp.classinfo;
	
	FlipperApp app = cast(FlipperApp)inf.create( );
	app.run( );
	
	DeviceManager.cleanup( );
	
	//Stdout.formatln( "Classinfo: {}",  );
	
	return 0;
	
	//auto app = new FlipperApp( );
	//app.run( );
	
	return 0;
}
