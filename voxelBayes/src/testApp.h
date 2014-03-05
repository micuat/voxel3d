#pragma once

#include "ofMain.h"
#include "ofxOpenCv.h"

#define NUM_PERS 8

extern "C" {
	// float-ubyte
	struct francoPhotofub {
		float intrinsics[9];
		float extrinsics[12];
		int width;
		int height;
		uchar *image;
	};
	
	// float
	struct francoVoxelf {
		float side;
		int numVoxels;
		float center[3];
		float *pdf;
	};
	
	struct francoVoxelf francoReconstructfub(struct francoPhotofub *, int);
};

class testApp : public ofBaseApp{

	public:
		void setup();
		void update();
		void draw();

		void keyPressed(int key);
		void keyReleased(int key);
		void mouseMoved(int x, int y );
		void mouseDragged(int x, int y, int button);
		void mousePressed(int x, int y, int button);
		void mouseReleased(int x, int y, int button);
		void windowResized(int w, int h);
		void dragEvent(ofDragInfo dragInfo);
		void gotMessage(ofMessage msg);
		
	ofVboMesh mesh;
	ofVboMesh voxel;
	ofEasyCam cam;
	
	static const int h = 800;
	static const int w = 1280;
	
	vector<ofMatrix4x4> Intr;
	vector<ofMatrix4x4> Extr;
	vector<ofImage> images;
	francoPhotofub p[NUM_PERS];
	int displayChannel;
	bool doProcess;
};
