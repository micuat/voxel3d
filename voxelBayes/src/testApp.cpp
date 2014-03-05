#include "testApp.h"

//--------------------------------------------------------------
void testApp::setup(){
	ofSetLogLevel(OF_LOG_VERBOSE);
	
	mesh.load("lofi-bunny.ply");
	
	Intr.resize(NUM_PERS);
	Extr.resize(NUM_PERS);
	
	ofMatrix4x4 R, T;
	float f = 1500;
	float cx = w/2 + 0.5;
	float cy = h/2 + 0.5;
	
	for( int i = 0; i < Extr.size(); i++ ) {
		R.makeIdentityMatrix();
		R.rotate(i * 360 / Extr.size(), 0, 1, 0);
		T.makeIdentityMatrix();
		T.translate(0, 0, 1000);
		Extr.at(i) = ofMatrix4x4::getTransposedOf(T * R);
		ofMatrix4x4 proj(f, 0, cx, 0,
						 0, f, cy, 0,
						 0, 0, 1, 0,
						 0, 0, 0, 0);
		
		Intr.at(i) = proj;
		ofLogVerbose() << "\n" << Extr.at(i);
		ofLogVerbose() << "\n" << proj * Extr.at(i);
	}
	
	displayChannel = 0;
	doProcess = false;
	drawMesh = true;
}

//--------------------------------------------------------------
void testApp::update(){
	if( doProcess ) {
		for( int i = 0; i < Intr.size(); i++ ) {
			for( int row = 0; row < 3; row++ )
				for( int col = 0; col < 3; col++ )
					p[i].intrinsics[row + 3*col] = Intr.at(i)(row, col);
			for( int row = 0; row < 3; row++ )
				for( int col = 0; col < 4; col++ )
					p[i].extrinsics[row + 3*col] = Extr.at(i)(row, col);
			p[i].width = w;
			p[i].height = h;
			p[i].image = images.at(i).getPixels();
		}
		
		francoParamf fparam;
		fparam.pD = 0.9;
		fparam.pFA = 0.1;
		fparam.k = 1;
		francoVoxelf v;
		v = francoReconstructfub(p, NUM_PERS, fparam);
		
		ofVec3f center(v.center[0], v.center[1], v.center[2]);
		int n = v.numVoxels;
		for( int i = 0; i < n*n*n; i++ ) {
			float p = *(v.pdf + i);
			if( p > 0.5 ) {
				ofVec3f pos;
				pos.x = i % n - n / 2;
				pos.y = (i / n) % n - n / 2;
				pos.z = i / (n * n) - n / 2;
				voxel.addVertex((pos * v.side / v.numVoxels) + center);
				voxel.addColor(ofFloatColor(p));
			}
		}
		
		doProcess = false;
	}		
}

//--------------------------------------------------------------
void testApp::draw(){
	ofEnableDepthTest();
	ofBackground(0);
	ofSetColor(255);
	
	float f = 1500;
	
	float fx = f;
	float fy = f;
	float cx = w/2 + 0.5;
	float cy = h/2 + 0.5;
	
	float nearDist = 0.1, farDist = 10000.0;
	
	if( displayChannel == 0 ) {
		cam.begin();
		
		if( drawMesh ) {
			ofPushStyle();
			ofSetColor(50, 10, 240);
			mesh.drawWireframe();
			ofPopStyle();
		}
		
		voxel.drawVertices();
		
		for( int i = 0; i < Extr.size(); i++ ) {
			ofPushMatrix();
			glMultMatrixf(ofMatrix4x4::getTransposedOf(Extr.at(i)).getPtr());
			ofDrawAxis(100);
			
			ofMatrix4x4 frustumMatrix;
			float nearDist = 50.0, farDist = 200.0;
			frustumMatrix.makeFrustumMatrix(nearDist * (-cx) / fx, nearDist * (w - cx) / fx,
											nearDist * (cy - h) / fy, nearDist * (cy) / fy,
											nearDist, farDist);
			frustumMatrix = frustumMatrix.getInverse();
			ofMultMatrix(frustumMatrix);
			ofLine(-1, -1, -1, -1, -1, 1);
			ofLine(1, -1, -1, 1, -1, 1);
			ofLine(-1, 1, -1, -1, 1, 1);
			ofLine(1, 1, -1, 1, 1, 1);
			ofNoFill();
			ofRect(-1, -1, 1, 2, 2);
			ofRect(-1, -1, -1, 2, 2);
			ofPopMatrix();
		}
		
		cam.end();
	} else {
		
		ofSetupScreenPerspective(w, h);
		
//		float w = ofGetScreenWidth();
//		float h = ofGetScreenHeight();
		glViewport(0, 0, w, h);
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		
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
		glMultMatrixf(ofMatrix4x4::getTransposedOf(Extr.at(displayChannel-1)).getInverse().getPtr());
		mesh.drawFaces();
		ofImage image;
		image.allocate(w, h, OF_IMAGE_GRAYSCALE);
		image.grabScreen(0, 0, w, h);
		image.setImageType(OF_IMAGE_GRAYSCALE);
		image.saveImage(ofToString(displayChannel) + ".png");
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
	
	if( key == 'd' ) {
		drawMesh = !drawMesh;
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
