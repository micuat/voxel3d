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

MatrixView!T mean(T, uint N)(T[N][] arr) {
	auto m = matrix!T(N, 1, 0);
	
	foreach(ref tuple; arr) {
		// tuple[N]
		m.array[] += tuple[];
	}
	
	return m.div(cast(T)arr.length);
}

MatrixView!T covariance(T, uint N)(T[N][] arr, MatrixView!T m) {
	auto cov = matrix!T(N, N);
	
	T[N][] diff;
	diff.length = arr.length;
	
	foreach(j; 0..diff.length) {
		foreach(i, ref x; diff[j]) {
			x = arr[j][i] - m[i, 0];
			x = x * x;
		}
	}
	
	foreach(ii; 0..N) {
		foreach(jj; ii..N) {
			T sum = 0;
			foreach(i; 0..diff.length) {
				sum += diff[i][ii] * diff[i][jj];
			}
			cov[ii, jj] = sqrt(sum / cast(T)diff.length);
			if(ii != jj) {
				cov[jj, ii] = cov[ii, jj];
			}
		}
	}
	
	return cov;
}

T mvnpdf(T, uint N)(T[N] sample, MatrixView!T m, MatrixView!T cov) {
	static if(N == 1) {
		if(cov[0, 0] == 0) {
			// homogeneous background; this is tricky
			if(!approxEqual(sample[0], m[0, 0], 1.5)) {
				return 0;
			} else {
				return 1;
			}
		}
		//auto coeff = pow(2 * PI, -0.5) / cov[0, 0];
		auto diff = sample[0] - m[0, 0];
		auto power = diff * diff / cov[0, 0] / cov[0, 0];
		return exp(-0.5 * power);
	} else {
		auto covInv = cov.copy;
		auto sv = pseudoInvert(covInv);
		T pdet = 1;
		int count = 0;
		foreach(s; sv) {
			if(s > 0) {
				pdet *= s;
				count++;
			}
		}
		if(count == 0) {
			// homogeneous background; this is tricky
			foreach(i, s; sample) {
				if(!approxEqual(s, m[i, 0], 1.5)) {
					return 0;
				}
			}
				
			return 1;
		}
		
		//Tout coeff = pow(2 * PI, -0.5*count) /= sqrt(pdet);
		
		auto x = matrix!T(N, 1);
		x.array[] = sample[];
		auto diff = x.sub(m);
		auto power = diff.dot(covInv.mul(diff));
		auto ret = exp(-0.5 * power);
		
		if(power < 0) {
			ret = 1;
		}
		return ret;
	}
}
