// dmd -I~/Documents/scid/generated/headers -m32 -c franco/types.d

module franco.types;

import std.stdio;

import scid.matrix;
import franco.matrix;

extern (C) struct francoPhotofub {
	float m[16];
	int width;
	int height;
	ubyte *image;
}

extern (C) struct francoVoxelf {
	float side;
	int numVoxels;
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
	
	void reconstruct() {
		foreach(int i, ref p; pdf) {
			foreach(ref model; _models) {
//				project()
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
			
			Tmat length;
			int edgeDim;
			foreach(int i; 0..2) {
				if(diffxyz[i] > length) {
					edgeDim = i;
					length = diffxyz[i];
				}
			}
			edgeDim.writeln;
			// center is on the halfway of the edges
			float[3] center;
			foreach(int i; 0..3) {
				center[i] = maxModel[edgeDim].extrinsics[i, 3] + minModel[edgeDim].extrinsics[i, 3];
				center[i] /= 2;
			}
			center.writeln;
			
			setDimensions(length, point3!Tmat(center), 200);
		}
		
		francoVoxelf fVoxel() {
			francoVoxelf fv;
			fv.side = _side;
			fv.numVoxels = _numVoxels;
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
