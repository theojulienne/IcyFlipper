module json;

version( Tango ) {
	import tango.util.Convert;
	static import Float = tango.text.convert.Float;
	import Util = tango.text.Util;
	import tango.io.Stdout;
} else {
	import std.string;
	
	// TODO: Phobos support
}


// char and string utilities

bool isWhitespace( char testChar ) {
	return ( testChar == ' ' || testChar == '\t' || testChar == '\n' || testChar == '\r' );
}

bool isDigit( char testChar ) {
	return ( testChar >= '0' && testChar <= '9' );
}


char[] trimWhitespace( inout char[] string ) {
	while( isWhitespace( string[0] ) ) {
		string = string[1..$];
	}
	
	while( isWhitespace( string[$-1] ) ) {
		string = string[0..$-1];
	}
	
	return string;
}

real toReal( char[] buffer ) {
	version( Tango ) {
		return Float.parse( buffer );
	} else {
		throw new Exception( "Phobos support not yet finished" );
	}
}

class JSONException : Exception {
	this( int line, char[] msg ) {
		char[] lineNum;
		version( Tango ) {
			lineNum ~= to!( char[] )( line );
		} else {
			lineNum ~= toString( line );
		}
		
		super( "Syntax Error, line " ~ lineNum ~ ": " ~ msg );
	}
}


enum JSONType { Object, Array, String, Number, Bool, Null };

// encoding/decoding and value storing classes

interface JSONValue {
	JSONType type( );
	char[] encode( );
}

class JSONObject : JSONValue {
	private JSONType _type;

	this( ) {
		_type = JSONType.Object;
	}
	
	JSONType type( ) {
		return _type;
	}
	
	JSONValue[ char[] ] values;
	
	JSONValue opIndex( char[] name ) {
		return values[ name ];
	}
	
	JSONValue opIndexAssign( JSONValue value, char[] name ) {
		values[ name ] = value;
		return value;
	}
	
	char[] encode( ) {
		char[] encodedOutput;
		
		encodedOutput ~= "{";
		
		bool first = true;
		foreach ( name, value; values ) {
			char[] item;
			
			if ( first ) {
				first = false;
			} else {
				item ~= ',';
			}
			
			item ~= "\"" ~ name ~ "\"" ~ ":" ~ value.encode( );
			encodedOutput ~= item;
		}
		
		encodedOutput ~= "}";
		
		return encodedOutput;
	}
}

class JSONArray : JSONValue {
	private JSONType _type;

	this( ) {
		_type = JSONType.Array;
	}
	
	JSONType type( ) {
		return _type;
	}

	JSONValue[] values;

	JSONValue opIndex( size_t index ) {
		return values[ index ];
	}
	
	JSONValue opIndexAssign( JSONValue value, size_t index ) {
		values[ index ] = value;
		return value;
	}
	
	char[] encode( ) {
		char[] encodedOutput;
		
		encodedOutput ~= '[';
		
		bool first = true;
		foreach ( value; values ) {
			char[] item;
			
			if ( first ) {
				first = false;
			} else {
				item ~= ',';
			}
			
			item ~= value.encode();
			encodedOutput ~= item;
		}
		
		encodedOutput ~= ']';
		
		return encodedOutput;
	}
}

class JSONString : JSONValue {
	private JSONType _type;

	this( ) {
		_type = JSONType.String;
	}
	
	JSONType type( ) {
		return _type;
	}
	
	char[] value;
	
	char[] encode( ) {
		char[] encodedOutput;
		
		encodedOutput ~= '"';
		
		// TODO: control characters, " and \ filtering
		encodedOutput ~= value;
		
		encodedOutput ~= '"';
		
		return encodedOutput;
	}
}

class JSONNumber : JSONValue {	
	private JSONType _type;

	this( ) {
		_type = JSONType.Number;
	}
	
	JSONType type( ) {
		return _type;
	}
	
	real value;
	
	int intValue( ) {
		return cast(int)value;
	}
	
	real realValue( ) {
		return cast(real)value;
	}
	
	char[] encode( ) {
		
		char[] encodedString;
		
		version( Tango ) {
			encodedString ~= to!( char[] )( value );
		} else {
			encodedString ~= toString( value );
		}
		
		return encodedString;
	}
}

class JSONBool : JSONValue {
	private JSONType _type;

	this( ) {
		_type = JSONType.Bool;
	}
	
	JSONType type( ) {
		return _type;
	}
	
	bool value;
	
	char[] encode( ) {
		char[] encodedString;
		
		if ( value ) {
			encodedString ~= "true";
		} else {
			encodedString ~= "false";
		}
		
		return encodedString;
	}
}

class JSONNull : JSONValue {
	private JSONType _type;

	this( ) {
		_type = JSONType.Bool;
	}
	
	JSONType type( ) {
		return _type;
	}
	
	char[] encode( ) {
		char[] encodedString;
		encodedString ~= "null";
		
		return encodedString;
	}
}

class JSON {
	private static const char EOF = cast(char)255;
	
	private static enum TokenType {
		None,
		LeftBrace,
		RightBrace,
		LeftBracket,
		RightBracket,
		Colon,
		Comma,
		String,
		Number,
		Bool,
		Null,
		EOF
	}
	
	private struct Token {
		char[] stringValue;
		real   realValue;
		bool   boolValue;
		int    type;
		
		static Token opCall( int type ) {
			Token tok;
			tok.type = type;
			return tok;
		}
	}
	
	char[] source;
	
	private int index;
	private int line;
	
	this( char[] source ) {
		this.source = source;
		this.index = 0;
		this.line = 0;
	}
	
	private void error( char[] msg ) {
		throw new JSONException( line, msg );
	}
	
	private Token lex( ) {
		Token token;
		token.type = TokenType.None;
		char[] buffer;
		char c = ' '; // give it a space to start with
		
		// stepping through characters
		void nextChar( ) {
				
			if ( c == EOF ) {
				error( "Premature EOF" );
			}
			
			c = source[index];
			index++;
			
			// ignore whitespace and count lines
			while ( isWhitespace( c ) ) {

				if ( c == '\n' ) {
					line++;
				}

				c = source[index];
				index++;	
			}
			
			//Stdout.formatln( "{}", c );
		}
		
		void stepBack( ) {
			index--;
		}
		
		// validation matching for bool and null
		char[] matchWord;
	
		void match( ) {
			foreach ( letter; matchWord ) {
				if ( c != letter ) {
					error( "Unknown value" );
				}
				nextChar( );
			}
			stepBack( );
		}
		
		
		// digit lexer, saves digits to the buffer until no more digits
		void lexDigits( ) {
			do {
				buffer ~= c;
				nextChar();
			} while ( isDigit( c ) );
		}
		
		// string lexer
		void lexString( ) {
			bool escaping = false;
			
			while ( true ) {
				nextChar( );
				
				if ( escaping ) {
					switch ( c ) {
						case '"': c = '"'; break;
						case '\\': c = '\\'; break;
						case '/' : c = '/' ; break;
						case 'b' : c = '\b'; break;
						case 'f' : c = '\f'; break;
						case 'n' : c = '\n'; break;
						case 'r' : c = '\r'; break;
						case 't' : c = '\t'; break;
						case 'u' : {
							// 4 hex digits
							uint val=0;
							for ( int i = 0; i < 4; i++ ) {
								val <<= 4;
								nextChar( );
								if ( c >= '0' && c <= '9' ) {
									val += c - '0';
								} else if ( c >= 'a' && c <= 'f' ) {
									val += 10 + c-'a';
								} else if ( c >= 'A' && c <= 'F' ) {
									val += 10 + c-'A';
								} else if (c == EOF) {
									error( "Unterminated string literal" );
								} else {
									error( "Non hex digit inside \\uXXXX escape sequence" );
								}
							}
							
							c = cast(char)val;
						}
						break;
						
						default:
							error( "Unknown escape sequence" );
							break;
					}
					
					buffer ~= c;
					escaping = false;
				} else {
					if ( c == '\\' ) {
						
						// escape character, start escaping
						
						escaping = true;
						continue; // read another character
					} else if ( c == '"' ) {
						
						// end of string, save the token
						token.stringValue = buffer;
						token.type = TokenType.String;
						
						return; // we're done
					} else if ( c == EOF ) {
						
						// uh-oh
						error( "Unterminated string literal" );
						
					} else {
						
						// otherwise just add the character to the buffer
						// and count new lines inside strings too
						if ( c == '\n' ) {
							line++;
						}
						buffer ~= c;
						
					}
				}
			}
		}
		
		
		// number lexer
		void lexNumber( ) {
			
			token.type = TokenType.Number;
		
			lexDigits( );
		
			// floating point
			if ( c == '.' ) {
				lexDigits( );
			}
		
			// exponent
			if ( c == 'e' || c == 'E' ) {
				buffer ~= c;
				nextChar( );
			
				if ( c == '+' || c == '-' ) {
					buffer ~= c;
					nextChar( );
				}
			
				if ( isDigit( c ) ) {
					lexDigits( );
				} else {
					error( "Empty exponent" );
				}
			}
		
			token.realValue = buffer.toReal( );
		
			stepBack( );
		}
		
		
		// Begin Lexing
		
		nextChar( );
		
		if ( c == '"' ) {
			
			// String
			
			lexString( );
			return token;
			
		} else if ( isDigit( c ) || c == '-' || c == '+' ) {
			
			// Number
			lexNumber( );
			return token;
			
		} else if ( c == 't' ) {
			
			// true

			matchWord = "true";
		
			match( );
		
			token.boolValue = true;
			token.type = TokenType.Bool;
			return token;	
			
		} else if ( c == 'f' ) {

			// false
			
			matchWord = "false";
		
			match( );
		
			token.boolValue = false;
			token.type = TokenType.Bool;	
			return token;	
				
		} else if ( c == 'n' ) {
			
			// null
			
			matchWord = "null";
		
			match( );
		
			token.type = TokenType.Null;	
			return token;
			
		}
	
		// other tokens
		switch ( c ) {
			case '{': token.type = TokenType.LeftBrace; break;
			case '}': token.type = TokenType.RightBrace; break;
			case '[': token.type = TokenType.LeftBracket; break;
			case ']': token.type = TokenType.RightBracket; break;
			case ':': token.type = TokenType.Colon; break;
			case ',': token.type = TokenType.Comma; break;
	
			case EOF: token.type = TokenType.EOF; break;
			
			default: break;
		}
	
		return token;
	}
	
	
	private JSONValue parse( Token previousToken = Token( TokenType.None ) ) {
		Token token;
		JSONValue result;
		
		if ( previousToken.type == TokenType.None ) {
			token = lex( );
		} else {
			token = previousToken;
		}
		
		switch ( token.type ) {
			
			// Object
			case TokenType.LeftBrace:
				char[] name;
				
				result = new JSONObject( );
				
				while ( true ) {
					
					// find the name
					token = lex( );
						
					if ( token.type == TokenType.String ) {
						name = token.stringValue;
					} else {
						error( "Object names must be strings" );
					}
					
					// followed by a colon
					
					token = lex( );
					
					if ( token.type != TokenType.Colon ) {
						error( "Expected ':' after object name" );
					}
					
					// followed by a value
					token = lex( );
					
					JSONObject object = cast(JSONObject)result;
					object[ name ] = parse( token );
					
					// followed by a comma or end of object
					
					token = lex( );
					
					if ( token.type == TokenType.Comma ) {
						continue;
					} else if ( token.type == TokenType.RightBrace ) {
						break;
					} else {
						error( "Expected ',' or '}' after name/value pair" );
					}
					
				}
				break;
				
			// Array
			case TokenType.LeftBracket:
				result = new JSONArray( );
				
				token = lex( );
				
				// empty array
				if ( token.type == TokenType.RightBracket ) {
					break;
				}
				
				while ( true ) {
					// parse a value
					JSONArray array = cast(JSONArray) result;
					array.values ~= parse( token );
					
					token = lex( );
					// expecting a comma, or end of array
					if ( token.type == TokenType.Comma ) {
						token = lex( );
						continue; // read next value
					} else if ( token.type == TokenType.RightBracket ){
						break; // end array
					}
				}
				break;
				
			// String
			case TokenType.String:
				result = new JSONString( );
				
				JSONString string = cast(JSONString)result;
				string.value = token.stringValue;
				break;
				
			// Number
			case TokenType.Number:
				result = new JSONNumber( );
				
				JSONNumber number = cast(JSONNumber)result;
				number.value = token.realValue;
				break;
			
			// Boolean
			case TokenType.Bool:
				result = new JSONBool( );
				
				JSONBool boolean = cast(JSONBool)result;
				boolean.value = token.boolValue;
				break;
				
			// Null
			case TokenType.Null:
				result = new JSONNull( ); 
				break;
				
			// Oops
			default:
				error( "Unknown or malformed JSON value" );
		}
		
		return result;
	}
	
	
	
	static JSONValue decode( char[] jsonString ) {
		auto parser = new JSON( jsonString );
		return parser.parse( );
	}
	
	static char[] encode( JSONValue value ) {
		return value.encode( );
	}

}