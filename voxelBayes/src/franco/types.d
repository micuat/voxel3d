// dmd -I~/Documents/scid/generated/headers -m32 -c franco/types.d

module franco.types;

import std.stdio;

import scid.matrix;
import franco.matrix;
import franco.wrapper;

class photoModel(Tmat, Timg) {
public:
	this() {
	}
	
	this(in francoPhoto fp) {
		setFromFrancoPhoto(fp);
	}
	
	void setFromFrancoPhoto(in ref francoPhoto fp) {
		_m = matrix!Tmat(4, 4);
		_m.array = fp.m.dup;
		
		int w = fp.width;
		int h = fp.height;
		_image = matrix!Timg(w, h);
		_image.array[0..h*w] = fp.image[0..h*w];
	}
	
	@property {
		MatrixView!Tmat extrinsics() const {
			return _m.copy;
		}
		void extrinsics(MatrixView!Tmat m) {
			_m = m;
		}
		MatrixView!Timg image() const {
			return _image.copy;
		}
	}
	
private:
	MatrixView!Tmat _m;
	MatrixView!Timg _image; // transposed
}

class voxelLike(T) {
public:
	this() {
	}
private:
	int width;
	int height;
	int depth;
	T[][][] pdf;
}
