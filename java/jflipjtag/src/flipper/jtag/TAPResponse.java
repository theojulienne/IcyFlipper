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
	}
	
	public long getInt32( ) {
		return data.getInt32( 0 );
	}
	
	public int getInt16( ) {
		return data.getInt16( 0 );
	}
}
