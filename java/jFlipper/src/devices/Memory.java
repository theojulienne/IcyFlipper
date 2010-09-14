package devices;

import chips.Chip;

public class Memory {
	public Chip chip = null;
	
	public Memory( Chip c ) {
		chip = c;
	}
}
/*
	public uint memoryBytes = 0; // in bytes
	public uint pageBytes = 0; // in bytes
	
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
	
	bool writeStream( Program program, MemoryProgressDelegate writeProgress=null ) {
		writeProgress( 0 );
		
		uint offset = program.programStart;
		uint startPage = offset / pageBytes;
		uint currPage = startPage;
		
		while ( (offset-program.programStart) < program.totalBytes ) {
			assert( currPage < numPages );
			
			writeProgress( (currPage-startPage) * pageBytes );
			
			ubyte[] pageBuf = program.getBytes( offset, offset+pageBytes );
			writePage( currPage, pageBuf );
			
			currPage++;
			offset += pageBytes;
		}
		
		writeProgress( (currPage-startPage) * pageBytes );
		
		return true;
	}
	
	bool verifyStream( Program program, MemoryProgressDelegate verifyProgress=null ) {
		verifyProgress( 0 );
		
		uint offset = program.programStart;
		uint startPage = offset / pageBytes;
		uint currPage = startPage;
		
		while ( (offset-program.programStart) < program.totalBytes ) {
			assert( currPage < numPages );
			
			verifyProgress( (currPage-startPage) * pageBytes );
			
			ubyte[] pageBuf = program.getBytes( offset, offset+pageBytes );
			ubyte[] actualBuf = readPage( currPage );
			
			for ( int j = 0; j < pageBuf.length; j++ ) {
				if ( actualBuf[j] != pageBuf[j] ) {
					throw new Exception( "Verify failed!" );
				}
			}
			
			currPage++;
			offset += pageBytes;
		}
		
		verifyProgress( (currPage-startPage) * pageBytes );
		
		return true;
	}
	
	/*
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
	
	bool writeStream( InputStream src, MemoryProgressDelegate writeProgress=null, int pageOffset=0 ) {
		version (Tango) {
			BufferedInput srcData = new BufferedInput( src );
			srcData.seek( 0, File.Anchor.Begin );
		} else {
			InputStream srcData = src;
			srcData.seekSet( 0 );
		}
		
		ubyte[] pageBuf;
		pageBuf.length = pageBytes;
		int currPage = pageOffset;
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
	
	bool verifyStream( InputStream src, MemoryProgressDelegate verifyProgress=null, int pageOffset=0 ) {
		version (Tango) {
			BufferedInput srcData = new BufferedInput( src );
			srcData.seek( 0, File.Anchor.Begin );
		} else {
			InputStream srcData = src;
			srcData.seekSet( 0 );
		}
		
		ubyte[] pageBuf, actualBuf;
		pageBuf.length = pageBytes;
		int currPage = pageOffset;
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
	}-/
}

*/