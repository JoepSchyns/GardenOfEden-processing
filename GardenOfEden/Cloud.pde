/*** Constants ***/
final int[] MIN_MAX_DIAMETER_CLOUD_ELIPSE = {20, 50};   // Min & Max size of an ellipse in a cloud
final int[] MIN_MAX_AMOUNT_CLOUD_ELIPSES = {5, 14};     // Min & Max amount of ellipses in a clound 
final int[] MAX_DIMENSIONS_CLOUD = {100, 50};           // Max width and height a cloud can be 
final int MAX_CLOUDS = 10;                              // Max amount of clouds that can be made

final float MAX_CLOUD_SPEED = 0.1f;   // Max speed a cloud can go
final float MIN_CLOUD_SPEED = 0.01f;  // Min speed a cloud can go

final color CLOUD_COLOR = color(255);  // Color of clouds


/*** Variables ***/
int timePreCloud;         // Previous time a cloud was added
float avgTimeInAir;       // Average time a cloud spends in the screens sky

ArrayList<Cloud> clouds = new ArrayList<Cloud>();              // List of all our clouds
ArrayList<Integer> timeNextCloud = new ArrayList<Integer>();   // List of times we will add new clouds

void drawClouds() {
  // Apply shadows and display all the clouds
  tint(brightnessBackground + 191 * abs(cos(myTime)) * (1 - abs(sin(myTime))), brightnessBackground + 127 * abs(cos(myTime))* (1 - abs(sin(myTime))), brightnessBackground); 
  for (int i =0; i < clouds.size (); i++) 
    clouds.get(i).drawCloud();

  // Remove shadows 
  noTint();
  // If our list of times when we should add clouds is lower than the max amount of clouds we can have we should determine a point of time to add one
  if (timeNextCloud.size() < MAX_CLOUDS) {
    // Determine average time it takes a cloud to cross the screen
    if (millis() > 500) { 
      avgTimeInAir = (((width / ( ((float)MAX_CLOUD_SPEED + MIN_CLOUD_SPEED) / 2.0 ) ) / frameRate) * 1000) / MAX_CLOUDS;
    } else {
      avgTimeInAir = (((width / (((float)MAX_CLOUD_SPEED + MIN_CLOUD_SPEED) / 2.0 )) / 60.0) * 1000) / MAX_CLOUDS;
    }
    timeNextCloud.add(round(random(avgTimeInAir)));
  }

  // Make a new cloud when we got space for one and the old one is longer gone than the timeNextCloud has determided
  if (clouds.size() < MAX_CLOUDS && millis() - timePreCloud > timeNextCloud.get(0)) { 
    timeNextCloud.remove(0); 
    clouds.add(new Cloud(clouds.size()));
  }
}

void contructClouds() {
  // Fill our list with clouds
  for (int i = 0; i < MAX_CLOUDS; i++) {
    clouds.add(new Cloud(clouds.size()));
    timeNextCloud.add( round(random(avgTimeInAir)) );
    clouds.get(clouds.size() - 1).pos.x = random(width - MAX_TERRAIN_HEIGHT);
  }
}
void removeCloud(int id) {
  // Removes a cloud from our list
  for (int i =clouds.size () - 1; i > id; i--) {
    clouds.get(i).subtractId();
  }
  clouds.remove(id);
}


/******* class Cloud *************
 Creates clouds that have:
 - random cloud shape
 - random speed
 - random location
 - get affected by the wind
 *********************************/
class Cloud {
  int id;
  int randomTime;
  float speed;

  PVector pos;
  PGraphics cloud;

  Cloud(int id_) {
    id = id_;

    // Generate the cloud grahpics, with random amount of ellipes, sizes and randomly positioned
    cloud = createGraphics(MAX_DIMENSIONS_CLOUD[0], MAX_DIMENSIONS_CLOUD[1]); 
    cloud.beginDraw();
    cloud.fill(CLOUD_COLOR); 
    cloud.noStroke();
    int amountEl = round( random(MIN_MAX_AMOUNT_CLOUD_ELIPSES[0], MIN_MAX_AMOUNT_CLOUD_ELIPSES[1]) ); 
    int[][] XYSizeEllipse = new int [amountEl][3]; 
    // Draw all ellipses
    for (int i = 0; i < amountEl; i++) { 
      // If we already have an ellipse in existance we should find a place that fits else make a new one
      if (i > 0) { 
        boolean nFits = true; 
        // Try to create an ellipse that fits
        while (nFits) { 
          int neighbour = round(random(0, i -1));  // Select an random neightbour
          float angle = random(TWO_PI);            // Random angle in relation to other ellipses

          XYSizeEllipse[i][2] = round( random(MIN_MAX_DIAMETER_CLOUD_ELIPSE[0], MIN_MAX_DIAMETER_CLOUD_ELIPSE[1]) );    // set size
          XYSizeEllipse[i][0] = round( cos(angle) * ((float)XYSizeEllipse[i][2] / 2.0) ) + XYSizeEllipse[neighbour][0]; //set x position 
          XYSizeEllipse[i][1] = round( sin(angle) * ((float)XYSizeEllipse[i][2] / 2.0) ) + XYSizeEllipse[neighbour][1]; //set y position

          // Check if generated cloud truely fits  
          if (XYSizeEllipse[i][0] > XYSizeEllipse[i][2] / 2 && XYSizeEllipse[i][0] < MAX_DIMENSIONS_CLOUD[0] - XYSizeEllipse[i][2] / 2 && XYSizeEllipse[i][1] > XYSizeEllipse[i][2] / 2 && XYSizeEllipse[i][1] < MAX_DIMENSIONS_CLOUD[1] - XYSizeEllipse[i][2] / 2)
            nFits = false;
        }
      } else { 
        XYSizeEllipse[i][2] = round(random(MIN_MAX_DIAMETER_CLOUD_ELIPSE[0], MIN_MAX_DIAMETER_CLOUD_ELIPSE[1]));          // set size
        XYSizeEllipse[i][0] = round(random(XYSizeEllipse[i][2] / 2, MAX_DIMENSIONS_CLOUD[0] - XYSizeEllipse[i][2] / 2 )); //set x position
        XYSizeEllipse[i][1] = round(random(XYSizeEllipse[i][2] / 2, MAX_DIMENSIONS_CLOUD[1] - XYSizeEllipse[i][2] / 2 )); //set y position
      }
      // Draw the actual ellipse
      cloud.ellipse(XYSizeEllipse[i][0], XYSizeEllipse[i][1], XYSizeEllipse[i][2], XYSizeEllipse[i][2]); //create ellipse
    }
    cloud.endDraw();

    // Give it a speed and position
    speed = random(MIN_CLOUD_SPEED, MAX_CLOUD_SPEED); 
    pos = new PVector(- MAX_DIMENSIONS_CLOUD[0], random(height - 2*MAX_TERRAIN_HEIGHT));
    
    // Time previous cloud was created, used for new cloud spawns
    timePreCloud = millis(); 
  }

  void drawCloud() {
    // Display cloud
    PVector wind = PVector.mult(getWind(pos), speed);
    pos.add(wind);
    image(cloud, pos.x, pos.y);
    // Destroy cloud if it escapes the screen
    if (pos.x >width) { 
      if (id > clouds.size() -1) 
        id = clouds.size() - 1;
      removeCloud(id);
    }
  }

  void subtractId() {
    id--;
  }
}
