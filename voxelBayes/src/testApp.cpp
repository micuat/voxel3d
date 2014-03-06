#include "testApp.h"

//--------------------------------------------------------------
void testApp::setup(){
	ofSetLogLevel(OF_LOG_VERBOSE);
	ofSetVerticalSync(true);
	
	mesh.load("lofi-bunny.ply");
	backImage.loadImage("background.jpg");
	
	Intr.resize(NUM_PERS);
	Extr.resize(NUM_PERS);
	
	ofMatrix4x4 R, T;
	
	f = 1500;
	fx = f;
	fy = f;
	cx = w/2 + 0.5;
	cy = h/2 + 0.5;
	
	nearDist = 0.1;
	farDist = 10000.0;
	
	
	for( int i = 0; i < Extr.size(); i++ ) {
		ofMatrix4x4 proj(f, 0, cx, 0,
						 0, f, cy, 0,
						 0, 0, 1, 0,
						 0, 0, 0, 0);
		
		Intr.at(i) = proj;
	}		
	for( int i = 0; i < Extr.size() - 1; i++ ) {
		ofMatrix4x4 pre;
		pre.makeIdentityMatrix();
		if(i % 2 == 0) {
			pre.rotate(-30, 1, 0, 0);
			pre.translate(0, 750, 0);
		}
		R.makeIdentityMatrix();
		R.rotate(i * 360 / (Extr.size() - 1), 0, 1, 0);
		T.makeIdentityMatrix();
		T.translate(0, 0, 1500);
		Extr.at(i) = ofMatrix4x4::getTransposedOf(pre * T * R);
	}
	R.makeIdentityMatrix();
	R.rotate(-90, 1, 0, 0);
	T.makeIdentityMatrix();
	T.translate(0, 1500, 0);
	Extr.at(Extr.size() - 1) = ofMatrix4x4::getTransposedOf(R * T);
	
	float hside = 2000;
//	background = ofMesh::box(side, side, side);
	background.setMode(OF_PRIMITIVE_TRIANGLE_STRIP);
	background.addVertex(ofVec3f(-hside,  hside, -hside));
	background.addVertex(ofVec3f( hside,  hside, -hside));
	background.addVertex(ofVec3f( hside, -hside, -hside));
	background.addVertex(ofVec3f(-hside, -hside, -hside));
	background.addVertex(ofVec3f(-hside,  hside, -hside));
	background.addTexCoord(ofVec2f(0, 0));
	background.addTexCoord(ofVec2f(backImage.getWidth(), 0));
	background.addTexCoord(ofVec2f(backImage.getWidth(), backImage.getHeight()));
	background.addTexCoord(ofVec2f(0, backImage.getHeight()));
	background.addTexCoord(ofVec2f(0, 0));
	
	displayChannel = 0;
	doProcess = false;
	drawForeground = true;
	drawBackground = true;
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
			p[i].image = (uint *)images.at(i).getPixels();
			p[i].background = (uint *)backs.at(i).getPixels();
		}
		
		francoParamf fparam;
		fparam.pD = 0.9;
		fparam.pFA = 0.1;
		fparam.k = 1;
		francoVoxelf v;
		v = francoReconstructfui(p, NUM_PERS, fparam);
		
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
				voxel.addColor(ofFloatColor(ofMap(p, 0.5, 1.0, 0.0, 1.0)));
			}
		}
		
		doProcess = false;
	}		
}

void testApp::drawFore(bool wire) {
	ofPushStyle();
	ofSetColor(50, 10, 255);
	
	ofPushMatrix();
	ofTranslate(200, 0, 0);
	if( wire ) mesh.drawWireframe();
	else mesh.drawFaces();
	ofPopMatrix();
	
	ofPushMatrix();
	ofTranslate(-200, 0, 0);
	if( wire ) mesh.drawWireframe();
	else mesh.drawFaces();
	ofPopMatrix();
	
	ofPopStyle();
}
	
void testApp::drawBack() {
	ofPushMatrix();
	backImage.bind();
	for( int i = 0; i < 4; i++ ) {
		background.drawFaces();
		ofRotate(90, 0, 1, 0);
	}
	backImage.unbind();
	ofPopMatrix();
}

void testApp::drawCameras() {
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
}	

//--------------------------------------------------------------
void testApp::draw(){
	ofEnableDepthTest();
	glPointSize(2);
	ofBackground(0);
	ofSetColor(255);
	
	if( displayChannel == 0 ) {
		cam.begin();
		
		if( drawForeground ) {
			drawFore(true);
		}
		voxel.drawVertices();
		if( drawBackground ) {
			drawBack();
		}
		
		drawCameras();
		
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
		
		// add noise
		ofTranslate(rRand(20), rRand(20), rRand(20));
		ofRotate(rRand(10), ofRandom(1), ofRandom(1), ofRandom(1));
		
		ofImage image;
		
		drawBack();
		
		image.allocate(w, h, OF_IMAGE_COLOR_ALPHA);
		image.grabScreen(0, 0, w, h);
		image.setImageType(OF_IMAGE_COLOR_ALPHA);
		//image.saveImage(ofToString(displayChannel) + "back.png");
		backs.push_back(image);
		
		drawFore(false);
		
		image.allocate(w, h, OF_IMAGE_COLOR_ALPHA);
		image.grabScreen(0, 0, w, h);
		image.setImageType(OF_IMAGE_COLOR_ALPHA);
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
		backs.clear();
		displayChannel = (displayChannel + 1);
	}
	
	if( key == 'd' ) {
		drawForeground = !drawForeground;
	}
	if( key == 'f' ) {
		drawBackground = !drawBackground;
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
