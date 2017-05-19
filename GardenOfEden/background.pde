/*** Constants ***/
final float DAYTIME = 8000f;           // Amount of miliseconds in a day
final float MAX_STAR_DIAMETER = 2f;    // Max diameter of a star
final float FSTAR_SPEED_VARIANCE = 2f; // Variance a falling stars can have in speed

final int SUN_SIZE = 40;                         // Size of the sun & moon         
final int MAX_BACKGROUND_TERRAIN_HEIGHT = 100;   // Maximum height for backgroundLevel
final int STARS_AMOUNT = 1000;                   // Amount of stars
final int FSTAR_CHANCE = 100;                    // Chance of a falling star 1 out of FSTAR_CHANCE

final color SUN_COLOR = color(255, 230, 0);      // Color of the sun
final color MOON_COLOR = color(224, 224, 224);   // Color of the moon

/*** Variables ***/
int SUN_HEIGHT;
PVector posSun = new PVector();   // Position of the sun

float myTime;                     // Current time
float randomStartTime;            // Give each world a random start time when generated

float brightnessBackground;       // Brightness of background - day night cycle - 
color backgroundColor;            // Color of the sky

float[] heightBackground;         // Height of background terran
PShape backgroundTerrain;         // Background terrain
PGraphics stars;                  // Stars in the night sky

PVector posFallingStar;           // Position of a falling star
PVector speedFallingStar;         // Speed of a falling star
float lengthFallingStar;          // Length of the falling stars tail
boolean fallingStar = false;      // Whether a falling star is present

LampPost[] lampPosts = new LampPost[3];  // The lamp posts in the background
Tree[] tree = new Tree[2];               // The trees in the background


void drawBackground() {
  myTime = millis() / DAYTIME; 

  // Display sky - Normal color is (0.175.255) when the sun goes down color(191.127.0) is added
  backgroundColor = color(191 * abs(cos(myTime)) * (1 - abs(sin(myTime))), -175 * sin(myTime) + 127 * abs(cos(myTime))* (1 - abs(sin(myTime))), -255 * sin(myTime)); 
  brightnessBackground = brightness(backgroundColor); 
  background(backgroundColor); 

  // Display Sun
  drawSun();

  // Color of stars color fades away when the background gets bright and when the sun goes down
  tint(255-brightnessBackground, 255-brightnessBackground, 255-brightnessBackground, 255-brightnessBackground - 127 * abs(cos(myTime))* (1 - abs(sin(myTime)))); 
  // Display stars
  image(stars, 0, 0); 
  noTint();

  // Display falling stars if we have some
  fallingStars();

  // Display background terrain - color(10.143.209) this color gets darker when the sun goes under
  backgroundTerrain.setFill(color(-10 * sin(myTime) + 127 * abs(cos(myTime))* (1 - abs(sin(myTime))), -143 * sin(myTime) + 127 * abs(cos(myTime))* (1 - abs(sin(myTime))), -209 * sin(myTime) + 127 * abs(cos(myTime))* (1 - abs(sin(myTime))))); 
  shape(backgroundTerrain, 0, height - MAX_BACKGROUND_TERRAIN_HEIGHT - MAX_BACKGROUND_TERRAIN_HEIGHT); 

  // Display clouds
  drawClouds();

  // Display Trees
  for (Tree t : tree)
    t.display();

  // Display Lampposts
  for (LampPost l : lampPosts) {
    l.drawLampPost();
  }
}


void fallingStars() {
  // If we do not have a falling star and we are lucky enough to spawn one we create one
  if (!fallingStar  && (int)random(FSTAR_CHANCE) == 1) {
    fallingStar = true;
    speedFallingStar = new PVector(random(5f, 5f*FSTAR_SPEED_VARIANCE) * random(-1, 1), random(5f, 5f*FSTAR_SPEED_VARIANCE));
    lengthFallingStar = (speedFallingStar.x + speedFallingStar.y) * 10;
    posFallingStar= new PVector(random(width), -lengthFallingStar);
  }
  // If we already have a falling star we display it
  if (fallingStar) {
    posFallingStar.add(speedFallingStar);

    // Display the falling star, we cannot use line because of the OPENGL render
    pushMatrix();
    translate(posFallingStar.x + lengthFallingStar/2, posFallingStar.y);
    rotate(speedFallingStar.heading() );
    noStroke();
    fill(150-brightnessBackground, 150-brightnessBackground, 150-brightnessBackground, 150-brightnessBackground - 127 * abs(cos(myTime))* (1 - abs(sin(myTime))));
    rect(0, 0, lengthFallingStar, 1);
    popMatrix();

    // If it has escaped the screen we need to let it go
    if (posFallingStar.x > width || posFallingStar.x < 0 || posFallingStar.y > height) 
      fallingStar = false;
  }
}


void drawSun() {
  pushMatrix();

  translate(width /2, height); //set middle of rotation to middle bottom screen
  
  // Calculate sun position
  posSun.x = ((width - SUN_SIZE) / 2) *cos(myTime); 
  posSun.y =(SUN_HEIGHT - SUN_SIZE) * sin(myTime); 
  
  // Display sun
  noStroke();
  fill(SUN_COLOR); 
  ellipse(posSun.x, posSun.y, SUN_SIZE, SUN_SIZE); 
  
  // Display moon
  fill(MOON_COLOR); 
  ellipse(-posSun.x, -posSun.y, SUN_SIZE, SUN_SIZE);
  
  // Cut a hole in the moon for the moon cycle
  fill(backgroundColor); 
  float moonHoleLead = 0.01 + 0.04*sin(myTime / 30.0);
  ellipse(-((width - SUN_SIZE) / 2) *cos(myTime + moonHoleLead), -(SUN_HEIGHT - SUN_SIZE) * sin(myTime + moonHoleLead), SUN_SIZE, SUN_SIZE);

  popMatrix();
}

void backgroundConstruct() {
  SUN_HEIGHT = round(0.3 * width);               // Set the maximum height of the sun
  randomStartTime = random(width, width + 1000); // Generate a time seed for creation background

  // Generate background terrain
  backgroundTerrain = createShape();
  backgroundTerrain.beginShape(); 
  backgroundTerrain.noStroke();
  backgroundTerrain.vertex(0, height);
  // For each pixel we generate a height
  for (int i = 0; i <= width; i++) { 
    backgroundTerrain.vertex(i, noise(i * NOISE_STEP_SIZE + randomStartTime) * MAX_BACKGROUND_TERRAIN_HEIGHT); 
  }
  backgroundTerrain.vertex(width, height);
  backgroundTerrain.endShape(CLOSE); 
   
  // Generate Stars
  constructStars();
  
  // Generate Clouds
  contructClouds();
  
  // Create Lamp posts at random x locations
  for (int i = 0; i < lampPosts.length; i++) {
    lampPosts[i] = new LampPost((int)random(width));
  }
  
  // Create Trees at random x locations
  for (int i=0; i<tree.length; i++)
    tree[i] = new Tree((int)random(width));
}

void constructStars() {
  stars = createGraphics(width, height); 
  stars.beginDraw();
  stars.fill(255); 
  stars.noStroke();
  // Draw all stars at random postions with random diameters
  for (int i = 0; i < STARS_AMOUNT; i++) { 
    float diameter = random(MAX_STAR_DIAMETER); 
    stars.ellipse(random(width), random(height), diameter, diameter); 
  }
  stars.endDraw();
}
