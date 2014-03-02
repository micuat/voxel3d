#include "testApp.h"

//--------------------------------------------------------------
void testApp::setup(){
	ofSetLogLevel(OF_LOG_VERBOSE);
	
	mesh.load("lofi-bunny.ply");
	
	P.resize(NUM_PERS);
	
	ofMatrix4x4 R, T;
	
	for( int i = 0; i < P.size(); i++ ) {
		R.makeIdentityMatrix();
		R.rotate(i * 360 / P.size(), 0, 1, 0);
		T.makeIdentityMatrix();
		T.translate(0, 0, 1000);
		P.at(i) = T * R;
		for( int row = 0; row < 4; row++ )
			for( int col = 0; col < 4; col++ )
				p[i].m[row + 4*col] = P.at(i)(col, row);
		p[i].width = w;
		p[i].height = h;
		
		ofLogVerbose() << ofMatrix4x4::getTransposedOf(P.at(i));
	}
	
	displayChannel = 0;
	doProcess = false;
}

//--------------------------------------------------------------
void testApp::update(){
	if( doProcess ) {
		for( int i = 0; i < P.size(); i++ ) {
			p[i].image = images.at(i).getPixels();
		}
		
		francoVoxel v;
		v = francoReconstruct(p, NUM_PERS);
		
		doProcess = false;
	}		
}

//--------------------------------------------------------------
void testApp::draw(){
	ofBackground(0);
	ofSetColor(255);
	
	if( displayChannel == 0 ) {
		cam.begin();
		mesh.drawFaces();
		cam.end();
	} else {
		
		float f = 1000;
		
		ofSetupScreenPerspective(w, h);
		
		float w = ofGetScreenWidth();
		float h = ofGetScreenHeight();
		glViewport(0, 0, w, h);
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		float fx = f;
		float fy = f;
		float cx = w/2 + 0.5;
		float cy = h/2 + 0.5;
		
		float nearDist = 0.0001, farDist = 100000000.0;
		
		glFrustum(
				  nearDist * (-cx) / fx, nearDist * (w - cx) / fx,
				  nearDist * (cy - h) / fy, nearDist * (cy) / fy,
				  nearDist, farDist);
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		gluLookAt(
				  0, 0, 0,
				  0, 0, 1,
				  0, 1, 0);
		
		glMatrixMode(GL_PROJECTION);
		glMultMatrixf(P.at(displayChannel-1).getInverse().getPtr());
		mesh.drawFaces();
		ofImage image;
		image.allocate(w, h, OF_IMAGE_GRAYSCALE);
		image.grabScreen(0, 0, w, h);
		image.setImageType(OF_IMAGE_GRAYSCALE);
		//image.saveImage(ofToString(displayChannel) + ".png");
		images.push_back(image);
		displayChannel++;
		if( displayChannel > NUM_PERS ) {
			displayChannel = 0;
			doProcess = true;
		}
	}
}

//--------------------------------------------------------------
void testApp::keyPressed(int key){
	if( key == ' ' ) {
		images.clear();
		displayChannel = (displayChannel + 1);
	}
}

//--------------------------------------------------------------
void testApp::keyReleased(int key){

}

//--------------------------------------------------------------
void testApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void testApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void testApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void testApp::dragEvent(ofDragInfo dragInfo){ 

}
