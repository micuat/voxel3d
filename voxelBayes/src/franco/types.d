// dmd -I~/Documents/scid/generated/headers -m32 -c franco/types.d

module franco.types;

import std.stdio;

import scid.matrix;
import franco.matrix;

extern (C) struct francoPhotofub {
	float intrinsics[9];
	float extrinsics[12];
	int width;
	int height;
	ubyte *image;
}

extern (C) struct francoVoxelf {
	float side;
	int numVoxels;
	float center[3];
	float *pdf;
}

class photoModel(Tmat, Timg) {
public:
	this() {
	}
	
	this(in francoPhotofub fp) {
		setFromFrancoPhoto(fp);
	}
	
	void setFromFrancoPhoto(in ref francoPhotofub fp) {
		_intrinsics = matrix!Tmat(3, 3);
		_intrinsics.array = fp.intrinsics.dup;
		_extrinsics = matrix!Tmat(3, 4);
		_extrinsics.array = fp.extrinsics.dup;
		
		auto extrinsics4x4 = _extrinsics.concatVertical(MatrixView!Tmat([0, 0, 0, 1], 1, 4));
		auto extrinsicsInv4x4 = extrinsics4x4.inv;
		_extrinsicsInv = matrix!Tmat(3, 4);
		foreach(int i; 0..3) {
			foreach(int j; 0..4) {
				_extrinsicsInv[i, j] = extrinsicsInv4x4[i, j];
			}
		}
		
		int w = fp.width;
		int h = fp.height;
		_image = matrix!Timg(w, h);
		_image.array[0..h*w] = fp.image[0..h*w];
	}
	
	// image is transposed
	Timg getPixel(MatrixView!Tmat pixel) {
		return _image[cast(uint)pixel[0, 0], cast(uint)pixel[1, 0]];
	}
	
	Timg getPixel(int x, int y) {
		return _image[x, y];
	}
	
	@property {
		uint w() const {
			return _image.rows;
		}
		uint h() const {
			return _image.cols;
		}
		MatrixView!Tmat intrinsics() const {
			return _intrinsics.copy;
		}
		MatrixView!Tmat extrinsics() const {
			return _extrinsics.copy;
		}
		MatrixView!Tmat projection() const {
			return _intrinsics.mul(_extrinsicsInv);
		}
		MatrixView!Timg image() const {
			return _image.copy;
		}
	}
	
private:
	MatrixView!Tmat _intrinsics;
	MatrixView!Tmat _extrinsics;
	MatrixView!Tmat _extrinsicsInv;
	MatrixView!Timg _image; // transposed
}

class voxelLike(Tmat, Timg) {
public:
	Tmat pD, pFA, k;
	
	this() {
	}
	
	void setDimensions(Tmat side, MatrixView!Tmat center, int numVoxels) {
		_side = side;
		_voxelSide = side / numVoxels;
		_center = center.copy;
		_numVoxels = numVoxels;
		pdf.length = numVoxels * numVoxels * numVoxels;
	}
	
	MatrixView!Tmat indexToPosition(int index) {
		Tmat[3] position;
		position[0] = index % _numVoxels - _numVoxels / 2;
		position[1] = (index / _numVoxels) % _numVoxels - _numVoxels / 2;
		position[2] = index / (_numVoxels * _numVoxels) - _numVoxels / 2;
		position[] *= _voxelSide;
		return point3!Tmat(position).add(_center);
	}
	
	MatrixView!Tmat toHomogeneous(MatrixView!Tmat p) {
		assert((p.rows == 2 || p.rows == 3) && (p.cols == 1));
		
		MatrixView!Tmat ph;
		if(p.rows == 2) {
			ph = matrix!Tmat(3, 1);
			ph.array = p.array.dup;
			ph.array.length = 3;
			ph[2, 0] = 1.0;
		} else if(p.rows == 3) {
			ph = matrix!Tmat(4, 1);
			ph.array = p.array.dup;
			ph.array.length = 4;
			ph[3, 0] = 1.0;
		}
		return ph;
	}
	
	void reconstruct() {
		foreach(int i, ref p; pdf) {
			Tmat pFill = 1;
			Tmat pNofill = 1;
			bool isUpdated = false;
			foreach(ref model; _models) {
				auto pixel = model.projection.mul(toHomogeneous(indexToPosition(i)));
				if( pixel[2, 0] < 0 ) {
					//"negative projection depth".writeln;
					continue;
				}
				int x = cast(int)(pixel[0, 0] / pixel[2, 0]);
				int y = cast(int)(pixel[1, 0] / pixel[2, 0]);
				if( x >= 0 && y >= 0 && x < model.w && y < model.h ) {
					if( model.getPixel(x, y) > 128) {
						pFill *= 1.1;
						pNofill *= 0.9;
						isUpdated = true;
					}
				}
			}
			if( isUpdated == true ) {
				p = pFill / (pFill + pNofill);
			} else {
				p = 0;
			}
		}
	}
	
	@property {
		// set model pointer and initialize
		void models(photoModel!(Tmat, Timg)[] m) {
			_models = m;
			
			Tmat[3] minxyz = [1e10, 1e10, 1e10];
			Tmat[3] maxxyz = [-1e10, -1e10, -1e10];
			photoModel!(Tmat, Timg)[3] minModel;
			photoModel!(Tmat, Timg)[3] maxModel;
			
			foreach(ref model; _models) {
				foreach(int i; 0..3) {
					if(model.extrinsics[i, 3] < minxyz[i]) {
						minxyz[i] = model.extrinsics[i, 3];
						minModel[i] = model;
					}
					if(model.extrinsics[i, 3] > maxxyz[i]) {
						maxxyz[i] = model.extrinsics[i, 3];
						maxModel[i] = model;
					}
				}
			}
			// find largest difference in xyz
			Tmat[3] diffxyz;
			diffxyz[] = maxxyz[] - minxyz[];
			diffxyz.writeln;
			
			Tmat length = 0;
			int edgeDim;
			foreach(int i; 0..2) {
				if(diffxyz[i] > length) {
					edgeDim = i;
					length = diffxyz[i];
				}
			}
			// center is on the halfway of the edges
			float[3] center;
			foreach(int i; 0..3) {
				center[i] = maxModel[edgeDim].extrinsics[i, 3] + minModel[edgeDim].extrinsics[i, 3];
				center[i] /= 2;
			}
			center.writeln;
			setDimensions(length, point3!Tmat(center), 50);
		}
		
		francoVoxelf fVoxel() {
			francoVoxelf fv;
			fv.side = _side;
			fv.numVoxels = _numVoxels;
			fv.center[0] = _center[0, 0];
			fv.center[1] = _center[1, 0];
			fv.center[2] = _center[2, 0];
			fv.pdf = pdf.ptr;
			return fv;
		}
	}
private:
	photoModel!(Tmat, Timg)[] _models;
	Tmat _side;
	Tmat _voxelSide;
	MatrixView!Tmat _center;
	int _numVoxels;
	Tmat[] pdf;
}
