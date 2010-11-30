package flipper.jtag;

import java.util.*;

public class TAPCommand {
	public int bitLength;
	
	public BitStream tmsStream;
	public BitStream dataStream;
	
	public boolean sendData = false;
	public boolean receiveData = false;
	public boolean sendTMS = false;
	
	private TAPCommand( ) {
		
	}
	
	public String toString( ) {
		StringBuilder s = new StringBuilder();
		s.append( "<TAPCommand length=" + bitLength );
		
		if ( sendData ) {
			s.append( " sendData=" );
			s.append( dataStream );
		}
		
		if ( sendTMS ) {
			s.append( " sendTMS=" );
			s.append( tmsStream );
		}
		
		if ( receiveData ) {
			s.append( " receive" );
		}
		
		s.append( ">" );
		return s.toString( );
	}
	
	public static TAPCommand clockTMS( BitStream tms ) {
		return sendData( tms.length( ), null, tms, false );
	}
	
	public static TAPCommand clockTMS( String bits ) {
		return sendData( bits.length( ), null, BitStream.fromString( bits ), false );
	}
	
	public static TAPCommand sendData( int bitLength, BitStream data, BitStream tms, boolean receive ) {
		TAPCommand cmd = new TAPCommand( );
		
		cmd.bitLength = bitLength;
		cmd.tmsStream = tms;
		cmd.dataStream = data;
		
		cmd.sendData = ( data != null );
		cmd.receiveData = receive;
		cmd.sendTMS = ( tms != null );
		
		return cmd;
	}
	
	public static TAPCommand receiveData( int bitLength ) {
		return sendData( bitLength, null, null, true );
	}
	
	/*
	public static TAPCommand sendData( int bitLength, SizedBitSet dataBits, SizedBitSet tmsBits, Method m ) {
		TAPCommand cmd = new TAPCommand( );
		
		cmd.bitLength = bitLength;
		cmd.tmsBits = tmsBits;
		cmd.dataBits = dataBits;
		cmd.method = m;
		
		return cmd;
	}
	
	public static TAPCommand sendData( int bitLength, int dataBits, int tmsBits ) {
		return sendData( bitLength, 
						 SizedBitSet.forInt( bitLength, dataBits ),
						 SizedBitSet.forInt( bitLength, tmsBits ),
						 Method.SendDataTMS );
	}
	*/
	/*
	public static TAPCommand SendData( uint bitLength, uint dataBits, uint tmsBits, Method m ) {
		return SendData( bitLength, BitConverter.GetBytes( dataBits ), BitConverter.GetBytes( tmsBits ), m );
	}
	*/
	/*
	public static TAPCommand sendReceiveData( int bitLength, SizedBitSet dataBits ) {
		return sendData( bitLength, dataBits, new SizedBitSet(bitLength), Method.SendReceiveData );
	}
	
	public static TAPCommand sendReceiveData( int bitLength, SizedBitSet dataBits, SizedBitSet tmsBits ) {
		return sendData( bitLength, dataBits, tmsBits, Method.SendReceiveDataTMS );
	}
	*/
	/*
	public static TAPCommand SendReceiveData( uint bitLength, ubyte[] dataBits ) {
		TAPCommand cmd = SendData( bitLength, dataBits );
		cmd.method = Method.SendReceiveData;
		return cmd;
	}
	
	public static TAPCommand SendReceiveData( uint bitLength, uint dataBits ) {
		TAPCommand cmd = SendData( bitLength, dataBits );
		cmd.method = Method.SendReceiveData;
		return cmd;
	}
	
	public static TAPCommand SendReceiveData( uint bitLength, uint dataBits, uint tmsBits ) {
		TAPCommand cmd = SendData( bitLength, dataBits, tmsBits );
		cmd.method = Method.SendReceiveData | Method.SendTMS;
		return cmd;
	}
	
	public static TAPCommand SendReceiveData( int bitLength, int dataBits, int tmsBits ) {
		return SendReceiveData( cast(uint)bitLength, cast(uint)dataBits, cast(uint)tmsBits );
	}
	*/
	/*
	public static TAPCommand receiveData( int bitLength ) {
		return sendData( bitLength, new SizedBitSet(bitLength), new SizedBitSet(bitLength), Method.ReceiveData );
	}
	*/
	/*
	public static TAPCommand ReceiveData( uint bitLength ) {
		TAPCommand cmd;
		
		cmd.bitLength = bitLength;
		cmd.tmsBits = BitConverter.GetBytes( 0 );
		cmd.dataBits = BitConverter.GetBytes( 0 );
		cmd.method = Method.ReceiveData;
		
		return cmd;
	}
	
	public static bool GetBitFromBytes( ubyte[] bytes, int bit ) {
		int actualByte = bit / 8;
		int actualBit = bit % 8;
		return (bytes[actualByte] & (1 << actualBit)) != 0;
	}
	
	public static void SetBitFromBytes( ubyte[] bytes, int bit, bool val ) {
		int actualByte = bit / 8;
		int actualBit = bit % 8;
		
		ubyte bitVal = cast(byte)(1 << actualBit);
		
		if ( val )
			bytes[actualByte] |= bitVal;
		else
			bytes[actualByte] &= cast(byte)~bitVal;
	}
	*/
	/*
	public boolean getDataBit( int bit ) {
		return dataBits.get( bit );
		//return GetBitFromBytes( dataBits, bit );
	}
	
	public boolean getTMSBit( int bit ) {
		return tmsBits.get( bit );
		//return GetBitFromBytes( tmsBits, bit );
	}
	
	public void setBit( int bit, boolean val ) {
		dataBits.set( bit, val );
		//SetBitFromBytes( dataBits, bit, val );
	}
	
	public void setTMSBit( int bit, boolean val ) {
		if ( val == true ) {
			method.setTMS( );
		}
		
		tmsBits.set( bit, val );
		//SetBitFromBytes( tmsBits, bit, val );
	}
	*/
	public int neededBytes( ) {
		int byteCount = bitLength / 8;
		
		if ( (bitLength % 8) > 0 )
			byteCount++;
		
		//writefln( "{0} bits need {1} bytes", bitLength, byteCount );
		
		return byteCount;
	}
	
	/*
	public static ubyte[] GetBitsForRange( ubyte[] bytes, int startIndex, int numBits ) {
		int byteCount = numBits / 8;
		
		if ( (numBits%8) > 0 )
			byteCount++;
		
		ubyte[] newBytes = new ubyte[byteCount];
		
		for ( int i = 0; i < byteCount; i++ ) {
			newBytes[i] = 0;
		}
		
		for ( int i = 0; i < numBits; i++ ) {
			if ( GetBitFromBytes( bytes, startIndex + i ) )
				newBytes[i/8] |= cast(byte)( 1 << (i%8) );
		}
		
		return newBytes;
	}
	*/
	/*
	public SizedBitSet getTMSBits( int startIndex, int numBits ) {
		return tmsBits.get( startIndex, startIndex + numBits );
		//return GetBitsForRange( tmsBits, startIndex, cast(int)numBits );
	}
	
	public SizedBitSet getDataBits( int startIndex, int numBits ) {
		return dataBits.get( startIndex, startIndex + numBits );
		//return GetBitsForRange( dataBits, startIndex, cast(int)numBits );
	}
	*/
	
	public boolean getDataBit( int index ) {
		if ( dataStream == null ) {
			return false;
		}
		
		return dataStream.get( index );
	}
	
	public boolean getTMSBit( int index ) {
		if ( tmsStream == null ) {
			return false;
		}
		
		return tmsStream.get( index );
	}
	
	// Splits a TAPCommand with double transitions (where both TMS and TDI change)
	// into multiple TAPCommands, each with only single transitions
	// (TMS or TDI stay stable the whole duration)
	public List<TAPCommand> splitByDoubleTransitions( ) {
		boolean splitNeeded = true;
		
		//if ( (method & (Method.SendData | Method.SendTMS)) != (Method.SendData | Method.SendTMS) ) {
		if ( !sendData || !sendTMS ) {
			// skip complex checking if TMS and TDI are not both being used
			splitNeeded = false;
		}
		
		if ( bitLength == 1 ) {
			// skip complex checking if we're only 1 bit long
			splitNeeded = false;
		}
		
		ArrayList<TAPCommand> cmdList = new ArrayList<TAPCommand>();
		
		if ( !splitNeeded ) {
			//TAPCommand[] tapCommands = new TAPCommand[1];
			//tapCommands[0] = this;
			//return tapCommands;
			cmdList.add( this );
			return cmdList;
		}
		
		System.out.println( "Preparing to split..." );
		//writefln( "Preparing to split..." );
		
		int currentBit = 0;
		boolean transitionFound = false;
		boolean transitionIsTMS = false;
		
		boolean currentData, currentTMS;
		int tmpBit;
		
		while ( currentBit < bitLength ) {
			if ( !transitionFound ) {
				// find a transition by skipping ahead until 1 bit changes
				currentData = getDataBit( currentBit );
				currentTMS = getTMSBit( currentBit );
				
				tmpBit = currentBit + 1;
				while ( tmpBit < bitLength ) {
					if ( currentData != getDataBit( tmpBit ) ) {
						// data bit changed first
						transitionFound = true;
						transitionIsTMS = false;
						
						break;
					} else if ( currentTMS != getTMSBit( currentBit ) ) {
						// TMS bit changed first
						transitionFound = true;
						transitionIsTMS = true;
						
						break;
					}
					
					tmpBit++;
				}
			}
			
			// we now have found the first transition (defined by transitionIsTMS).. 
			// now do another scan, looking as far as we can until the OTHER value changes
			currentData = getDataBit( currentBit );
			currentTMS = getTMSBit( currentBit );
			
			tmpBit = currentBit + 1;
			while ( tmpBit < bitLength ) {
				if ( (transitionIsTMS && currentData != getDataBit( tmpBit )) ||
				 	 ((!transitionIsTMS) && currentTMS != getTMSBit( tmpBit )) ) {
					// double transition found at tmpBit
					
					System.out.println( "Double transition found at " + tmpBit );
					//writefln( "Double transition found at {0}", tmpBit );
					
					int numBits = tmpBit - currentBit;
					TAPCommand cmd = this.subCommand( currentBit, numBits );
					cmdList.add( cmd );
					
					// continue from that bit
					transitionFound = false;
					currentBit = tmpBit;
					break;
				}
				
				tmpBit++;
			}
			
			if ( tmpBit == bitLength ) {
				int numBits = tmpBit - currentBit;
				TAPCommand cmd = this.subCommand( currentBit, numBits );
				cmdList.add( cmd );
				
				break;
			}
		}
		
		//writefln( "Split {0} bits into {1} parts", bitLength, cmdList.Count );
		
		return cmdList;
	}
	
	public TAPCommand subCommand( int fromIndex, int numBits ) {
		TAPCommand cmd = new TAPCommand( );
		cmd.bitLength = numBits;
		cmd.tmsStream = tmsStream.get( fromIndex, numBits );
		cmd.dataStream = dataStream.get( fromIndex, numBits );
		cmd.sendData = sendData;
		cmd.receiveData = receiveData;
		cmd.sendTMS = sendTMS;
		return cmd;
	}
}
