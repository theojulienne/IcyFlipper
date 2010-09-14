package widgets;

import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.*;

public class DeviceTabFactory {
	public static TabFolder createPenguinoAVRFolder( Composite parent, int style ) {
		TabFolder folder = new TabFolder( parent, style );
		
		// add some dummy tabs with a text-box
		for ( int loopIndex = 0; loopIndex < 3; loopIndex++ ) {
			TabItem tabItem = new TabItem(folder, SWT.NULL);
			tabItem.setText("Tab " + loopIndex);
		
			Text text = new Text(folder, SWT.BORDER);
			text.setText("This is page " + loopIndex);
			tabItem.setControl(text);
		}
		
		updateLayoutData( folder );
		
		return folder;
	}
	
	public static TabFolder createEmptyFolder( Composite parent, int style ) {
		TabFolder folder = new TabFolder( parent, style );
		updateLayoutData( folder );
		return folder;
	}
	
	private static void updateLayoutData( TabFolder folder ) {
		GridData deviceData = new GridData( );
		// stretch to fill the cell vertically
		deviceData.verticalAlignment = SWT.FILL;
		deviceData.grabExcessVerticalSpace = true;
		// and horizontally
		deviceData.horizontalAlignment = SWT.FILL;
		deviceData.grabExcessHorizontalSpace = true;
		
		folder.setLayoutData( deviceData );
	}
}
