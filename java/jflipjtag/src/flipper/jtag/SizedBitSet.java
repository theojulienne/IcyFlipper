package flipper.jtag;

import java.util.BitSet;

public class SizedBitSet extends BitSet {
	@Deprecated
	public SizedBitSet( ) {
		super( );
	}
	
	@Deprecated
	public SizedBitSet( int length ) {
		super( length );
		setLength( length );
	}
	
	private int length;
	@Deprecated
	public int getLength( ) {
		return length;
	}
	@Deprecated
	public void setLength( int l ) {
		length = l;
	}
	@Deprecated
	public SizedBitSet get( int firstIndex, int lastIndex ) {
		BitSet tmpPart = super.get( firstIndex, lastIndex );
		
		int length = lastIndex - firstIndex;
		SizedBitSet sbs = new SizedBitSet( length );
		sbs.or( tmpPart );
		
		return sbs;
	}
	@Deprecated
	public void fromInt( int bitLength, int bits ) {
		for ( int i = 0; i < bitLength; i++ ) {
			int bitValue = ( 1 << i );
			set( i, (bits & bitValue) != 0 );
		}
	}
	@Deprecated
	public static SizedBitSet forInt( int bitLength, int bits ) {
		SizedBitSet sbs = new SizedBitSet( bitLength );
		sbs.fromInt( bitLength, bits );
		return sbs;
	}
}