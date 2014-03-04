//dmd -I~/Documents/scid/generated/headers -m32 -c franco/matrix.d

module franco.matrix;

import std.traits;
import scid.matrix;
import scid.linalg;

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
	
	foreach( typeof(c) j; 0..c ) {
		foreach( typeof(m1.rows) i; 0..m1.rows ) {
			m.array[i + j * r] = m1.array[i + j * m1.rows];
		}
		foreach( typeof(m2.rows) i; 0..m2.rows ) {
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
	foreach( typeof(c) j; 0..c ) {
		foreach( typeof(r) i; 0..r ) {
			a[i + j * r] = 0;
			foreach( size_t k; 0..m1.cols ) {
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
	foreach( typeof(a.length) i; 0..a.length ) {
		a[i] = a[i] * scalar;
	}
	return MatrixView!(T)(a, m.rows, m.cols);
}

MatrixView!(T) div(T, T2)
(const MatrixView!(T) m, T2 scalar)
if( isBasicType!(T2) )
{
	T[] a = m.array.dup;
	foreach( typeof(a.length) i; 0..a.length ) {
		a[i] = a[i] / scalar;
	}
	return MatrixView!(T)(a, m.rows, m.cols);
}

MatrixView!(T) t(T)
(const MatrixView!(T) m)
{
	auto mt = matrix!(T)(m.cols, m.rows);
	foreach( typeof(m.cols) j; 0..m.cols ) {
		foreach( typeof(m.rows) i; 0..m.rows ) {
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
