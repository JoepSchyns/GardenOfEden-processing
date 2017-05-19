/*** Constants ***/
final int CANNONBALL_RADIUS = 7;   // Radius of a cannon ball

/********** class CannonBall ****************
 Creates Cannonballs that:
 - extends a normal ball
 - destroy drones from another team 
 - destroy cannoballs from another team
********************************************/
class CannonBall extends Ball {
  int lifeTime = 35;

  CannonBall(PVector pos_, PVector speed_, int id_, color myColor_, int team_) {
    super(pos_, speed_, id_, CANNONBALL_RADIUS);
    myColor = myColor_;
    team = team_;
  }

  void drawBall() {
    super.drawBall();
    // Loop through all balls
    for (int i = balls.size () -1; i >= 0; i--) {
      // See if ball i is a cannonball from another team and if they hit each other
      if (balls.get(i).getClass() == CannonBall.class && balls.get(i).team != team && balls.get(i).pos.dist(pos) < CANNONBALL_RADIUS) { 
        removeBall(id); 
        explosion(pos, 8, 2, 4, color(255, 0, 0)); 
        break; 
      }
    }
    
    // Decrease lifetime
    lifeTime--;
    // If particle is dead remove it
    if (lifeTime <= 0) 
      removeBall(id);	
  }
}
