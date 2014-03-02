// dmd -I~/Documents/scid/generated/headers -m32 -c franco/wrapper.d

module franco.wrapper;

import std.stdio;

import scid.matrix;
import franco.core;
import franco.matrix;
import franco.types;

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

extern (C) francoVoxel francoReconstruct(francoPhoto *fp, int numPhoto) {
	francoVoxel fVoxel;
	
	photoModel!(float, ubyte)[] models;
	models.length = numPhoto;
	foreach(int i; 0..numPhoto) {
		auto model = new photoModel!(float, ubyte)(fp[i]);
		model.extrinsics.writeln;
		models[i] = model;
	}
	
	auto voxel = reconstruct!(float, float, ubyte)(models);
	
	return fVoxel;
}

extern(C) int ofmain();
void main() {
	ofmain();
}
