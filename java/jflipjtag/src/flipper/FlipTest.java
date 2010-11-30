package flipper;

import flipper.penguino.*;

import java.util.ArrayList;

public class FlipTest {
	public static void main( String[] args ) {
		ArrayList<PenguinoDevice> penguinos = PenguinoDevice.enumeratePenguinoDevices( );
		
		penguinos = null;
		System.gc( );
	}
}