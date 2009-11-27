module flipper.interfaces.penguinoavr;

import std.compat;

import flipper.interfaces.penprog;
import flipper.board;
import flipper.boards.penguinoavr;

class PenguinoAVRInterface : PenprogInterface {
	const uint USBVendorId = 0x16D0;
	const uint USBProductId = 0x04CA;
	
	this( ) {
		super( );
	}
	
	public static void DiscoverInterfaces( ) {
		PenprogInterface.DiscoverInterfaces!(PenguinoAVRInterface)( USBVendorId, USBProductId );
	}
	
	public string getBoardName( ) {
		return "Penguino AVR";
	}
	
	public Board createBoard( ) {
		return new PenguinoAVRBoard( this );
	}
}
