// dmd -I~/Documents/scid/generated/headers -m32 -c franco/core.d

module franco.core;

import std.stdio;

import scid.matrix;
import franco.matrix;
import franco.types;

voxelLike!(Tvox) reconstruct(Tvox, Tmat, Timg)(photoModel!(Tmat, Timg)[] models) {
	auto voxel = new voxelLike!Tvox;
	
	Tmat[3] minxyz = [1e10, 1e10, 1e10];
	Tmat[3] maxxyz = [-1e10, -1e10, -1e10];
	
	foreach(ref model; models) {
		foreach(int i; 0..3) {
			if(model.extrinsics[i, 3] < minxyz[i]) {
				minxyz[i] = model.extrinsics[i, 3];
			}
			if(model.extrinsics[i, 3] > maxxyz[i]) {
				maxxyz[i] = model.extrinsics[i, 3];
			}
		}
	}
	minxyz[0].writeln;
	maxxyz.writeln;
	minxyz.sort[0].writeln;
	maxxyz.sort.writeln;
	
	return voxel;
}
