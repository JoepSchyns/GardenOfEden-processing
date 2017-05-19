/*** Constants ***/
final float BALL_DRAG = .0125f;    // Drag coefficient of a ball
final float WORLD_GRAVITY = 0.14f; // Pull force the world has on a ball
final float GRAVITY_SUN = .24f;    // Pull force the sun has on a ball
final float GRAVITY_MOON = .049f;  // Pull force the moon has on a ball
final float DAMPING_FACTOR = 0.9f; // Damping factor of a ball

void removeBall(int id) {
  // Update all balls IDs
  for (int i =balls.size () - 1; i > id; i--) {
    balls.get(i).subtractId();
  }
  // Remove ball that was parsed in
  balls.remove(id);
}

/******* class Ball *************
 Creates balls that:
 - moves
 - gets affected by different gravities
 - gets affected by wind
 - gets affected by drag
 - can collide with the terrain
 *********************************/
class Ball {
  int id;            // Identification number of this ball
  int team = -1;     // By default it is not in a team
  int sizeBall = 10; // Default size is 10

  boolean moving = true;      // Whether the ball is moving

  color myColor;              // Color the ball

  PVector gravity = new PVector(0, WORLD_GRAVITY);  // Force that pulls the ball down
  PVector pos;                                      // Current position of the ball
  PVector prevPos;                                  // Previous position the ball was at
  PVector speed;                                    // Speed of the ball

  Ball(PVector pos_, PVector speed_, int id_) {
    id = id_;
    pos = pos_;
    speed = speed_; 
    myColor = color(random(150), random(150), random(150));
    // Calculate gravitational force of this ball - size dependent
    gravity.mult((sizeBall / 10) * 0.2 + 0.8);
  }

  Ball(PVector pos_, PVector speed_, int id_, int sizeBall_) {
    sizeBall = sizeBall_;
    id = id_;
    pos = pos_;
    speed = speed_; 
    myColor = color(random(150), random(150), random(150));
    // Calculate gravitational force of this ball - size dependent
    gravity.mult((sizeBall / 10) * 0.2 + 0.8);
  }


  void move() {
    // If we are not moving check if the ball has started to move again
    if (!moving && speed.mag() > 0.3) 
      moving = true;

    // If the ball is moving we need to calclute things, else we only need to check if it has started to move
    if (moving) { 
      // If moon and sun gravity setting is turned on we need to calculate its gravity
      if (GRAVITY_SUN_AND_MOON) {
        PVector realPosSun = new PVector(posSun.x + width /2, posSun.y + height); 
        PVector realPosMoon = new PVector(-posSun.x + width /2, -posSun.y + height);

        float distanceToSun = PVector.dist(pos, realPosSun); 
        float distanceToMoon = PVector.dist(pos, realPosMoon); 

        // If we are in range of the sun or the moon we need to calculate its force on the ball
        if (distanceToSun < SUN_SIZE * 2) { 
          PVector gravitySun = new PVector(((realPosSun.x - pos.x) / distanceToSun) * GRAVITY_SUN, ((realPosSun.y - pos.y) / distanceToSun) * GRAVITY_SUN); 
          speed.add(gravitySun);
        } else if (distanceToMoon < SUN_SIZE * 2) {
          PVector gravityMoon = new PVector(((realPosMoon.x - pos.x) / distanceToMoon) * GRAVITY_SUN, ((realPosMoon.y - pos.y) / distanceToMoon) * GRAVITY_MOON); 
          speed.add(gravityMoon);
        }
      }

      // Apply earths gravity to the ball
      speed.add(gravity); 

      // Apply drag, depens on speed and size
      PVector drag = PVector.mult(speed, BALL_DRAG * sizeBall); 
      drag.mult(BALL_DRAG); 
      speed.sub(drag); 

      // Apply wind
      PVector wind = getWind(pos); 
      wind.mult(0.003 * sizeBall);
      speed.add(wind); 

      // Update position and store old one
      prevPos = new PVector(pos.x, pos.y); 
      pos.add(speed);

      //check for collisions
      collision();
    }

    // Display the ball
    drawBall();
  }

  void drawBall() {
    // Display ball
    noStroke();
    fill(myColor); 
    ellipse(pos.x, pos.y, sizeBall, sizeBall);

    // If display ball normal setting is turned on we should display the balls direction
    if (DISPLAY_BALL_NORMAL) {
      strokeWeight(1);
      stroke(color(0, 255, 255));
      line(pos.x, pos.y, pos.x + speed.x * 10, pos.y + speed.y * 10);
    }
  }

  void collision() {
    // If the ball touching left edge
    if (pos.x <= 1) { 
      speed.rotate( PI - 2 * (speed.heading() - PI) ); // Rotate the direction of movement according to the normal and the previous direction of movement
      pos.x += 0.4;                                    // Set ball away from touching point
      speed.mult(DAMPING_FACTOR);                      // Damping factor
    } 
    // Else if it is touching right edge
    else if (pos.x >= width - 1) { 
      speed.rotate( PI - 2 * (speed.heading() + PI) ); // Rotate the direction of movement according to the normal and the previous direction of movement
      pos.x -= 0.4;                                    // Set ball away from touching point
      speed.mult(DAMPING_FACTOR);                      // Damping factor
    } 
    // Else if it is hitting the terrain
    else if (height - MAX_TERRAIN_HEIGHT + terrainHeight[round(pos.x)] < round(pos.y) + sizeBall / 2) { 
      // If the speed is almost 0 stop the endless bouncing
      if (speed.mag() < 0.3f) { 
        moving = false;                 // We are not moving any more
        speed.rotate(-speed.heading()); // Set direction of ball to top
      } else {
        // Rotate the direction of movement according to the normal and the previous direction of movement
        speed.rotate(PI - 2* (speed.heading() - terrainNormals[round(pos.x) + SCREEN_OFFSET / 2].heading()));
        pos.y-= 0.4;                   // Set above touching point to prevent continuous touches
        speed.mult(DAMPING_FACTOR);    // Damping factor
      }
    }
  }

  void subtractId() { 
    id--;
  }
}
