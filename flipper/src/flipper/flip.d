module flipper.flip;

version (Tango) {
	import tango.io.Stdout;
	import tango.time.StopWatch;
	import tango.stdc.stdlib;
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

class QuickFlipApp : Application, FlipperDeviceNotify {
	Window mainWindow;
	
	StackView stackView;
	
	TreeView deviceTree;
	
	//Frame deviceFrame;
	
	static const int WindowDefaultWidth = 400;
	static const int WindowDefaultHeight = 250;
	
	char[] programFilename;
	bool flipCompleted = false;
	
	Button btnSelectTarget;
	
	this( char[] program ) {
		applicationName = "Flipper";
		
		programFilename = program;
		
		mainWindow = new Window( "Flipper" );
		mainWindow.setSize( WindowDefaultWidth, WindowDefaultHeight );
		
		stackView = new StackView( StackDirection.Vertical );
		stackView.padding = 16;
		
		// add a treeview to the left of the splitview
		deviceTree = new TreeView( );
		deviceTree.dataSource = new DeviceManagerDataSource( );
		deviceTree.onSelectionChanged += &deviceSelectionChanged;
		
		auto col = new TableColumn( "Devices" );
		deviceTree.addTableColumn( col );
		deviceTree.outlineTableColumn = col;
		
		stackView.addSubview( deviceTree );
		stackView.setProportion( deviceTree, 1 );
		
		btnSelectTarget = new Button( "Select Target" );
		btnSelectTarget.enabled = false;
		btnSelectTarget.onPress += &useSelectedDevice;
		stackView.addSubview( btnSelectTarget );
		
		// attach the splitter as the contentView for the window
		mainWindow.contentView = stackView;
		
		// attach window closer handler
		mainWindow.onClose += &onWindowClose;
		
		// enumerate all devices, then enable the 0.5s enumeration routine
		doUSBEnumeration( );
		this.useIdleTask = true;
		lastEnumeration.start;
		
		int numMatches = DeviceManager.matchedDevices.length;
		
		if ( numMatches == 1 ) {
			foreach ( usbdev, dev; DeviceManager.matchedDevices ) {
				beginUploadWithDevice( dev );
			}
		} else {
			// now that enumeration is complete, show the window
			mainWindow.show( );
		}
	}
	
	ProgressBar uploadProgress;
	Label uploadStatus;
	
	void useSelectedDevice( Event e ) {
		beginUploadWithDevice( selectedDevice );
	}
	
	void beginUploadWithDevice( Device device ) {
		stackView = new StackView( StackDirection.Vertical );
		stackView.padding = 16;
		
		Frame frame = new Frame( "Programming" );
		
		auto progView = new StackView( StackDirection.Vertical );
		progView.padding = 16;
		uploadStatus = new Label( "Waiting for upload..." );
		progView.addSubview( uploadStatus );
		uploadProgress = new ProgressBar( ProgressBarType.Horizontal );
		uploadProgress.indeterminate = false;
		uploadProgress.value = 0;
		progView.addSubview( uploadProgress );
		
		frame.contentView = progView;
		
		stackView.addSubview( frame );
		stackView.setProportion( frame, 1 );
		
		mainWindow.contentView = stackView;
		
		float height = frame.sizeHint.suggestedSize.height + (32);
		mainWindow.setSize( WindowDefaultWidth, height );
		mainWindow.show( );
		
		SimpleProgramming simpleProg = cast(SimpleProgramming)device;
		simpleProg.simpleProgramDevice( programFilename, uploadProgress, uploadStatus );
		
		uploadStatus.text = "Upload Complete!";
		uploadProgress.animating = false;
		uploadProgress.indeterminate = false;
		
		mainWindow.close( );
		
		flipCompleted = true;
		stop( );
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
		/*currentDevicePanel = selectedDevice.devicePanel( );
		stackView.addSubview( currentDevicePanel );
		stackView.setProportion( currentDevicePanel, 1 );*/
		btnSelectTarget.enabled = true;
		
		version (Tango)
			Stdout.formatln( "Selection changed: {} (panel={})", selectedDevice, currentDevicePanel );
		else
			writefln( "Selection changed: %s", selectedDevice );
	}
}

int main( char[][] args ) {
	if ( args.length != 2 ) {
		version (Tango)
			Stdout.formatln( "Usage: {} <flash.(bin|hex)>", args[0] );
		else
			writefln( "Usage: %s <flash.(bin|hex)>", args[0] );
		return 0;
	}
	
	char[] program = args[1];
	
	QuickFlipApp app = new QuickFlipApp( program );
	
	if ( !app.flipCompleted )
		app.run( );
	
	DeviceManager.cleanup( );
	
	return 0;
}
