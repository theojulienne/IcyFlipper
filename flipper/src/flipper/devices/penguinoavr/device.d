module flipper.devices.penguinoavr.device;

version (Tango) {
	import tango.io.Stdout;
	import tango.io.FileConduit;
	import tango.io.Conduit;
} else {
	import std.stdio;
	import std.stream;
}

import flipper.devices.device;
import flipper.devices.manager;
import flipper.protocols.jtag;
import flipper.chips.avr;
import flipper.flash.avrflash;
import flipper.memory;
import flipper.program;

import chisel.core.all;
import chisel.ui.all;

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

class PenguinoAVRDevice : Device, SimpleProgramming {
	View _devicePanel;
	
	PenprogInterface penprog;
	IJTAG ijtag;
	TAPStateMachine sm;
	
	ProgressBar uploadProgress;
	Label uploadStatus;
	
	this( ) {
		version (Tango) Stdout.formatln( "Penguino AVR Device constructor" );
	}
	
	~this( ) {
		if ( penprog !is null ) {
			delete penprog;
		}
	}
	
	void usbDisconnected( USBDevice dev ) {
		Device.usbDisconnected( dev );
		
		penprog.usbDisconnected( dev );
	}
	
	void usbDevice( USBDevice dev ) {
		Device.usbDevice( dev );
		
		penprog = new PenprogInterface( dev );
		ijtag = cast(IJTAG)penprog;
		sm = new TAPStateMachine( ijtag );
		
		version (Tango) Stdout.formatln( "Penguino AVR now has a USB device!" );
		
		assert( verifyParts( ), "Could not verify the chip on the attached Penguino AVR" );
		
		enumerateChips( );
	}
	
	void enumerateChips( ) {
		auto chip = new AVRChip( this.sm );
		
		// Penguino AVR contains an ATMega32A with 32KB flash
		chip.addMemory( "flash", new AVRFlash( chip, 32*1024 ) );
		
		chips["user"] = chip;
	}
	
	View createProgrammingTab( ) {
		auto progView = new StackView( StackDirection.Vertical );
		progView.padding = 16;
		auto uploadButton = new Button( "Upload Flash..." );
		uploadButton.onPress += &uploadPrompt;
		progView.addSubview( uploadButton );
		uploadStatus = new Label( "Waiting for upload..." );
		progView.addSubview( uploadStatus );
		uploadProgress = new ProgressBar( ProgressBarType.Horizontal );
		uploadProgress.indeterminate = false;
		uploadProgress.value = 0;
		progView.addSubview( uploadProgress );
		
		return progView;
	}
	
	View createAdvancedTab( ) {
		auto infoView = new StackView( StackDirection.Vertical );
		infoView.padding = 16;
		
		
		char[][] lines = [
			"WARNING: Resetting to DFU mode should only be used when updating",
			"the firmware on the Penguino, and should only be attempted by",
			"advanced users at this time."
		];
		auto warningView = new StackView( StackDirection.Vertical );
		foreach ( line; lines )
			warningView.addSubview( new Label( line  ) );
		infoView.addSubview( warningView );
		
		auto dfuButton = new Button( "Reset to DFU mode" );
		dfuButton.onPress += &penprog.enterDFUMode;
		infoView.addSubview( dfuButton );
		
		return infoView;
	}
	
	CheckBox BOOTRST, BOOTSZ0, BOOTSZ1;
	
	const int BIT_BOOTRST = 0x01;
	const int BIT_BOOTSZ0 = 0x02;
	const int BIT_BOOTSZ1 = 0x04;
	
	View createFuseTab( ) {
		auto infoView = new StackView( StackDirection.Vertical );
		infoView.padding = 16;
		
		infoView.addSubview( new Label( "Checks below reflect a setting of '1', which means unprogrammed." ) );
		infoView.addSubview( new Label( "See ATMega32A datasheet for details." ) );
		
		BOOTSZ0 = new CheckBox( "BOOTSZ0" );
		infoView.addSubview( BOOTSZ0 );
		
		BOOTSZ1 = new CheckBox( "BOOTSZ1" );
		infoView.addSubview( BOOTSZ1 );
		
		BOOTRST = new CheckBox( "BOOTRST" );
		infoView.addSubview( BOOTRST );
		
		ubyte fuseByte = readFuseH( );
		
		BOOTRST.checked = ( fuseByte & BIT_BOOTRST ) != 0;
		BOOTSZ0.checked = ( fuseByte & BIT_BOOTSZ0 ) != 0;
		BOOTSZ1.checked = ( fuseByte & BIT_BOOTSZ1 ) != 0;
		
		return infoView;
	}
	
	ubyte generateHighFuse( ubyte rest ) {
		ubyte ret = rest & 0xf8;
		
		if ( BOOTRST.checked )
			ret |= BIT_BOOTRST;
		
		if ( BOOTSZ0.checked )
			ret |= BIT_BOOTSZ0;
		
		if ( BOOTSZ1.checked )
			ret |= BIT_BOOTSZ1;
		
		return ret;
	}
	
	ubyte readFuseH( ) {
		AVRChip chip = cast(AVRChip)chips["user"];
		
		ubyte b = chip.ReadFuseH( );
		
		chip.exitProgMode( );
		
		return b;
	}
	
	void writeFuseH( ubyte b ) {
		AVRChip chip = cast(AVRChip)chips["user"];
		
		chip.WriteFuseH( b );
		
		chip.exitProgMode( );
	}
	
	void createDevicePanel( ) {
		auto tabView = new TabView( );
		
		//auto deviceInfoTab = new TabViewItem( "Information" );
		//tabView.appendItem( deviceInfoTab );
		
		auto progTab = new TabViewItem( "Programming" );
		progTab.contentView = createProgrammingTab( );
		tabView.appendItem( progTab );
		
		auto fuseTab = new TabViewItem( "Configuration" );
		fuseTab.contentView = createFuseTab( );
		tabView.appendItem( fuseTab );
		
		auto advancedTab = new TabViewItem( "Advanced" );
		advancedTab.contentView = createAdvancedTab( );
		tabView.appendItem( advancedTab );
		
		_devicePanel = tabView;
	}
	
	View devicePanel( ) {
		if ( _devicePanel is null ) {
			createDevicePanel( );
		}
		
		assert( _devicePanel !is null );
		
		return _devicePanel;
	}
	
	char[] name( ) {
		return "Penguino AVR";
	}
	
	bool verifyParts( ) {
		this.testReset = true;
		scope(exit) this.testReset = false;
		
		sm.GotoState( TAPState.TestLogicReset );
		sm.GotoState( TAPState.ShiftDR );
		
		// should only be 1 part in a penguino avr
		TAPResponse response = sm.SendCommand( TAPCommand.ReceiveData( 32 ) );
		uint id = response.GetUInt32( );
		TAPDeviceIDRegister reg = TAPDeviceIDRegister.ForID( id );
		
		version (Tango) {
			Stdout.format( "IDCODE = {0}: {1}", id, reg.toString ).newline;
		} else {
			writefln( "IDCODE = %s: %s\n", id, reg );
		}
		
		if ( id != 0x8950203f ) {
			return false;
		}
		
		return true;
	}
	
	private bool _systemReset = false;
	private bool _testReset = false;
	
	void systemReset( bool sr ) {
		assert( ijtag !is null );
		
		if ( _systemReset != sr ) {
			_systemReset = sr;
		
			ijtag.JTAGReset( _systemReset, _testReset );
			
			version (Tango) {
				Stdout.formatln( "reset: sys={} test={}", _systemReset, _testReset );
			} else {
				writefln( "reset: sys=%s test=%s", _systemReset, _testReset );
			}
		}
	}
	
	void testReset( bool tr ) {
		assert( ijtag !is null );
		
		if ( _testReset != tr ) {
			_testReset = tr;
		
			ijtag.JTAGReset( _systemReset, _testReset );
			
			version (Tango) {
				Stdout.formatln( "reset: sys={} test={}", _systemReset, _testReset );
			} else {
				writefln( "reset: sys=%s test=%s", _systemReset, _testReset );
			}
		}
	}
	
	void uploadPrompt( ) {
		FileOpenChooser chooser = new FileOpenChooser;
		
		chooser.onCompleted += &openDialogCompleted;
		chooser.allowsMultipleSelection = false;
		chooser.allowedFileTypes = [ "bin" ];
		
		chooser.beginModal( _devicePanel.window );
	}
	
	void openDialogCompleted( Event e ) {
		FileOpenChooser chooser = cast(FileOpenChooser)e.target;
		
		String[] paths = chooser.chosenPaths;
		
		if ( !chooser.fileWasChosen || chooser.chosenPaths.length == 0 ) {
			return;
		}
		
		String path = paths[0];
		
		simpleProgramDevice( path.toString, uploadProgress, uploadStatus );
		doFuseBits( );
	}
	
	void simpleProgramDevice( char[] path, ProgressBar simpleUploadProgress, Label simpleUploadStatus ) {
		version (Tango) {
			version (Tango) Stdout.formatln( "Uploading: {}", path );
		} else {
			writefln( "Uploading: %s", path );
		}
		
		auto uploadTarget = "flash";
		
		Memory targetMemory = chips["user"].getMemory( uploadTarget );
		assert( targetMemory !is null );
		
		// AVR flashingness
		
		/*version (Tango) {
			File file = new File( path.toString );
		} else {
			Stream file = new BufferedFile( path.toString, FileMode.In );
		}
		
		if ( file is null )
			return;
		
		version (Tango) {
			int sourceBytes = file.length;
		} else {
			int sourceBytes = file.size;
		}*/
		Program program = Program.load( path );
		
		if ( program is null )
			return;
		
		int sourceBytes = program.totalBytes;
		
		//Stdout.newline;
		//version (Tango) Stdout.format( "Erasing {0}...", uploadTarget ).newline;
		simpleUploadStatus.text = "Erasing " ~ uploadTarget ~ "...";
		targetMemory.erase( );
		
		void reportOperationProgress( uint bytesCompleted ) {
			if ( bytesCompleted > sourceBytes )
				bytesCompleted = sourceBytes;
			
			simpleUploadProgress.maxValue = sourceBytes;
			simpleUploadProgress.value = bytesCompleted;
		}
		
		//Stdout.newline.newline;
		//version (Tango) Stdout.format( "Writing {0}...", uploadTarget ).newline;
		//Stdout( " ~ starting ~ " );
		simpleUploadStatus.text = "Writing " ~ uploadTarget ~ "...";
		targetMemory.writeStream( program, &reportOperationProgress );
		
		//Stdout.newline.newline;
		//version (Tango) Stdout.format( "Verifying {0}...", uploadTarget ).newline;
		//Stdout( " ~ starting ~ " );
		simpleUploadStatus.text = "Verifying " ~ uploadTarget ~ "...";
		targetMemory.verifyStream( program, &reportOperationProgress );
		
		targetMemory.finished( );
	}
	
	void doFuseBits( ) {
		uploadStatus.text = "Preparing for post-flashing...";
		uploadProgress.indeterminate = true;
		uploadProgress.animating = true;
		
		AVRChip chip = cast(AVRChip)chips["user"];
		
		uploadStatus.text = "Updating fuse bit (L)...";
		/*version (Tango) {
			Stdout.formatln( "ReadFuseL() = {}", chip.ReadFuseL( ) );
		} else {
			writefln( "ReadFuseL() = %s", chip.ReadFuseL( ) );
		}*/
		chip.WriteFuseL( 0xEF );
		
		uploadStatus.text = "Updating fuse bit (H)...";
		/*version (Tango) {
			Stdout.formatln( "ReadFuseH() = {}", chip.ReadFuseH( ) );
		} else {
			writefln( "ReadFuseH() = %s", chip.ReadFuseH( ) );
		}*/
		ubyte highFuse = generateHighFuse( 0x88 );
		Stdout.formatln( "Writing fuse high byte: {}", highFuse );
		chip.WriteFuseH( highFuse );
		
		chip.exitProgMode( );
		
		uploadStatus.text = "Upload Complete!";
		uploadProgress.animating = false;
		uploadProgress.indeterminate = false;
	}
}



class PenprogInterface : IJTAG {
	const byte jtagCommandGetBoard = 0x01;
	const byte jtagCommandReset = 0x02;
	const byte jtagCommandJumpBootloader = 0x03;

	const byte jtagCommandClockBit = 0x20;
	const byte jtagCommandClockBits = 0x21;
	
	
	const uint USBVendorId = 0x03EB;
	const uint USBProductId = 0x2018;
	
	const int jtagBulkIn = 0x83;
	const int jtagBulkOut = 0x03;
	
	const int jtagInterface = 2;
	
	USBDevice _device;
	
	this( USBDevice dev ) {
		this.device = dev;
	}
	
	~this( ) {
		version (Tango) {
			Stdout.formatln( "Releasing interface..." );
		} else {
	    	writefln( "Releasing interface..." );
		}
		
		if ( _device !is null ) {
			_device.releaseInterface( jtagInterface );
		}
	}
	
	void usbDisconnected( USBDevice dev ) {
		assert( dev is _device );
		_device = null;
	}
	
	void device( USBDevice dev ) {
		_device = dev;
		
		_device.open( );
		
		// set timeout
		// set configuration on win32
		version (Windows) {
			_device.configuration = 1;
		}
		
		// claim interface
		_device.claimInterface( jtagInterface );
	}
	
	USBDevice device( ) {
		return _device;
	}
	
	public void JTAGReset( bool systemReset, bool testReset ) {
		ubyte[32] bytes;
		int ret;
		
		bytes[0] = jtagCommandReset; // RESET
		bytes[1] = (systemReset ? 1 : 0);
		bytes[2] = (testReset ? 1 : 0);
		
		while ( (ret = device.bulkWrite( jtagBulkOut, bytes )) != bytes.length ) {
			version (Tango) {
				
			} else {
				writefln( "RST: USB Bulk Write failed (%s), retrying...", ret ); // loopies
			}
			
			//System.Threading.Thread.Sleep( 100 );
		}
		
		while ( (ret = device.bulkRead( jtagBulkIn, bytes )) != bytes.length ) {
			version (Tango) {
				
			} else {
				writefln( "RST: USB Bulk Read failed (%s), retrying...", ret ); // loopies
			}
			
			//System.Threading.Thread.Sleep( 100 );
		}
	}
	
	struct ClockBitsOutData {
		ubyte[30] data;
		
		void setBit( int bitNum, bool dataBit, bool tmsBit ) {
			int bitOffset = ((bitNum%4)*2);
			
			data[bitNum/4] &= ~(0x3 << bitOffset);
			
			if ( dataBit )
				data[bitNum/4] |= (1 << bitOffset);
			if ( tmsBit )
				data[bitNum/4] |= (2 << bitOffset);
		}
	}
	
	struct ClockBitsInData {
		ubyte[30] data;
		
		bool getBit( int bitNum ) {
			return ((data[bitNum/8] >> (bitNum%8)) & 0x1) != 0;
		}
	}
	
	void processChunk( TAPCommand cmd, TAPResponse response, int startIndex, int numBits ) {
		ClockBitsOutData outData;
		ubyte[32] usbMsg;
		int ret;
		
		// prepare our output data
		for ( int i = startIndex; i < startIndex+numBits; i++ ) {
			bool dataBit = cmd.GetBit(i);
			bool tmsBit = cmd.GetTMSBit(i);
			
			outData.setBit( i - startIndex, dataBit, tmsBit );
		}
		
		//writefln( "Chunk will contain %d bits, starting from [%d]", numBits, startIndex );
		
		void reportUSBError( char[] where, USBDevice device, int ret ) {
			version (Tango) {
				Stdout.formatln( "[USB] Error in {}: {} (return code: {})", where, device.getError( ), ret );
			} else {
				writefln( "[USB] Error in %s: %s (return code: %s)", where, device.getError( ), ret );
			}
		}
		
		// prepare our usb message
		usbMsg[0] = jtagCommandClockBits;
		usbMsg[1] = numBits;
		usbMsg[2..$] = outData.data;
		while ( (ret = device.bulkWrite( jtagBulkOut, usbMsg )) != usbMsg.length ) {
			//reportUSBError( "USB Bulk Write (chunk)", device, ret );
			
			device.clearHalt( jtagBulkOut );
		}
		
		// read the response
		ubyte[32] readBytes;
		while ( (ret = device.bulkRead( jtagBulkIn, readBytes )) != readBytes.length ) {
			//reportUSBError( "USB Bulk Read (chunk)", device, ret );
			
			device.clearHalt( jtagBulkIn );
		}
		
		//writefln( "read = %s", readBytes[1] );
		
		// set our response bits
		ClockBitsInData inData;
		inData.data[0..$] = readBytes[2..$];
		for ( int i = startIndex; i < startIndex+numBits; i++ ) {
			bool currBit = inData.getBit( i - startIndex );
			response.SetBit( i, currBit );
			//writefln( "[%d] %d", i, currBit );
		}
	}
	
	public TAPResponse JTAGCommand( TAPCommand cmd ) {
		TAPResponse response = null;
		uint numBytes = cmd.neededBytes( );
		ubyte[] responseBytes;
		responseBytes.length = numBytes;
		response = new TAPResponse( responseBytes );
		ubyte[2] bytes;
		
		//writefln( "writing %s bits", cmd.bitLength );
		
		// usb msg = 32 bytes, 2 instruction bytes, then 4 bits per byte
		// (because 2 physical bits per logical bit/clock)
		const int MaxBitsPerMessage = ((32-2) * 4);
		
		for ( int i = 0; i < cmd.bitLength; ) {
			int numBits = MaxBitsPerMessage;
			
			if ( i + numBits > cmd.bitLength )
				numBits = cmd.bitLength - i;
			
			processChunk( cmd, response, i, numBits );
			
			i += MaxBitsPerMessage;
		}
		
		return response;
	}
	
	void enterDFUMode( ) {
		ubyte[32] bytes;
		int ret;
		
		bytes[0] = jtagCommandJumpBootloader;
		
		while ( (ret = device.bulkWrite( jtagBulkOut, bytes )) != bytes.length ) {
			version (Tango) {
				
			} else {
				writefln( "RST: USB Bulk Write failed (%s), retrying...", ret ); // loopies
			}
			
			//System.Threading.Thread.Sleep( 100 );
		}
	}
}

