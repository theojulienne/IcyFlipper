module flipper.ui;

import chisel.core.all;
import chisel.ui.all;

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
	}
	
	void onWindowClose( ) {
		stop( );
	}
}

int main( char[][] argv ) {
	auto app = new FlipperApp( );
	app.run( );
	
	return 0;
}
