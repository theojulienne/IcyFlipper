module flipper.ui;

import tango.io.Stdout;
import tango.time.StopWatch;

import usb.all;

import chisel.core.all;
import chisel.ui.all;

import flipper.devices.manager;

class FlipperApp : Application {
	Window mainWindow;
	
	StackView stackView;
	
	TreeView deviceTree;
	
	Frame deviceFrame;
	
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
		stackView.addSubview( deviceTreeFrame );
		stackView.setSize( deviceTreeFrame, DeviceTreeDefaultWidth );
		
		auto col = new TableColumn( "Devices" );
		deviceTree.addTableColumn( col );
		deviceTree.outlineTableColumn = col;
		
		// add a frame to the right of the splitview
		deviceFrame = new Frame( "Device Information" );
		stackView.addSubview( deviceFrame );
		
		// attach the splitter as the contentView for the window
		mainWindow.contentView = stackView;
		
		// size the splitter's divider to a decent size for the tree
		//stackView.setDividerPosition( 0, DeviceTreeDefaultWidth );
		stackView.setProportion( deviceFrame, 1 );
		
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
	const int EnumerationFrequencyUS = 5000000;
	
	void idleTask( ) {
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
}

int main( char[][] argv ) {
	
	ClassInfo inf = FlipperApp.classinfo;
	
	FlipperApp app = cast(FlipperApp)inf.create( );
	app.run( );
	
	//Stdout.formatln( "Classinfo: {}",  );
	
	return 0;
	
	//auto app = new FlipperApp( );
	//app.run( );
	
	return 0;
}
