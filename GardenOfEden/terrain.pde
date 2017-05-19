/*** Constants ***/
final int MAX_TERRAIN_HEIGHT = 150; // Max height of the terrain
final int GRASS_HEIGHT = 4;         // Height of the grass on the terrain
final int SCREEN_OFFSET = 5;        // Offset that the terrain is bigger than the screen
final int MAX_DARK_SPOTS = 500;     // amount of spots of darker dirt in the terrain
final int NORMAL_LENGTH = 35;       // Length of a normal

final float NOISE_STEP_SIZE = .01f;   // Step Size of the terrain and background generator
final float WIND_BLOCK_SIZE = 40f;    // Size of each wind area
final float SEASON_TIME = 4.3f;       // Time each season takes in 'in-game' time

final color DIRT_COLOR = color(120, 72, 0);      // Color of the terrain
final color DARK_DIRT_COLOR = color(89, 54, 12); // Color of the dirt spots

// Colors of the grass in each season
final color GRASS_COLOR[] = { 
  color(0, 123, 12),     // Summer
  color(0, 92, 9),       // Autumn
  color(230, 232, 227),  // Winter
  color(1, 166, 17)      // Spring
};

/*** Variables ***/
// Terrain variables
PGraphics darkEarth;       // Holds the spots of darker earth
PVector[] terrainNormals;  // Normals of the terrain, used for ball collision
PShape terrain;            // Shape of the terrain

float[] terrainHeight;   // Contains all the heights of the terrain for each pixel

// Draw Level Variables
int season = 1;            // Current season we are in, start off in summer
int prefSeason = season;   // We start off without a season change
int changeTicks;           // Ticks the terrain has changed into new season 

float seasonChangePercentage;  // Value 0-1 how far the terrain is into a transition       
float prevSeasonTime = 0;      // Pervious time a season was changed

boolean seasonChanging;    // Whether we are in a season change

void drawTerrain() { 
  // If display normals setting is true we should display them 
  if (DISPLAY_NORMALS) {
    pushMatrix();
    translate(0, height - MAX_TERRAIN_HEIGHT); 
    // Loop through all terrain points and draw their normals
    for (int i = 1; i < width; i++) { 
      stroke( color(0, 255, 255) ); 
      strokeWeight(1);
      line(i - SCREEN_OFFSET/2, terrainHeight[i], i - terrainNormals[i].x - SCREEN_OFFSET/2, terrainHeight[i] - terrainNormals[i].y);
    }
    popMatrix();
  }

  // If display windfield setting is on we should display it
  if (DISPLAY_WINDFIELD) 
    drawWindField(); 

  // Change season of terrain if season has just changed
  if (!seasonChanging && season != prefSeason) { 
    changeTicks = 600; 
    seasonChangePercentage= 1f / (float)changeTicks;
    seasonChanging = true;
  }

  if (seasonChanging) { 
    // If we are in a season transition and we have ticks left we lerp from old grass color to new one, else we are not changing seasons
    if (--changeTicks > 0) {
      color c = lerpColor(GRASS_COLOR[season - 1], GRASS_COLOR[prefSeason - 1], seasonChangePercentage * changeTicks); 
      terrain.setStroke(c);
    } else {
      seasonChanging = false;
      prefSeason = season;
    }
  }

  // Draw Terrain and the dark spots
  shape(terrain, - SCREEN_OFFSET / 2, height - MAX_TERRAIN_HEIGHT);
  image(darkEarth, 0, height - MAX_TERRAIN_HEIGHT); 

  // Check if a season has passed
  if (myTime - prevSeasonTime > SEASON_TIME) {
    // We can only go into transition during mid day
    if (brightnessBackground > 200) {
      season++;
      season = (season > 4)? 1 : season;
      prevSeasonTime = myTime;
    }
  }
}

void terrainConstruct() {
  terrainHeight = new float[width + 1 + SCREEN_OFFSET];
  terrainNormals = new PVector[width + SCREEN_OFFSET];

  terrain = createShape(); 
  terrain.beginShape(); 
  terrain.stroke(GRASS_COLOR[0]); 
  terrain.fill(DIRT_COLOR);
  terrain.strokeWeight(GRASS_HEIGHT); 
  terrain.vertex(0, height + SCREEN_OFFSET);
  // For each pixel we create a terrain height
  for (int i = 0; i <= width + SCREEN_OFFSET; i++) {
    terrainHeight[i] =  noise(i * NOISE_STEP_SIZE) * MAX_TERRAIN_HEIGHT;
    terrain.vertex(i, terrainHeight[i]);
  }
  terrain.vertex(width + SCREEN_OFFSET, height + SCREEN_OFFSET);
  terrain.endShape(CLOSE); 

  //Generate normals for each point
  for (int i = 1; i <= width + SCREEN_OFFSET; i++) {
    PVector normal = new PVector(1, terrainHeight[i] - terrainHeight[i -1]);
    normal.normalize();         // only direction is important
    normal.mult(NORMAL_LENGTH); // make normal certain lenght
    normal.rotate(HALF_PI);
    terrainNormals[i - 1] = normal;
  }

  // Generate dark dirt spots
  generateDirtSpots();
}

void generateDirtSpots() {
  darkEarth = createGraphics(width, MAX_TERRAIN_HEIGHT); 
  darkEarth.beginDraw();
  // Give each spot a  random x position, random y position(the lower the more chance) and size(the lower the more chance)
  for (int i = 0; i < MAX_DARK_SPOTS; i++) {
    int xPos = round( random(GRASS_HEIGHT * 2, width -  GRASS_HEIGHT * 2) ); 
    float dirtHeight = (MAX_TERRAIN_HEIGHT - terrainHeight[xPos] - GRASS_HEIGHT * 2f);
    int yPos = round( MAX_TERRAIN_HEIGHT - abs( randomGaussian() *(dirtHeight/4) ) ); 
    float sizeSpots = abs( (MAX_TERRAIN_HEIGHT - (float)yPos - dirtHeight)/(dirtHeight) ) * randomGaussian() * 5f; 

    darkEarth.noStroke();
    darkEarth.fill(DARK_DIRT_COLOR);
    // Add generated spot
    darkEarth.ellipse(xPos, yPos, sizeSpots, sizeSpots);
  }
  darkEarth.endDraw();
}

PVector getWind(PVector pos) {
  float angle;
  // If we are not in the screen we dont have wind, else return the wind for the position
  if (pos.x > width || pos.x < 0 || pos.y < 0) 
    angle = 0f;
  else 
    angle = map( noise((pos.x / WIND_BLOCK_SIZE) - myTime * 5, (pos.y / WIND_BLOCK_SIZE) ), 0, 1, 0, TWO_PI) + PI;
  
  // Return the wind direction from the requested point
  return new PVector(cos(angle), sin(angle));
}

void drawWindField() {
  pushStyle();
  // For each point in the grid we draw a wind standard
  for (int i = 0; i < width / WIND_BLOCK_SIZE; i++) {
    for (int j = 0; j < height / WIND_BLOCK_SIZE; j++) {
      stroke(color(0, 255, 255)); 
      strokeWeight(1);
      float x = i * WIND_BLOCK_SIZE + WIND_BLOCK_SIZE / 2;
      float y = j * WIND_BLOCK_SIZE + WIND_BLOCK_SIZE / 2;
      line(x, y, x + getWind(new PVector(x, y)).x * 10, y + getWind(new PVector(x, y)).y * 10);
      ellipse(x, y, 2, 2);
    }
  }
  popStyle();
}
