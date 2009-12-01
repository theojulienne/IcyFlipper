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
	
	abstract View devicePanel( ) {
		assert( false );
	}
	
	char[] name( ) {
		return "Unknown Device";
	}
}
