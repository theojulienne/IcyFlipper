package flipper.jtag;

import java.util.BitSet;

public abstract class BitSetHelper {
	@Deprecated
	private static int getInt32FromSet( BitSet bs, int firstBit ) {
		int temp = 0;
		
		for ( int i = 0; i < 32; i++ ) {
			if ( bs.get( firstBit + i ) ) {
				temp |= 1 << i;
			}
		}
		
		return temp;
	}
	
	@Deprecated
	private static int getInt16FromSet( BitSet bs, int firstBit ) {
		int temp = 0;
		
		for ( int i = 0; i < 16; i++ ) {
			if ( bs.get( firstBit + i ) ) {
				temp |= 1 << i;
			}
		}
		
		return temp;
	}
	
	
	
	// Returns a bitset containing the values in bytes.
	// The byte-ordering of bytes must be big-endian which means the most significant bit is in element 0.
	@Deprecated
	private static BitSet fromByteArray(byte[] bytes) {
	    BitSet bits = new BitSet();
	    for (int i=0; i<bytes.length*8; i++) {
	        if ((bytes[bytes.length-i/8-1]&(1<<(i%8))) > 0) {
	            bits.set(i);
	        }
	    }
	    return bits;
	}

	// Returns a byte array of at least length 1.
	// The most significant bit in the result is guaranteed not to be a 1
	// (since BitSet does not support sign extension).
	// The byte-ordering of the result is big-endian which means the most significant bit is in element 0.
	// The bit at index 0 of the bit set is assumed to be the least significant bit.
	@Deprecated
	private static byte[] toByteArray(BitSet bits) {
	    byte[] bytes = new byte[bits.length()/8+1];
	    for (int i=0; i<bits.length(); i++) {
	        if (bits.get(i)) {
	            bytes[bytes.length-i/8-1] |= 1<<(i%8);
	        }
	    }
	    return bytes;
	}
}