// dmd -I~/Documents/scid/generated/headers -m32 -c franco/wrapper.d

module franco.wrapper;

import core.memory;
import std.stdio;

import scid.matrix;
import franco.matrix;

extern (C) struct francoPhoto {
	float m[16];
	int width;
	int height;
	ubyte *image;
}

extern (C) struct francoVoxel {
	int width;
	int height;
	int depth;
	int *pdf;
}

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

extern (C) francoVoxel francoReconstruct(francoPhoto *fp, int numPhoto) {
	francoVoxel fVoxel;
	
	photoModel!(float, ubyte)[] models;
	models.length = numPhoto;
	foreach(int i; 0..numPhoto) {
		auto model = new photoModel!(float, ubyte)(fp[i]);
		model.extrinsics.writeln;
		models[i] = model;
	}
	
	return fVoxel;
}

extern(C) int ofmain();
void main() {
	ofmain();
}
