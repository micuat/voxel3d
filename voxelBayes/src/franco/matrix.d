//dmd -I~/Documents/scid/generated/headers -m32 -c franco/matrix.d

module franco.matrix;

import std.traits;

import scid.bindings.lapack.dlapack;
import scid.core.fortran;
import scid.core.memory;
import scid.core.meta;
import scid.core.testing;
import scid.core.traits;
import scid.linalg;
import scid.matrix;
import scid.util;

pragma(lib, "blas");
pragma(lib, "lapack");

version(unittest) {
	import scid.core.testing; 
	import std.math;
}

MatrixView!(T) concatVertical(T)
(const MatrixView!(T) m1, const MatrixView!(T) m2)
{
	assert( m1.cols == m2.cols );
	
	auto r = m1.rows + m2.rows;
	auto c = m1.cols;
	auto m = matrix!T(r, c);
	
	foreach(j; 0..c) {
		foreach(i; 0..m1.rows) {
			m.array[i + j * r] = m1.array[i + j * m1.rows];
		}
		foreach(i; 0..m2.rows) {
			m.array[i + m1.rows + j * r] = m2.array[i + j * m2.rows];
		}
	}
	return m;
}

MatrixView!(T) concatHorizontal(T)
(const MatrixView!(T) m1, const MatrixView!(T) m2)
{
	assert( m1.rows == m2.rows );
	
	auto r = m1.rows;
	auto c = m1.cols + m2.cols;
	
	T[] a;
	a = cast(T[])m1.array ~ cast(T[])m2.array;
	auto m = MatrixView!T(a, r, c);
	
	return m;
}

unittest
{
	auto m = matrix!real(2, 3, 2.0);
	auto m2 = matrix!real(2, 3, 1.0);
	
	check( concatVertical(m, m2)[3, 1] == 1.0 );
	check( concatHorizontal(m2, m)[1, 5] == 2.0 );
}

MatrixView!(T) add(T)
(const MatrixView!(T) m1, const MatrixView!(T) m2)
{
	auto a = m1.array.dup;
	a[] = a[] + m2.array[];
	return MatrixView!(T)(a, m1.rows, m1.cols);
}

MatrixView!(T) sub(T)
(const MatrixView!(T) m1, const MatrixView!(T) m2)
{
	auto a = m1.array.dup;
	a[] = a[] - m2.array[];
	return MatrixView!(T)(a, m1.rows, m1.cols);
}

MatrixView!(T) mul(T)
(const MatrixView!(T) m1, const MatrixView!(T) m2)
{
	auto r = m1.rows;
	auto c = m2.cols;
	T[] a;
	a.length = r * c;
	foreach(j; 0..c ) {
		foreach(i; 0..r) {
			a[i + j * r] = 0;
			foreach(k; 0..m1.cols) {
				a[i + j * r] += m1.array[i + k * r] * m2.array[k + j * r];
			}
		}
	}
	return MatrixView!(T)(a, r, c);
}

MatrixView!(T) mul(T, T2)
(const MatrixView!(T) m, T2 scalar)
if( isBasicType!(T2) )
{
	T[] a = m.array.dup;
	a[] *= scalar;
	return MatrixView!(T)(a, m.rows, m.cols);
}

MatrixView!(T) div(T, T2)
(const MatrixView!(T) m, T2 scalar)
if( isBasicType!(T2) )
{
	T[] a = m.array.dup;
	a[] /= scalar;
	return MatrixView!(T)(a, m.rows, m.cols);
}

MatrixView!(T) t(T)
(const MatrixView!(T) m)
{
	auto mt = matrix!(T)(m.cols, m.rows);
	foreach(j; 0..m.cols) {
		foreach(i; 0..m.rows) {
			mt.array[j + i * mt.rows] = m.array[i + j * m.rows];
		}
	}
	return mt;
}

MatrixView!(T) inv(T)
(const MatrixView!(T) m)
{
	auto minv = m.copy;
	invert(minv);
	return minv;
}
unittest
{
	auto m = matrix!real(3, 3, 2.5);
	auto m2 = matrix!real(3, 3, 1.0);
	check( add(m, m2)[1, 1] == 3.5 );
	check( sub(m, m2)[1, 1] == 1.5 );
	check( mul(m, m2)[1, 1] == 7.5 );
	check( mul(m, 4.0)[1, 1] == 10.0 );
	check( div(m, 5.0)[1, 1] == 0.5 );
	
	m[1, 2] = 5.0;
	check( t(m)[2, 1] == 5.0 );
}

T dot(T)
(const MatrixView!(T) p1, const MatrixView!(T) p2)
{
	return mul(t(p1), p2)[0, 0];
}

MatrixView!(T) point2(T)(T[] init) pure
{
	auto array = new T[2];
	array[] = init;
	return typeof(return)(array, 2, 1);
}

unittest
{
	auto p1 = point2!real([1.0, 2.0]);
	auto p2 = point2!real([2.0, 3.0]);
	check( add(p1, p2)[1, 0] == 5.0 );
	check( sub(p1, p2)[1, 0] == -1.0 );
	check( mul(p1, 4.0)[1, 0] == 8.0 );
	check( div(p1, 5.0)[1, 0] == 0.4 );
	check( dot(p1, p2) == 8.0 );
}

MatrixView!(T) point3(T)(T[] init) pure
{
	auto array = new T[3];
	array[] = init;
	return typeof(return)(array, 3, 1);
}

unittest
{
	auto p1 = point3!real([2.0, 3.0, 5.0]);
	auto p2 = point3!real([3.0, 5.0, 6.0]);
	check( add(p1, p2)[1, 0] == 8.0 );
	check( sub(p1, p2)[1, 0] == -2.0 );
	check( mul(p1, 4.0)[1, 0] == 12.0 );
	check( div(p1, 5.0)[1, 0] == 0.6 );
	check( dot(p1, p2) == 51.0 );
}


/** Calculate the Moore-Penrose pseudoinverse of a matrix.
 
 Currently only defined for general real matrices.
 */
T[] pseudoInvert(T, Storage stor)(ref MatrixView!(T, stor) m)
if (isFortranType!T  &&  !scid.core.traits.isComplex!T
	&&  stor == Storage.General)
body
{
	mixin (newFrame);
	// Calculate optimal workspace size.
	int info;
	char optu = 'A', optvt = 'A'; // full matrices
	T optimal;
	gesvd(
		  optu, optvt,
		  toInt(m.rows), toInt(m.cols), null, toInt(m.leading), // Info about M
		  null,
		  null, toInt(m.rows),
		  null, toInt(m.cols),
		  &optimal, -1, // Do workspace query
		  info);
	
	// Allocate workspace memory.
	T[] work = newStack!T(cast(int)(optimal));
	
	auto u = matrix!T(m.rows, m.rows);
	T[] s;
	s.length = m.rows;
	auto vt = matrix!T(m.cols, m.cols);
	
	// Perform singular value decomposition.
	gesvd(
		  optu, optvt,
		  toInt(m.rows), toInt(m.cols), m.array.ptr, toInt(m.leading), // Matrix
		  s.ptr,
		  u.array.ptr, toInt(u.leading),
		  vt.array.ptr, toInt(vt.leading),
		  work.ptr, toInt(work.length), // Workspace
		  info);
	
	assert (info == 0);
	
	auto v = vt.t;
	foreach(j; 0..m.rows) {
		foreach(i; 0..m.cols) {
			if(s[i] > 0.5) {
				v[j, i] /= s[i];
			} else {
				s[i] = 0;
				v[j, i] = 0;
			}
		}
	}
	m = v.mul(u.t);
	
	return s;
}
