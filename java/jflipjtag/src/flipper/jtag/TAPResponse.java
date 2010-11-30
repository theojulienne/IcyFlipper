package flipper.jtag;

public class TAPResponse {
	public BitStream data;
	
	public TAPResponse( BitStream data ) {
		this.data = data;
		//writefln( "{0} = inLength", inData.length );
	}
	
	public TAPResponse( ) {
		this( BitStream.emptyStream( ) );
	}
	
	public String toString( ) {
		return "<TAPResponse " + data + ">";
	}
	
	public boolean getBit( int bit ) {
		return data.get( bit );
		//return TAPCommand.GetBitFromBytes( data, bit );
	}
	
	public long getInt32( ) {
		return data.getInt32( 0 );
		//return BitConverter.ToUInt32( data, 0 );
	}
	
	public int getInt16( ) {
		return data.getInt16( 0 );
		//return BitConverter.ToUInt32( data, 0 );
	}
	
	/*public byte getByte( int index ) {
		byte[] bytes = BitSetHelper.toByteArray( data );
		return bytes[index];
	}
	
	public short getUInt16( ) {
		return (short)BitSetHelper.getInt16FromSet( data, 0 );
		//writefln( "{0} = length", data.length );
		//return BitConverter.ToUInt16( data, 0 );
	}
	
	public void setBit( int bit, boolean val ) {
		data.set( bit, val );
		//TAPCommand.SetBitFromBytes( data, bit, val );
	}*/
}
