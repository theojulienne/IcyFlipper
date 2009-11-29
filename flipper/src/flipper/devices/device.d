module flipper.devices.device;

public import usb.all;

import flipper.devices.manager;

class Device {
	private USBDevice _usbDevice;
	
	void usbDevice( USBDevice dev ) {
		_usbDevice = dev;
	}
	
	char[] name( ) {
		return "Unknown Device";
	}
}
