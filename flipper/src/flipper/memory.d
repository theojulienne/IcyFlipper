module flipper.memory;

version (Tango) {
	import tango.io.device.File;
	import tango.io.device.Conduit;
	import tango.io.stream.Buffered;
} else {
	import std.stream;
	import std.stdio;
	alias BufferedStream BufferedInput;
	alias Stream InputStream;
}

//import std.stdio;

import flipper.chips.base;

class Memory {
	public uint memoryBytes = 0; // in bytes
	public uint pageBytes = 0; // in bytes
	public Chip chip = null;
	
	this( Chip c ) {
		chip = c;
	}
	
	uint numPages( ) {
		return memoryBytes / pageBytes;
	}
	
	abstract void erase( ) {
		
	}
	
	abstract void writePage( uint pageIndex, ubyte[] data ) {
		
	}
	
	abstract ubyte[] readPage( uint pageIndex ) {
		return null;
	}
	
	abstract void finished( ) {
		
	}
	
	typedef void delegate( uint bytesCompleted ) MemoryProgressDelegate;
	
	bool readStreamBytes( InputStream stream, ubyte[] buf, out size_t bytesRead ) {
		version (Tango) {
			bytesRead = stream.read( buf );
			return bytesRead != IConduit.Eof;
		} else {
			if ( stream.eof )
				return false;
			bytesRead = stream.read( buf );
			return bytesRead > 0;
		}
	}
	
	bool writeStream( InputStream src, MemoryProgressDelegate writeProgress=null ) {
		version (Tango) {
			BufferedInput srcData = new BufferedInput( src );
			srcData.seek( 0, File.Anchor.Begin );
		} else {
			InputStream srcData = src;
			srcData.seekSet( 0 );
		}
		
		ubyte[] pageBuf;
		pageBuf.length = pageBytes;
		int currPage = 0;
		size_t size_read;
		
		writeProgress( 0 );
		
		//while ( (size_read = srcData.fill( pageBuf )) != IConduit.Eof ) {
		while ( readStreamBytes( srcData, pageBuf, size_read ) ) {
			assert( currPage < numPages );
			
			writeProgress( currPage * pageBytes );
			
			pageBuf.length = size_read;
			writePage( currPage, pageBuf );
			
			currPage++;
		}
		
		writeProgress( currPage * pageBytes );
		
		return true;
	}
	
	bool verifyStream( InputStream src, MemoryProgressDelegate verifyProgress=null ) {
		version (Tango) {
			BufferedInput srcData = new BufferedInput( src );
			srcData.seek( 0, File.Anchor.Begin );
		} else {
			InputStream srcData = src;
			srcData.seekSet( 0 );
		}
		
		ubyte[] pageBuf, actualBuf;
		pageBuf.length = pageBytes;
		int currPage = 0;
		size_t size_read;
		
		verifyProgress( 0 );
		
		//while ( (size_read = srcData.fill( pageBuf )) != IConduit.Eof ) {
		while ( readStreamBytes( srcData, pageBuf, size_read ) ) {
			assert( currPage < numPages );
			
			verifyProgress( currPage * pageBytes );
			
			actualBuf = readPage( currPage );
			
			for ( int j = 0; j < size_read; j++ ) {
				//writefln( "%s == %s", correctBytes[j], verifyBytes[j] );
				
				if ( actualBuf[j] != pageBuf[j] ) {
					//writefln( "Error with byte %s in page %s (expected %s, read %s)", j, currPage, pageBuf[j], actualBuf[j] );
					throw new Exception( "Verify failed!" );
				}
			}
			
			currPage++;
		}
		
		verifyProgress( currPage * pageBytes );
		
		return true;
	}
}
