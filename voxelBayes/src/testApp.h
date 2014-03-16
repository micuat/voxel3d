#pragma once

#include "ofMain.h"
#include "ofxOpenCv.h"

#define NUM_PERS 16

extern "C" {
	// float-ubyte
	struct francoPhotofub {
		float intrinsics[9];
		float extrinsics[12];
		int width;
		int height;
		uchar *image;
		uchar *background;
	};
	
	// float-uint
	struct francoPhotofui {
		float intrinsics[9];
		float extrinsics[12];
		int width;
		int height;
		uint *image;
		uint *background;
	};
	
	// float
	struct francoParamf {
		float pD;
		float pFA;
		int k;
		int kbg;
	};
	
	// float
	struct francoVoxelf {
		float side;
		int numVoxels;
		float center[3];
		float *pdf;
	};
	
	struct francoVoxelf francoReconstructCovfub(struct francoPhotofub *, int, struct francoParamf);
	struct francoVoxelf francoReconstructCovfui(struct francoPhotofui *, int, struct francoParamf);
	struct francoVoxelf francoReconstructParzenfub(struct francoPhotofub *, int, struct francoParamf);
	struct francoVoxelf francoReconstructParzenfui(struct francoPhotofui *, int, struct francoParamf);
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
		
	inline float rRand(float r) {return ofRandom(2*r)-r;}
	void drawFore(bool);
	void drawBack();
	void drawCameras();
	
	ofVboMesh mesh;
	ofVboMesh voxel;
	ofVboMesh background, background2;
	ofImage backImage, backImage2;
	ofEasyCam cam;
	
	static const int h = 768;
	static const int w = 1024;
	
	vector<ofMatrix4x4> Intr;
	vector<ofMatrix4x4> Extr;
	vector<ofImage> images, backs;
	francoPhotofui p[NUM_PERS];
	int displayChannel;
	bool doProcess;
	bool saveImages;
	bool drawForeground, drawBackground, drawVoxel;
	
	float f;
	
	float fx;
	float fy;
	float cx;
	float cy;
	
	float nearDist, farDist;
	
	int scanMode;
};
