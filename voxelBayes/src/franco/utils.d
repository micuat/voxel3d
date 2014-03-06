module franco.utils;

import scid.matrix;
import franco.matrix;

MatrixView!int[] neighbors(MatrixView!int pos, int w, int h, int k) {
	return neighbors(cast(int)pos[0, 0], cast(int)pos[1, 0], w, h, k);
}

MatrixView!int[] neighbors(int cx, int cy, int w, int h, int k) {
	MatrixView!int[] ns;
	int halfk = (k - 1) / 2;
	
	foreach(int y; cy-halfk..cy+halfk+1) {
		foreach(int x; cx-halfk..cx+halfk+1) {
			if( x >= 0 && y >= 0 && x < w && y < h ) {
				ns ~= point2!int([x, y]);
			}
		}
	}
	
	return ns;
}
