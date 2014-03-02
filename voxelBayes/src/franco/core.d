// dmd -I~/Documents/scid/generated/headers -m32 -c franco/core.d

module franco.core;

import std.stdio;
import std.algorithm;

import scid.matrix;
import franco.matrix;
import franco.types;

voxelLike!(Tmat, Tpdf) reconstruct(Tpdf, Tmat, Timg)(photoModel!(Tmat, Timg)[] models) {
	auto voxel = new voxelLike!(Tmat, Tpdf);
	
	Tmat[3] minxyz = [1e10, 1e10, 1e10];
	Tmat[3] maxxyz = [-1e10, -1e10, -1e10];
	photoModel!(Tmat, Timg)[3] minModel;
	photoModel!(Tmat, Timg)[3] maxModel;
	
	foreach(ref model; models) {
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
	voxel.setDimensions(length, point3!Tmat(center), 1000);
	
	return voxel;
}
