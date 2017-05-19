// Creates an explosion particles that go in all directions and can bounce
void explosion(PVector pos_, int sizeExBall_, int speed_, float particles_, color exColor_) {
  float rotPerExploBall = TWO_PI / particles_;
  for (int q = 0; q < particles_; q++) {
    PVector exSpeed = new PVector(speed_, 0);
    exSpeed.rotate(rotPerExploBall * q);
    balls.add(new TrustBall(new PVector(pos_.x, pos_.y), exSpeed, balls.size(), 60, exColor_, sizeExBall_));
  }
}

/******* class DeadLeaves *************
 Creates falling leaevs that have:
 - moves towards the ground
 - moves in the wind
 - random life time
 *********************************/
class DeadLeaves {
  int lifeTime;      // Time the particle has to live

  color c;           // Color of this particle

  PVector position;  // Position of the particle 
  PVector velocity;  // Velocity of the particle

  DeadLeaves(PVector pos_) {
    position = pos_;
    velocity = new PVector(0, 0);
    lifeTime = (int)random(80, 120);
    c = lerpColor(TREE_AUTUMN_COLOR1, TREE_AUTUMN_COLOR2, random(1));
  }

  void display() {
    move();
    drawLeaf();
    lifeTime--;
  }

  void move() {
    velocity.sub(LEAF_GRAVITY);
    PVector wind = getWind(position);
    wind.mult(.1f);
    velocity.add(wind);
    velocity.limit(1f);
    position.add(velocity);
  }
  
  void drawLeaf(){
    noStroke();
    fill(c);
    ellipse(position.x - 2.5f, position.y - 1f, 5f, 3f); 
  }
}
