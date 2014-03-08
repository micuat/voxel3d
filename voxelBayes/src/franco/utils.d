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
	
	foreach(y; cy-halfk..cy+halfk+1) {
		foreach(x; cx-halfk..cx+halfk+1) {
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
	
	foreach(j; 0..diff.length) {
		foreach(i, ref x; diff[j]) {
			x = cast(Tout)arr[j][i] - m[i, 0];
			x = x * x;
		}
	}
	
	foreach(ii; 0..N) {
		foreach(jj; 0..N) {
			Tout sum = 0;
			foreach(i; 0..diff.length) {
				sum += diff[i][ii] * diff[i][jj];
			}
			cov[ii, jj] = sqrt(sum / cast(Tout)diff.length);
		}
	}
	
	return cov;
}

Tout mvnpdf(Tin, Tin N, Tout)(Tin[N] sample, MatrixView!Tout m, MatrixView!Tout cov) {
	static if(N == 1) {
		if(cov[0, 0] == 0) {
			// TODO: homogeneous background; this is tricky
			return 0;
		}
		//auto coeff = pow(2 * PI, -0.5) / cov[0, 0];
		auto diff = sample[0] - m[0, 0];
		auto power = diff * diff / cov[0, 0] / cov[0, 0];
		return exp(-0.5 * power);
	} else {
		auto covInv = cov.copy;
		auto sv = pseudoInvert(covInv);
		Tout pdet = 1;
		int count = 0;
		foreach(s; sv) {
			if(s > 0) {
				pdet *= s;
				count++;
			}
		}
		if(count == 0) {
			// TODO: homogeneous background; this is tricky
			return 0;
		}
		
		//Tout coeff = pow(2 * PI, -0.5*count) /= sqrt(pdet);
		
		auto x = matrix!Tout(N, 1);
		foreach(i; 0..N) {
			x[i, 0] = sample[i];
		}
		auto diff = x.sub(m);
		auto power = diff.dot(covInv.mul(diff));
		auto ret = exp(-0.5 * power);
		
		if(power < 0) {
			ret = 1;
		}
		return ret;
	}
}
