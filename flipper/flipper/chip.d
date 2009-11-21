module flipper.chip;

import std.compat : string;

import flipper.board;
import flipper.memory;

class Chip {
	Board board;
	Memory[string] memory;
	
	this( Board b ) {
		board = b;
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
