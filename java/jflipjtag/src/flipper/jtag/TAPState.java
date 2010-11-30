package flipper.jtag;

public enum TAPState {
	TestLogicReset(0),
	RunTestIdle(1),
	
	SelectDRScan(2),
	CaptureDR(3),
	ShiftDR(4),
	Exit1DR(5),
	PauseDR(6),
	Exit2DR(7),
	UpdateDR(8),
	
	SelectIRScan(9),
	CaptureIR(10),
	ShiftIR(11),
	Exit1IR(12),
	PauseIR(13),
	Exit2IR(14),
	UpdateIR(15),
	
	Unknown(0xffff);
	
	public static final int NumStates = 16;
	
	private int _i;
	TAPState( int i ) {
		_i = i;
	}
}
