module usb.device;

version (Tango) {
	import tango.stdc.stringz : fromStringz, toStringz;
	alias char[] string;
} else {
	import std.string;
	alias std.string.toString fromStringz;
}

import usb.libusb;
import usb.descriptors;

class USBException : Exception {
	this( string prefix ) {
		version (Tango) {
			super( prefix ~ ": " ~ fromStringz( usb_strerror( ) ) );
		} else {
			super( prefix ~ ": " ~ std.string.toString( usb_strerror( ) ) );
		}
	}
}

class USBDevice {
	static USBDevice[usb_device*] dev_map;
	static USBDevice fromC( usb_device *c_dev ) {
		if ( !(c_dev in dev_map) )
			dev_map[c_dev] = new USBDevice( c_dev );
		
		return dev_map[c_dev];
	}
	
	usb_device *_dev;
	usb_dev_handle *_hdl = null;
	int timeout = 1000;
	
	this( usb_device *native ) {
		_dev = native;
	}
	
	~this( ) {
		if ( _hdl !is null )
			close( );
	}
	
	USBDeviceDescriptor descriptor( ) {
		return usb_get_device_descriptor( _dev );
	}
	
	class ConfigurationEnumerator {
		int opApply( int delegate(ref USBConfigurationDescriptor) dg ) {
			int result;
			
			int i;
			for ( i = 0; i < this.length; i++ ) {
				USBConfigurationDescriptor cfg = opIndex(i);
				result = dg( cfg  );

				if ( result )
					break;
			}

			return result;
		}
		
		int length( ) {
			return descriptor.bNumConfigurations;
		}
		
		USBConfigurationDescriptor opIndex( int index ) {
			return usb_get_configuration_descriptor( _dev, index );
		}
	}
	
	ConfigurationEnumerator configurations( ) {
		return new ConfigurationEnumerator( );
	}
	
	void open( ) {
		_hdl = usb_open( _dev );
		assert( _hdl !is null );
	}
	
	void close( ) {
		assert( usb_close( _hdl ) == 0 );
	}
	
	void configuration( int configuration ) {
		if ( usb_set_configuration( _hdl, configuration ) != 0 ) {
			throw new USBException( "usb_set_configuration failed" );
		}
	}
	
	void claimInterface( int iface ) {
		if ( usb_claim_interface( _hdl, iface ) != 0 ) {
			throw new USBException( "usb_claim_interface failed" );
		}
	}
	
	void releaseInterface( int iface ) {
		if ( usb_release_interface( _hdl, iface ) != 0 ) {
			throw new USBException( "usb_release_interface failed" );
		}
	}
	
	int bulkRead( int endpoint, ubyte[] data ) {
		return usb_bulk_read( _hdl, endpoint, data.ptr, data.length, timeout );
	}
	
	int bulkWrite( int endpoint, ubyte[] data ) {
		return usb_bulk_write( _hdl, endpoint, data.ptr, data.length, timeout );
	}
	
	int clearHalt( int endpoint ) {
		return usb_clear_halt( _hdl, endpoint );
	}
	
	string getError( ) {
		return fromStringz( usb_strerror( ) );
	}
}
