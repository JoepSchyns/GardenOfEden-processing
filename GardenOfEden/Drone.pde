/*** Constants ***/
final int DRONE_RADIUS = 30;        // Radius of a drone
final int FRAMES_BETWEEN_SHOTS = 2; // Ticks between each time a drone shoots

final color TEAM_0_COLOR = color(100, 45, 201);  // Color of team 0
final color TEAM_1_COLOR = color(12, 202, 150);  // Color of team 1

/*** Variables ***/
int[] teamScore = new int[2];   // Kills that each team made

boolean flyDrones = true;       // Whether the drones are allowed to fly

PImage cloudCastle;                              // Image of the sky castle
PVector target = new PVector(random(400, 800), 
random(100, 400));  // Location of the sky castle


void droneKeyPressed() {
  // Use enter as a toggle button to allow flying
  if (key == ENTER) 
    flyDrones = !flyDrones;
}

void droneMousePressed() {
  // If right mouseButton is pressed move the sky castle
  if (mouseButton == RIGHT) {
    float yPos;
    // We cannot place the sky castle below 2 times the terrain height
    if (mouseY > height - MAX_TERRAIN_HEIGHT*2)
      yPos = height - MAX_TERRAIN_HEIGHT*2;
    else
      yPos = mouseY;

    target = new PVector(mouseX, yPos);
  }
}

void drawDroneTarget() {
  imageMode(CENTER);
  // Apply shadow, display the castle and remove the shadows
  tint(brightnessBackground + 191 * abs(cos(myTime)) * (1 - abs(sin(myTime))) + 20, brightnessBackground + 127 * abs(cos(myTime))* (1 - abs(sin(myTime))) + 20, brightnessBackground + 20); 
  image(cloudCastle, target.x, target.y);
  noTint();

  // Let the caslte move in the wind
  PVector wind = getWind(target);
  wind.mult(0.07);
  target.add(wind);

  // If the image leaves the screen on the right, make it appear on the left
  imageMode(CORNER);
  if (target.x >= width + cloudCastle.width / 2) {
    target.x = -cloudCastle.width / 2;
  }
}


void drawScores() {
  //Display kills each team made
  textSize(18);
  fill(TEAM_0_COLOR);
  text("Team 0 destroyed " + teamScore[0], 20, 20);
  fill(TEAM_1_COLOR);
  text("Team 1 destroyed " + teamScore[1], 20, 40);
}


/********** class Drone ****************
 Creates Drones that extends a normal ball that can:
 - extends a normal ball
 - shoot cannonBalls
 - that fight drones from another team
 - emit a particles when hit
 - avoid bullet of other team
 - gets pulled towards the sky castle
 - avoid being to close to other drones
 ********************************************/
class Drone extends Ball {
  int lifes = 10;          // Health point of the drone
  int framesBetweenShots;  // Ticks between now and last fired shot

  PVector normalizeHeading = new PVector(1, 0);   // Stabilisation angle for drawing the drone 
  PVector heading = new PVector(0, 0);            // Direction the drone is heading towards
  PImage droneImg;                                // Graphics of the drone

  ArrayList<float[]> posClosestDrone = new ArrayList<float[]>(); // Distance pos.x pos.y

  Drone(PVector pos_, PVector speed_, int id_, int team_) {
    super(pos_, speed_, id_, DRONE_RADIUS);
    team = team_;
    // Give each team its own color
    if (team == 0 ) { 
      myColor = TEAM_0_COLOR;
      droneImg =loadImage("drone0.png");
    } else {
      myColor = TEAM_1_COLOR;
      droneImg =loadImage("drone1.png");
    }

    // Set stabilisation angle for drawing the drone 
    normalizeHeading.normalize();
  }

  void move() {
    // If the drone is allowed to fly we make it fly
    if (flyDrones) {
      PVector steer = new PVector(0, 0);

      // Increase ticks
      framesBetweenShots++;

      // Clear closest drones from previous frame
      posClosestDrone.clear();

      // Loop through all the balls
      for (int i = balls.size () -1; i >= 0; i--) {
        // Get all enemy cannonballs
        if (balls.get(i).getClass() == CannonBall.class && balls.get(i).team != team) {
          float dist = balls.get(i).pos.dist(pos);
          // If the cannon ball hits this drone
          if (dist < DRONE_RADIUS) {
            // If we didnt survive the hit we should destroy the drone
            if (lifes <= 0) { 
              removeBall(id);

              // Replace the killed drone by a new teammate & make sure we dont spawn it too close to the terrain
              PVector spawnSpeed = new PVector(0, 0);
              PVector spawnPos;

              if (target.y >= height - 2*MAX_TERRAIN_HEIGHT)
                spawnPos = new PVector(random(target.x - 200, target.x + 200), random(target.y + 200));
              else
                spawnPos = new PVector(random(target.x - 200, target.x + 200), random(target.y - 200, target.y + 200));

              balls.add( new Drone(spawnPos, spawnSpeed, balls.size(), team) ); 

              // Create an explosion on the location we just died and spawn position
              explosion(pos, DRONE_RADIUS / 2, 1, 8, color(255, 0, 0));
              explosion(spawnPos, DRONE_RADIUS / 2, 1, 8, color(72, 72, 72));

              // Update scores
              if (team == 0) 
                teamScore[1]++;
              else
                teamScore[0]++;
              break;
            } 
            // If we survived the hit substract it from our lifepoints and create an explosion
            else {
              lifes--;
              explosion(pos, 8, 2, 4, color(255, 0, 0));
            }
          } 
          // If we didnt get hit we should try to dodge bullets
          else if (dist <= DRONE_RADIUS * 2) { 
            steer = PVector.sub(balls.get(i).pos, pos);
            steer.mult(-1.0);
            break;
          }
        } 
        // If the ball we found is not a cannonball we should search for other drones
        else if (balls.get(i).getClass() == Drone.class) { 
          // If the distance between two different drones is getting two small we should steer away
          if (balls.get(i).id != id && balls.get(i).pos.dist(pos) <= DRONE_RADIUS * 1.5) {
            steer = PVector.sub(balls.get(i).pos, pos);
            steer.mult(-1.0);
            break;
          } 
          // If the other drone is not part of our team we add it to our enemy list
          else if (balls.get(i).team != team) { 
            float[] temp = new float[3];
            temp[0] = pos.dist(balls.get(i).pos);
            temp[1] = balls.get(i).pos.x;
            temp[2] = balls.get(i).pos.y;
            posClosestDrone.add(temp);
          }
        }
      }
      // When no drone is too close 
      if (steer.x == 0 && steer.y ==0) { 
        float smallestDist = -1;
        int indexClosest = -1;

        // We search for the drone which is closest
        for (int i=0; i < posClosestDrone.size (); i++) { 
          if (posClosestDrone.get(i)[0] != 0 && (posClosestDrone.get(i)[0] < smallestDist || smallestDist == -1)) { 
            smallestDist = posClosestDrone.get(i)[0];
            indexClosest = i;
          }
        }

        // If we found a target 
        if (indexClosest != -1) {
          PVector posDrone = new PVector(posClosestDrone.get(indexClosest)[1], posClosestDrone.get(indexClosest)[2]);

          if ( framesBetweenShots > FRAMES_BETWEEN_SHOTS ) {
            framesBetweenShots = 0;                            // Reset tick counter
            PVector cannonSpeed = PVector.sub(posDrone, pos);  // Let the bullet go in direction of other drone
            cannonSpeed.limit(8);                              // Max speed of an bullet
            cannonSpeed.add(speed);                            // Add the drone speed to the bullet

            // Compensate direction of shot for gravity pulling cannonball down 
            if (cannonSpeed.heading() < HALF_PI &&  cannonSpeed.heading() > 0) 
              cannonSpeed.rotate(-cannonSpeed.heading() * 0.15);  

            // Create the cannonBall  
            balls.add(new CannonBall(new PVector(pos.x, pos.y), cannonSpeed, balls.size(), myColor, team));
          }

          // If the drone too far away we steer towards it
          if (posDrone.dist(pos) >= DRONE_RADIUS * 9) 
            steer = PVector.sub(posDrone, pos);
        }
      }

      // Do not let the drone escape the screen on the left and right side
      if (pos.x < 0)
        pos.x = 0;
      else if (pos.x > width)
        pos.x = width;

      PVector heightSteer =  new PVector(0, (height - MAX_TERRAIN_HEIGHT + terrainHeight[(int)pos.x] - RADIUS) - pos.y );

      // If minimum braking distance is larger than the distance or when flying toward the ground we need to stop, and go inreverse
      if (steer.mag() <= pow(speed.mag(), 2) || heightSteer.mag() <= pow(speed.mag(), 2)) { 
        steer = PVector.mult(speed, -1.0);
        steer.add(PVector.mult(gravity, -(sizeBall / 10) * 0.2 + 0.8)); // add trust against gravitational force
      } 
      // Else no corrections are needed, and we pull the drone a bit towards the skycastle
      else { 
        PVector toTarget = PVector.sub(target, pos); 
        toTarget.mult(0.1);                          
        steer.add(toTarget);
      }

      // Limit the acceleration
      steer.limit(0.5);
      speed.add(steer);
    }
    super.move();
  }

  void drawBall() {
    pushMatrix();

    // Go to drone location
    translate(pos.x, pos.y);

    // Rotate drones, towards  what they are heading
    PVector tempSpeed  = new PVector(speed.x, speed.y);
    tempSpeed.normalize();

    // Two different draw modes for rotating drones, when automatic flying enabled 
    if (flyDrones) { 
      tempSpeed.div(2);
      heading.add(tempSpeed);
      //stabalize drones ensure that drones are not draw upside down 
      heading.add(normalizeHeading); 
      rotate(heading.heading());
    } 
    // When automatic flying disabled 
    else { 
      heading.add(tempSpeed);
      rotate(heading.heading());
    }

    // Display drone
    imageMode(CENTER);
    image(droneImg, 0, 0); 
    imageMode(CORNER);

    // Draw the normal of the bal, vector of the direction and speed of the ball
    if (DISPLAY_BALL_NORMAL) { 
      strokeWeight(1);
      stroke(color(0, 255, 255)); 
      line(0, 0, speed.x * 10, speed.y * 10);
    }

    popMatrix();
  }
}
