/*** Constants ***/
final float BOOST = 0.3f;    // Speed a booster boosts

/*** Variables ***/
int[] controls = {87, 65, 83, 68}; // Keys used to control the ball, by default WASD

/**** class BallWithTrusters **************************
 Creates balls that extends a normall ball that can:
 - be controled with keys
 - has a truster which generates a force
 - genetates particles 
 *******************************************************/
class BallWithTrusters extends Ball {
  int[] controls;  // setting for key controls
  int id;          // ID of this ball

  boolean[] boostDirection = new boolean[4];  // Whether a direction key is pressed

  BallWithTrusters(PVector pos_, PVector speed_, int id_, int[] controls_) {
    super(pos_, speed_, id_, 15);
    controls = controls_;
  }

  void trusters() {
    PVector trust = new PVector(0, 0);   // Acceleration
    float heading = speed.heading();     // Angle direction
    
    // If forward key is pressed go forward
    if (checkKey(controls[0])) { 
      trust.x += BOOST;
      trust.rotate(heading);
    }
    // If back key is pressed go backward
    if (checkKey(controls[2])) {
      trust.x += BOOST;
      trust.rotate(heading + PI);
    }
    // If left key is pressed go left
    if (checkKey(controls[1])) {
      trust.x += BOOST;
      trust.rotate(heading - HALF_PI);
    }
    // If right key is pressed go right
    if (checkKey(controls[3])) {
      trust.x += BOOST;
      trust.rotate(heading + HALF_PI);
    }

    speed.add(trust);  // Increase speed with acceleration

   // Generate particle balls in opposite direction
    if (moving && trust.mag() >= BOOST) {
      trust.mult(-10.0); 
      trust.add(speed);

      PVector newPos = new PVector(pos.x, pos.y); 
      balls.add(new TrustBall(newPos, trust, balls.size(), 150, color(random(188, 255), random(0, 171), 0), 7)); 
    }
  }

  void move() {
    trusters();
    super.move();
  }
}
