#pragma once

#include "ofMain.h"
#include "ofxOpenCv.h"

#define NUM_PERS 8

extern "C" {
	struct francoPhoto {
		float m[16];
		int width;
		int height;
		uchar *image;
	};
	
	struct francoVoxel {
		int width;
		int height;
		int depth;
		int *pdf;
	};
	
	struct francoVoxel francoReconstruct(struct francoPhoto *, int);
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
	ofEasyCam cam;
	
	static const int h = 800;
	static const int w = 1280;
	
	vector<ofMatrix4x4> P;
	vector<ofImage> images;
	francoPhoto p[NUM_PERS];
	int displayChannel;
	bool doProcess;
};
