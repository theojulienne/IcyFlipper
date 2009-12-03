module flipper.chips.base;

version (Tango) {
	alias char[] string;
}

import flipper.devices.device;
import flipper.memory;
import flipper.protocols.jtag;

class Chip {
	TAPStateMachine sm;
	Memory[string] memory;
	
	this( TAPStateMachine sm ) {
		this.sm = sm;
	}
	
	void addMemory( string name, Memory inst ) {
		memory[name] = inst;
	}
	
	Memory getMemory( string name ) {
		if ( name in memory ) {
			return memory[name];
		}
		
		throw new Exception( "Invalid memory specified" );
	}
	
	public abstract void showInformation( ) {
		
	}
}
