module flipper.devices.device;

public import usb.all;

import chisel.core.all;
import chisel.ui.all;

import flipper.devices.manager;
import flipper.chips.base;

class Device {
	private USBDevice _usbDevice;
	Chip[char[]] chips;
	
	void usbDevice( USBDevice dev ) {
		_usbDevice = dev;
	}
	
	void usbDisconnected( USBDevice dev ) {
		_usbDevice = null;
	}
	
	abstract View devicePanel( ) {
		assert( false );
	}
	
	char[] name( ) {
		return "Unknown Device";
	}
}
