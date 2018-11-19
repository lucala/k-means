// color map
color[] colors = {
	color(255, 0, 0),
	color(0, 255, 0),
	color(0, 0, 255),
	color(255, 255, 0),
	color(255, 0, 255),
	color(0, 255, 255),
	color(random(255), random(255), random(255))
};

// nr of clusters to generate
nrClusters = 6;
// range of mean vector (-pRange, pRange)
int pRange = 250;
// range of std deviation (1, dRange)
int dRange = 80;
Cluster[] clusters = new Cluster[nrClusters];
PVector orthMouseVec = new PVector(0, 0, 0);
// length of coordinate axis
int coordLen = 500;
float x,y,z,t;
float angle;
// 1=true colors, 2=predicted colors, 3=all white
int colorClusters;
bool spaceBarPressed;
LloydAlgo lloyd;

void setup() {
	size(window.innerWidth, window.innerHeight, P3D);
	stroke(255);
	x = width/2;
	y = height/2;
	z = 0;

	for (int cid = 0; cid < nrClusters; cid++){
		nrPoints = random(300,500);
		clusters[cid] = new Cluster(pRange, dRange, nrPoints, colors[cid]);
	}

	//maybe add heuristic algo here to find nrClusters
	suggestedNrClusters = nrClusters;
	lloyd = new LloydAlgo(suggestedNrClusters, pRange);
}

void draw() {
	background(50); //deletes previously drawn objects
	stroke(255);
	lights();
	String s = "1=True clusters, 2=predicted clusters, 3=all white.";
	s += "\nPress spacebar for Lloyd's algorithm.";
	s += "\nDrag mouse to rotate.";
	textSize(20);
	fill(255);
	text(s, 10, 10, 500, 500);  // Text wraps within text box

	if ((mousePressed == true) && (mouseY != pmouseY && mouseX != pmouseX)) {
    //angle = atan2(mouseY-pmouseY, mouseX-pmouseX);
		orthMouseVec = new PVector(mouseY-pmouseY, -(mouseX-pmouseX), 0); // this is axis of rotation
		orthMouseVec.normalize();
  }

	//rotate( -angle, orthMouseVec.x, orthMouseVec.y, orthMouseVec.z );
	translate(x,y,z);
	rotate(1, orthMouseVec.x, orthMouseVec.y, orthMouseVec.z);
  line(0, 0, 0, coordLen, 0, 0);
	line(0, 0, 0, 0, coordLen, 0);
	line(0, 0, 0, 0, 0, coordLen);
	noStroke();
	for (cluster : clusters){
		cluster.display();
	}

	if (spaceBarPressed){
		lloyd.iter();
		spaceBarPressed = false;
	}

	if (colorClusters == 2)
		lloyd.displayCentroids();

}

class LloydAlgo{
	PVector[] centroids;

	LloydAlgo(nrCentroids, mltplier){
		// initialize centroids randomly
		centroids = new PVector[nrCentroids];
		for (int i = 0; i < nrCentroids; i++){
			centroids[i] = PVector.mult(PVector.random3D(),mltplier);
		}
		// assign data points to centroids
		for (int i = 0; i < nrClusters; i++){
			for (int j = 0; j < clusters[i].data.length; j++){
				//compute distance to each centroid, belongs to centroid with smallest dist
				PVector point = clusters[i].data[j];
				smallestDist = 1e9;
				for (int c = 0; c < centroids.length; c++){
					dist = PVector.dist(centroids[c], point);
					if (dist < smallestDist){
						smallestDist = dist;
						clusters[i].cID[j] = c;
					}
				}
			}
		}
	}

	void displayCentroids(){
		for (int i = 0; i < centroids.length; i++){
			pushMatrix();
			translate(centroids[i].x, centroids[i].y, centroids[i].z);
			fill(colors[i]);
			sphere(10);
			popMatrix();
		}
	}

	void iter(){
		// init values for new centroid position
		PVector[] sum = new PVector[centroids.length];
		int[] nrEntries = new int[centroids.length];
		for (int c = 0; c < centroids.length; c++){
			sum[c] = new PVector();
			nrEntries[c] = 0;
		}

		// assign each data point to a cluster
		for (int i = 0; i < nrClusters; i++){
			for (int j = 0; j < clusters[i].data.length; j++){
				//compute distance to each centroid, belongs to centroid with smallest dist
				PVector point = clusters[i].data[j];
				smallestDist = 1e9;
				for (int c = 0; c < centroids.length; c++){
					dist = PVector.dist(centroids[c], point);
					if (dist < smallestDist){
						smallestDist = dist;
						clusters[i].cID[j] = c;
					}
				}
				// this data point can be added to mean vec of its predicted centroid
				currCentroid = clusters[i].cID[j];
				nrEntries[currCentroid]++;
				sum[currCentroid].add(point);
			}
		}
		// average sum vector to obtain new centroid positions
		for (int c = 0; c < centroids.length; c++){
			centroids[c] = PVector.div(sum[c], nrEntries[c]);
		}
	}

}

class Cluster{
	PVector[] data;
	// color ID for every data point for clustering algo
	int[] cID;
	// true cluster color
	color clColor;

	Cluster(int meanRange, int stdRange, int nrPoints, color cin){
		clColor = cin;
		meanVec = new PVector(random(-meanRange, meanRange), random(-meanRange, meanRange), random(-meanRange, meanRange));
		stdVec = new PVector(random(1, stdRange), random(1, stdRange), random(1, stdRange));
		data = new PVector[nrPoints];
		cID = new int[nrPoints];
		for (int i = 0; i < nrPoints; i++){
			gauss3D = new PVector(randomGaussian(), randomGaussian(), randomGaussian());
			gauss3DScaled = new PVector(gauss3D.x*stdVec.x, gauss3D.y*stdVec.y, gauss3D.z*stdVec.z);
			data[i] = PVector.add(meanVec, gauss3DScaled);
		}
	}

	void display(){
		for (int i = 0; i < data.length; i++){
			pushMatrix();
			translate(data[i].x, data[i].y, data[i].z);
			if (colorClusters == 1)
				fill(clColor);
			else if(colorClusters == 2)
				fill(colors[cID[i]]);
			else
				fill(255);
			sphere(1);
			popMatrix();
		}
	}
}

void keyPressed() {
	if (key == '1') {
		// show true clusters
		colorClusters = 1;
	}
	else if (key == '2') {
		// show predicted clusters
		colorClusters = 2;
	}
	else if (key == '3'){
		// show white
		colorClusters = 3;
	}
	else if (key == ' '){
		spaceBarPressed = true;
	}
}
