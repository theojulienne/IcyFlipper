module flipper.devices.penguinoavr.device;

import tango.io.Stdout;
import tango.io.device.File;
import tango.io.device.Conduit;

import flipper.devices.device;
import flipper.devices.manager;
import flipper.protocols.jtag;
import flipper.chips.avr;
import flipper.flash.avrflash;
import flipper.memory;

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

class PenguinoAVRDevice : Device {
	View _devicePanel;
	
	PenprogInterface penprog;
	IJTAG ijtag;
	TAPStateMachine sm;
	
	ProgressBar uploadProgress;
	Label uploadStatus;
	
	this( ) {
		Stdout.formatln( "Penguino AVR Device constructor" );
	}
	
	void usbDevice( USBDevice dev ) {
		Device.usbDevice( dev );
		
		penprog = new PenprogInterface( dev );
		ijtag = cast(IJTAG)penprog;
		sm = new TAPStateMachine( ijtag );
		
		Stdout.formatln( "Penguino AVR now has a USB device!" );
		
		assert( verifyParts( ), "Could not verify the chip on the attached Penguino AVR" );
		
		enumerateChips( );
	}
	
	void enumerateChips( ) {
		auto chip = new AVRChip( this.sm );
		
		// Penguino AVR contains an ATMega32A with 32KB flash
		chip.addMemory( "flash", new AVRFlash( chip, 32*1024 ) );
		
		chips["user"] = chip;
	}
	
	void createDevicePanel( ) {
		auto stackView = new StackView( StackDirection.Vertical );
		stackView.padding = 0;
		
		auto deviceInfo = new Frame( "Device Information" );
		stackView.addSubview( deviceInfo );
		stackView.setProportion( deviceInfo, 1 );
		
		auto infoView = new StackView( StackDirection.Vertical );
		infoView.padding = 16;
		auto dfuButton = new Button( "Reset to DFU mode" );
		dfuButton.onPress += &penprog.enterDFUMode;
		infoView.addSubview( dfuButton );
		deviceInfo.contentView = infoView;
		
		auto uploading = new Frame( "Device Upload" );
		stackView.addSubview( uploading );
		stackView.setProportion( uploading, 1 );
		
		auto progView = new StackView( StackDirection.Vertical );
		progView.padding = 16;
		auto uploadButton = new Button( "Upload" );
		uploadButton.onPress += &uploadPrompt;
		progView.addSubview( uploadButton );
		uploadStatus = new Label( "Waiting for upload..." );
		progView.addSubview( uploadStatus );
		uploadProgress = new ProgressBar( ProgressBarType.Horizontal );
		uploadProgress.indeterminate = false;
		uploadProgress.value = 0;
		progView.addSubview( uploadProgress );
		uploading.contentView = progView;
		
		_devicePanel = stackView;
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
		
		//writefln( "IDCODE = %s: %s\n", id, reg );
		Stdout.format( "IDCODE = {0}: {1}", id, reg.toString ).newline;
		
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
		
		version (Tango) {
			Stdout.formatln( "Uploading: {}", path );
		} else {
			writefln( "Uploading: %s", path );
		}
		
		auto uploadTarget = "flash";
		
		Memory targetMemory = chips["user"].getMemory( uploadTarget );
		assert( targetMemory !is null );
		
		// AVR flashingness
		
		File file = new File( path.toString );
		
		if ( file is null )
			return;
		
		int sourceBytes = file.length;
		
		//Stdout.newline;
		//Stdout.format( "Erasing {0}...", uploadTarget ).newline;
		uploadStatus.text = "Erawing " ~ uploadTarget ~ "...";
		targetMemory.erase( );
		
		void reportOperationProgress( uint bytesCompleted ) {
			if ( bytesCompleted > sourceBytes )
				bytesCompleted = sourceBytes;
			
			uploadProgress.maxValue = sourceBytes;
			uploadProgress.value = bytesCompleted;
			
			/*Stdout( "\r  [" );
			
			int progressLength = 65;
			int bytesPerChunk = sourceBytes / progressLength;
			
			for ( int i = 0; i < progressLength; i++ ) {
				
				if ( bytesCompleted > i * bytesPerChunk ) {
					Stdout( "#" );
				} else {
					Stdout( "." );
				}
				
			}
			
			float progressPercent = 0;
			
			if ( sourceBytes > 0 ) {
				progressPercent = (cast(float)bytesCompleted / cast(float)sourceBytes) * 100;
			}
			
			Stdout.format( "] {0}%   ({1} of {2} bytes)", progressPercent, bytesCompleted, sourceBytes );
			Stdout.flush;
			//fflush( stdout );
			*/
		}
		
		//Stdout.newline.newline;
		//Stdout.format( "Writing {0}...", uploadTarget ).newline;
		//Stdout( " ~ starting ~ " );
		uploadStatus.text = "Writing " ~ uploadTarget ~ "...";
		targetMemory.writeStream( file, &reportOperationProgress );
		
		//Stdout.newline.newline;
		//Stdout.format( "Verifying {0}...", uploadTarget ).newline;
		//Stdout( " ~ starting ~ " );
		uploadStatus.text = "Verifying " ~ uploadTarget ~ "...";
		targetMemory.verifyStream( file, &reportOperationProgress );
		
		uploadStatus.text = "Done!";
		
		targetMemory.finished( );
		
		AVRChip chip = cast(AVRChip)chips["user"];
		
		Stdout.formatln( "ReadFuseL() = {}", chip.ReadFuseL( ) );
		chip.WriteFuseL( 0xEF );
		
		Stdout.formatln( "ReadFuseH() = {}", chip.ReadFuseH( ) );
		chip.WriteFuseH( 0x89 );
		
		chip.exitProgMode( );
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
		_device.releaseInterface( jtagInterface );
	}
	
	void device( USBDevice dev ) {
		_device = dev;
		
		_device.open( );
		
		// set timeout
		// set configuration on win32
		
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
		
		// prepare our usb message
		usbMsg[0] = jtagCommandClockBits;
		usbMsg[1] = numBits;
		usbMsg[2..$] = outData.data;
		while ( (ret = device.bulkWrite( jtagBulkOut, usbMsg )) != usbMsg.length ) {
			version (Tango) {
				
			} else {
				writefln( "CHUNK: USB Bulk Write failed (%s), retrying...", ret ); // loopies
			}
		}
		
		// read the response
		ubyte[32] readBytes;
		while ( (ret = device.bulkRead( jtagBulkIn, readBytes )) != readBytes.length ) {
			version (Tango) {
				Stdout( "Error: " ~ device.getError( ) ).newline;
			} else {
				writefln( "CHUNK: USB Bulk Read failed (%s), retrying...", ret ); // loopies
			}
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

