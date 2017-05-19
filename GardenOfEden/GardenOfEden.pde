/**********************************************************************************************
*
*              Title - Garden of Eden         Date - June 24, 2014.
*
*  This program has:
*     - A random level generator ( terrain(gaussian & noise), trees(random), clouds(random), stars(random), falling stars(random), wind(noise) & lampposts(random) )
*     - Time simulation (day/night cycle, season cycle, moon cycle)
*     - Bouncing ball simulation
*     - Fighting drones (see Drone class for more information)
*
*  Made by:   Joep Schyns   -  http://www.eyediction.com
*             Sven Santema  -  http://ewi1473.ewi.utwente.nl/~s1454064/
*           
*  Made in:  Processing v2.2.1
* 
*  Instructions:
*     - Add a normal bouncing ball by clicking with left mouse button and then drag your mouse
*     - Position the sky castle with right mouse button
*     - Press enter to turn the drones off
*     - Use WASD keys to control the trusters of the ball with trusters
* 
*************************************************************************************************/

/*** Settings ***/
final boolean DISPLAY_NORMALS = false;       // Display normals of the landscape on the screen
final boolean DISPLAY_WINDFIELD = false;      // Display the directions of the wind
final boolean DISPLAY_BALL_NORMAL = false;   // Display the normal of bals, vectors of the directions and speeds of the balls
final boolean GRAVITY_SUN_AND_MOON = true;   // Moon and sun have gravitational forces on balls
final int AMOUNT_BALLS_WITH_THRUSTERS = 1;   // Number of controllable balls
final int START_AMOUNT_BALLS = 1;            // Number of balls at start

/*** Variables ***/
ArrayList<Ball> balls;  // List of all the balls includes: bouncing balls, ball with trusters, cannonBalls, drones, explosion particles

void setup() {
  // Sketch is the size of the screen
  size(displayWidth, displayHeight, OPENGL);
  
  balls = new ArrayList<Ball>();
  
  // Add the amount of balls that were defined at start 
  for (int i=0; i < START_AMOUNT_BALLS; i++) 
    balls.add( new Ball( new PVector(random(1, 50), random(1, 50)), new PVector(10, 0), balls.size()) );
  
  // Add the amount of balls with thrusters defined at start
  for (int i=0; i < AMOUNT_BALLS_WITH_THRUSTERS; i++)
    balls.add(new BallWithTrusters(new PVector(random(1, 50), random(1, 50)), new PVector(10, 0), balls.size(), controls) ); 
  
  // Create 2 drones spread across 2 teams
  balls.add(new Drone(new PVector(width / 2 + random(-50, 50), height / 2 + random(-50, 50)), new PVector(0, 0), balls.size(), 0));
  balls.add(new Drone(new PVector(width / 2 + random(-50, 50), height / 2 + random(-50, 50)), new PVector(0, 0), balls.size(), 1));
  balls.add(new Drone(new PVector(width / 2 + random(-50, 50), height / 2 + random(-50, 50)), new PVector(0, 0), balls.size(), 0));
  balls.add(new Drone(new PVector(width / 2 + random(-50, 50), height / 2 + random(-50, 50)), new PVector(0, 0), balls.size(), 1));
  
  // Load the sky castle
  cloudCastle = loadImage("cloudCastle.png");
  
  // Generate a terrain and background
  terrainConstruct();
  backgroundConstruct();
}

void draw() {
  drawBackground();
  drawDroneTarget();
  
  // Loop through all the balls we have
  for (int i = balls.size() -1; i >= 0; i--)  
    balls.get(i).move();
  
  drawTerrain();
  drawElastic();
  drawScores();

  // Print the framerate 
  println("FPS : " + frameRate);
}

//boolean sketchFullScreen() {
//  return true;
//}