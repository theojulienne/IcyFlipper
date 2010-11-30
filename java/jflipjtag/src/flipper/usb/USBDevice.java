package flipper.usb;

import org.beblue.jna.usb.*;

public class USBDevice {
	private usb_device device;
	private usb_dev_handle handle;
	
	LibUSB libUSB = LibUSB.libUSB;
	
	public USBDevice( usb_device device ) {
		this.device = device;
	}
	
	public void open( ) {
		handle = libUSB.usb_open( device );
	}
	
	public usb_device_descriptor getDescriptor( ) {
		return device.descriptor;
	}
	
	public void claimInterface( int ifaceNum ) throws USBException {
		int ret = libUSB.usb_claim_interface( handle, ifaceNum );
		if ( ret != 0 ) {
			throw new USBException( "usb_claim_interface failed, returned " + ret );
		}
	}
	
	public void releaseInterface( int ifaceNum ) throws USBException {
		int ret = libUSB.usb_release_interface( handle, ifaceNum );
		if ( ret != 0 ) {
			throw new USBException( "usb_release_interface failed, returned " + ret );
		}
	}
	
	public int bulkWrite( int endpoint, byte[] bytes ) {
		return libUSB.usb_bulk_write( handle, endpoint, bytes, bytes.length, getTimeout( ) );
	}
	
	public int bulkRead( int endpoint, byte[] bytes ) {
		return libUSB.usb_bulk_read( handle, endpoint, bytes, bytes.length, getTimeout( ) );
	}
	
	private int getTimeout( ) {
		return 1000;
	}
	
	public void clearHalt( int endpoint ) {
		libUSB.usb_clear_halt( handle, endpoint );
	}
}
