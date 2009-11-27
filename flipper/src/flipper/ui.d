module flipper.ui;

import usb.all;

import chisel.core.all;
import chisel.ui.all;

import tango.io.Stdout;

class FlipperApp : Application {
	Window mainWindow;
	
	SplitView splitView;
	
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
		splitView = new SplitView( SplitterStacking.Horizontal );
		
		// add a treeview to the left of the splitview
		deviceTree = new TreeView( );
		splitView.addSubview( deviceTree );
		
		auto col = new TableColumn( "Device Tree" );
		deviceTree.addTableColumn( col );
		deviceTree.outlineTableColumn = col;
		
		// add a frame to the right of the splitview
		deviceFrame = new Frame( "Device Information" );
		splitView.addSubview( deviceFrame );
		
		// attach the splitter as the contentView for the window
		mainWindow.contentView = splitView;
		
		// size the splitter's divider to a decent size for the tree
		splitView.setDividerPosition( 0, DeviceTreeDefaultWidth );
		
		// attach window closer handler and make visible
		mainWindow.onClose += &onWindowClose;
		mainWindow.show( );
		
		this.useIdleTask = true;
	}
	
	void onWindowClose( ) {
		stop( );
	}
	
	void idleTask( ) {
		USB.findUSBBusses( );
		int devChange = USB.findDevices( );
		if ( devChange != 0 ) {
			Stdout.formatln( "USB change: {} devices", devChange );
		}
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
