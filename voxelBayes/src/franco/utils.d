module franco.utils;

import std.math;
import std.stdio;
import scid.matrix;
import scid.linalg;
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

MatrixView!Tout mean(Tin, Tin N, Tout)(Tin[N][] arr) {
	auto m = matrix!Tout(N, 1, 0);
	
	foreach(ref tuple; arr) {
		// tuple[N]
		foreach(int i, ref elem; tuple) {
			m[i, 0] += cast(Tout)elem;
		}
	}
	
	return m.div(cast(Tout)arr.length);
}

MatrixView!Tout covariance(Tin, Tin N, Tout)(Tin[N][] arr, MatrixView!Tout m) {
	auto cov = matrix!Tout(N, N);
	
	Tout[N][] diff;
	diff.length = arr.length;
	
	foreach(int j; 0..diff.length) {
		foreach(int i, ref x; diff[j]) {
			x = cast(Tout)arr[j][i] - m[i, 0];
			x = x * x;
		}
	}
	
	foreach(int ii; 0..N) {
		foreach(int jj; 0..N) {
			Tout sum = 0;
			foreach(int i; 0..diff.length) {
				sum += diff[i][ii] * diff[i][jj];
			}
			cov[ii, jj] = sqrt(sum / cast(Tout)diff.length);
		}
	}
	
	return cov;
}

Tout mvnpdf(Tin, Tin N, Tout)(Tin[N] sample, MatrixView!Tout m, MatrixView!Tout cov) {
	Tout coeff = pow(2 * PI, -0.5*N);
	coeff /= sqrt(det(cov));
	
	auto x = matrix!Tout(N, 1);
	foreach(int i; 0..N) {
		x[i, 0] = sample[i];
	}
	
	auto diff = x.sub(m);
	auto power = diff.t.mul(cov.inv.mul(diff));
	return coeff * exp(-0.5 * power[0, 0]);
}
