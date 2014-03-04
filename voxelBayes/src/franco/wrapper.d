// dmd -I~/Documents/scid/generated/headers -m32 -c franco/wrapper.d

module franco.wrapper;

import std.stdio;

import scid.matrix;
import franco.matrix;
import franco.types;

extern (C) francoVoxelf francoReconstructfub(francoPhotofub *fp, int numPhoto) {
	francoVoxelf fVoxel;
	
	photoModel!(float, ubyte)[] models;
	models.length = numPhoto;
	foreach(int i; 0..numPhoto) {
		auto model = new photoModel!(float, ubyte)(fp[i]);
		model.intrinsics.writeln;
		model.extrinsics.writeln;
		model.projection.writeln;
		models[i] = model;
	}
	
	auto voxel = new voxelLike!(float, ubyte);
	voxel.models = models;
	voxel.reconstruct;
	fVoxel = voxel.fVoxel;
	
	return fVoxel;
}

extern(C) int ofmain();
void main() {
	ofmain();
}
