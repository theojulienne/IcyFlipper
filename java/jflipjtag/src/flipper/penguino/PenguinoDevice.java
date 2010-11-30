package flipper.penguino;

//import ch.ntb.usb.*;

import org.beblue.jna.usb.*;

import java.util.ArrayList;

import flipper.usb.USBDevice;

import flipper.jtag.*;

public class PenguinoDevice {
	private static final int usbVendorId = 0x16D0;
	private static final int usbProductId = 0x04CA;
	
	private PenprogInterface penprog;
	
	public static ArrayList<PenguinoDevice> enumeratePenguinoDevices( ) {
		//LibusbJava.usb_set_debug(255);
		
		ArrayList<PenguinoDevice> devices = new ArrayList<PenguinoDevice>( );
		
		LibUSB libUSB = LibUSB.libUSB;
		
		libUSB.usb_init();
		libUSB.usb_find_busses();
		libUSB.usb_find_devices();
		
		for ( usb_bus bus = libUSB.usb_get_busses(); bus != null; bus = bus.next ) {
			for ( usb_device dev = bus.devices; dev != null; dev = dev.next ) {
				usb_device_descriptor desc = dev.descriptor;
				
				if ( desc.idVendor == usbVendorId && desc.idProduct == usbProductId ) {
					devices.add( new PenguinoDevice( new USBDevice( dev ) ) );
				}
			}
		}
		
		return devices;
	}
	
	private PenguinoDevice( USBDevice dev ) {
		penprog = new PenprogInterface( dev );
		
		idcodeDebug( );
	}
	
	private TAPStateMachine sm;
	
	void idcodeDebug( ) {
		sm = new TAPStateMachine( penprog );
		
		try {
			penprog.sendJTAGReset( true, true );
			
			sm.gotoState( TAPState.TestLogicReset );
			sm.gotoState( TAPState.ShiftDR );
			
			TAPResponse response = sm.sendCommand( TAPCommand.receiveData( 32 ) );
			int id = (int)response.getInt32( );
			
			System.out.printf( "Received IDCODE = %x (%s)\n", id, response );
			
		} finally {
			penprog.sendJTAGReset( false, false );
		}
	}
}
