module flipper.program;

import tango.io.device.File;
import tango.io.device.Conduit;
import tango.io.stream.Buffered;
import tango.io.stream.Text;
import Integer = tango.text.convert.Integer;

import tango.io.Stdout;

/*version (Tango) {
	alias BufferedInput FileHandle;
	
	FileHandle openFile( char[] path ) {
		return new BufferedInput( new File( path ) );
	}
	
	uint fileSize( FileHandle file ) {
		return file.length;
	}
	
	bool readStreamBytes( FileHandle file, ubyte[] buf, out size_t bytesRead  ) {
		bytesRead = stream.read( buf );
		return bytesRead != IConduit.Eof;
	}
} else {
	alias Stream FileHandle;
	
	FileHandle openFile( char[] path ) {
		return new BufferedFile( path, FileMode.In );
	}
	
	uint fileSize( FileHandle file ) {
		return file.size;
	}
	
	bool readStreamBytes( FileHandle file, ubyte[] buf, out size_t bytesRead  ) {
		if ( stream.eof )
			return false;
		bytesRead = stream.read( buf );
		return bytesRead > 0;
	}
}*/

class Program {
	struct ProgramChunk {
		int offset;
		ubyte[] bytes;
	}
	
	ProgramChunk chunk;
	
	static Program load( char[] filename ) {
		if ( filename[$-4..$] == ".bin" ) {
			return loadFileBinary( filename );
		} else if ( filename[$-4..$] == ".hex" ) {
			return loadFileIHex( filename );
		} else {
			return null;
		}
	}
	
	static Program loadFileBinary( char[] filename ) {
		return new Program( 0, cast(ubyte[])File.get( filename ) );
	}
	
	static Program loadFileIHex( char[] filename ) {
		auto lines = new TextInput( new File( filename ) );
		
		int offset = -1;
		
		ubyte[] hexToBytes( char[] hex ) {
			ubyte[] ret;
			
			ret.length = hex.length / 2;
			
			for ( int i = 0; i < ret.length; i++ ) {
				ret[i] = Integer.parse( hex[i*2..(i+1)*2], 16 );
			}
			
			return ret;
		}
		
		ubyte[] totalBytes;
		
		foreach ( line; lines ) {
			if ( line.length < 5 )
				continue;
			
			char[] byteCount = line[1..3];
			char[] address = line[3..7];
			char[] recordType = line[7..9];
			char[] data = line[9..$-2];
			char[] checksum = line[$-2..$];
			
			// TODO: checksum?
			ushort addr = Integer.parse( address, 16 );
			ubyte[] bytes = hexToBytes( data );
			
			if ( recordType == "00" ) {
				Stdout.formatln( "Read in {} bytes at offset 0x{} ({}), currently read {} ({})", bytes.length, address, addr, totalBytes.length, offset+totalBytes.length );
				
				if ( offset == -1 ) {
					offset = addr;
				} else {
					// make sure regions are consecutive
					assert( offset+totalBytes.length == addr );
				}
				
				totalBytes ~= bytes;
			}
		}
		
		lines.close;
		
		Stdout.formatln( "Read complete. {} bytes total at offset {}.", totalBytes.length, offset );
		
		return new Program( offset, totalBytes );
	}
	
	this( int offset, ubyte[] data ) {
		chunk.offset = offset;
		chunk.bytes = data;
	}
	
	uint totalBytes( ) {
		return chunk.bytes.length;
	}
	
	uint programStart( ) {
		return chunk.offset;
	}
	
	ubyte[] getBytes( uint from, uint to ) {
		int offset = chunk.offset;
		
		int end = to-offset;
		
		if ( end > chunk.bytes.length )
			end = chunk.bytes.length;
		
		return chunk.bytes[from-offset..end];
	}
}
