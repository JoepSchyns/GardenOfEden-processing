/******* class TrustBall *************
 Creates trustBalls that:
 - extends a normal ball
 - act as particles
 - Die over time
 - Can bounce
 *********************************/
class TrustBall extends Ball {
  int lifeTime;        // Time the particle has left to live
  int initialLifeTime; // Life time the particle started out with

  TrustBall(PVector pos_, PVector speed_, int id_, int lifeTime_, color myColor_, int sizeBall_) {
    super(pos_, speed_, id_, sizeBall_);
    speed.rotate(random(-0.2, 0.2));
    myColor = myColor_;
    lifeTime = lifeTime_;
    initialLifeTime = lifeTime_;
  }

  void drawBall() {
    super.drawBall();
    
    // Decrease life time
    lifeTime--;
    
    // Make color dissapear over the lifetime
    myColor = color(red(myColor) + initialLifeTime / 2 - lifeTime / 2, green(myColor) + initialLifeTime / 2 - lifeTime / 2, blue(myColor) + initialLifeTime / 2 - lifeTime / 2, lifeTime);
   
    // Remove the ball when it is dead
    if (lifeTime <= 0) 
      removeBall(id);	
  }
}
