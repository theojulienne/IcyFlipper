module flipper.flash.base;

import flipper.board;
import flipper.chip;
import flipper.memory;

class Flash : Memory {
	this( Chip c ) {
		super( c );
	}
}
