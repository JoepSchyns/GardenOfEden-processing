/*** Tree constants ***/
final float MIN_BRANCH_THICKNESS = 2f; 
final float TREE_WIND_MODIFIER = 0.1f;

final color TREE_STUMP_COLOR = color(83, 53, 10);
final color TREE_BRANCH_COLOR = color(92, 51, 0);
final color TREE_LEAVE_COLOR1 = color(58, 95, 11);
final color TREE_LEAVE_COLOR2 = color(70, 110, 8);
final color TREE_AUTUMN_COLOR1 = color(247, 66, 12);
final color TREE_AUTUMN_COLOR2 = color(247, 172, 12);
final color TREE_BUD_COLOR = color(255);

final PVector LEAF_GRAVITY = new PVector(0, -0.25f);


/******* class Tree *************
 Creates trees that have:
 - random branch lengths
 - random rotations
 - Changes seasons
 - moves in the wind
 - holds an array of leaves
 - emits falling leaves in autumn
 *********************************/
class Tree {
  int cnt;                 // Keeps track on which branch in the loop we are
  int treeSeason;          // Stores the season the tree is in
  int transitionTicks;     // Amount of ticks that is needed for the tree to adjust its season
  int curTransitionTick;   // Current tick into a season change
  int deadleaveTick;       // Tick counter for the emission of falling leaves(deadleaves);

  float stumpThickness;                    // Thickness of stump  
  float branchLength[] = new float[31];    // Holds length of branches
  float branchAngles[] = new float[31];    // Holds angles between branches

  boolean firstTime;                       // When a tree is first displayed we need to store the global positions of the leaves

  PVector position;                        // Position stump is located
  PVector[] leaveNodes = new PVector[30];  // Global positions of leave locations - used for falling leaves
  Leaves leaves[] = new Leaves[30];        // Stores the leaves that are attached to the branches

  ArrayList<DeadLeaves> deadLeaves;        // Stores all the fallen leave particles

  Tree(int x_) {
    position = new PVector(x_, height - MAX_TERRAIN_HEIGHT + terrainHeight[x_ + (int)stumpThickness / 2] - (int)stumpThickness * 0.95 + 20);
    treeSeason = season;
    firstTime = true;

    stumpThickness = random(9, 13);
    branchLength[0] = random(52, 64);

    generateBranches(0);
    branchAngles[0]  = radians(random(-20, -10));  // Give first 2 branches different start rotation - This looks better visually
    branchAngles[1]  = radians(random(10, 30));    // Give first 2 branches different start rotation - This looks better visually

    transitionTicks = (int)(random(400, 800));
    curTransitionTick = transitionTicks;
    deadleaveTick = 0; 
    cnt = 0;

    deadLeaves = new ArrayList<DeadLeaves>();
    for (int i=0; i<leaves.length; i++) {
      leaves[i] = new Leaves(x_);
    }
  }

  void generateBranches(int level) {
    for (int i=0; i<2; i++) {
      cnt++;
      branchLength[cnt] =  random(32, 48) * pow(2.6 - stumpThickness/10, -level);

      if (i == 0)  // Change deviation direction for each side
        branchAngles[cnt] = radians(random(20, 40));
      else 
        branchAngles[cnt] = radians(random(-40, -20));

      if (level < 3)
        generateBranches(level+1);
    }
  }

  void display() {
    checkSeason();

    if (inTranstion())    // Increase transitions ticks 
      curTransitionTick++;

    if (inTranstion() && season == 3) { // If we are in transition between autumn and winter
      emitDeadLeaves();
    }

    // Display Tree
    pushMatrix();
    pushStyle();
    displayStump();
    displayBranch(0);
    popStyle();
    popMatrix();

    cnt = 0;

    // display dead leaves
    for (int i=deadLeaves.size (); i>0; i--) {
      if (deadLeaves.get(i-1).lifeTime > 0)
        deadLeaves.get(i-1).display();       
      else 
        deadLeaves.remove(i-1);
    }

    // if this was our first run next run wont be our first
    if (firstTime)
      firstTime = false;
  }

  void displayStump() {
    stroke(TREE_STUMP_COLOR);
    strokeWeight(stumpThickness);
    translate(position.x, position.y);
    noStroke();
    fill(TREE_STUMP_COLOR);
    rect(-stumpThickness/2, 0, stumpThickness, - branchLength[0]);
    fill(backgroundColor, 100 - brightnessBackground);
    rect(-stumpThickness/2, 0, stumpThickness, - branchLength[0]);
    translate(0, -branchLength[0]);
  }

  void displayBranch(int level) {
    for (int i=0; i<2; i++) {
      pushMatrix();
      cnt++;

      rotate(branchAngles[cnt]);
      rotate(getWind( new PVector(position.x, position.y + (WIND_BLOCK_SIZE * level))).x  * TREE_WIND_MODIFIER);    // Apply wind

      noStroke();
      fill(lerpColor(TREE_STUMP_COLOR, TREE_BRANCH_COLOR, 0.25 * level));
      float thickness = lerp(stumpThickness, MIN_BRANCH_THICKNESS, 0.25 * level);
      // draw branch with shadow on top of it
      rect(-thickness/2, 0, thickness, - branchLength[cnt]);
      fill(backgroundColor, 100 - brightnessBackground);
      rect(-thickness/2, 0, thickness, - branchLength[cnt]);
      // draw joint with shadow on top of it
      fill(lerpColor(TREE_STUMP_COLOR, TREE_BRANCH_COLOR, 0.25 * level));
      ellipse(0, 0, thickness, thickness);
      fill(backgroundColor, 100 - brightnessBackground);
      ellipse(0, 0, thickness, thickness);

      translate(0, - branchLength[cnt]);

      // If we are more than 1 level deep into the tree we start displaying leaves, if it is the first time we will store the global positions of the leaves aswell
      if (level > 1) { 
        leaves[cnt-1].display(transitionModifier(), inTranstion());
        if (firstTime)
          leaveNodes[cnt-1] = new PVector(modelX(leaves[cnt-1].sizeLeaf/2, leaves[cnt-1].sizeLeaf/2, 0), modelY(0, 0, 0));
      }

      // If we are not 3 levels deep into the tree we make more branches
      if (level < 3) {
        displayBranch(level + 1);
      } 
      popMatrix();
    }
  }

  void emitDeadLeaves() {
    deadleaveTick++;            // increase tick counter
    if (deadleaveTick > 10) {   // emit dead leaves every 10 ticks
      int r;
      PVector p;
      for (int i=0; i<7 - (int)(transitionModifier()*6); i++) { // make amount of emitting leaves this moment depend on how far we are in transition
        r = (int)random(30);
        if (leaveNodes[r] != null) {
          p = new PVector(leaveNodes[r].x, leaveNodes[r].y);
          deadLeaves.add(new DeadLeaves(p));
        }
      }
      deadleaveTick = 0;
    }
  }


  // if season change has occured and tree hasn't changed yet we enter transition period and season changes
  void checkSeason() {
    if (treeSeason != season) {
      curTransitionTick = 0;
      treeSeason = season;
    }
  }

  // returns value between 0-1 how far it is into a season transisition
  float transitionModifier() { 
    return (float)curTransitionTick / (float)transitionTicks;
  }

  // returns boolean value. true if the tree is in a transition, false if not
  boolean inTranstion() {  
    if (curTransitionTick < transitionTicks) 
      return true;
    else 
      return false;
  }
}

/******* class Leaves *************
 Creates leaves that have:
 - random offset 
 - random color
 - Size depending on location in the tree
 - Changes seasons
 *********************************/
class Leaves {
  int middleTree;       // stores middle position of the tree
  int sizeLeaf = 0;     // size of leaf

  color summerColor;    // Color of this leaf in summer 
  color autumnColor;    // Color of this leaf in autumn
  color springColor;    // Color of this leaf in spring
  color branchColor;    // Color of this branch (winter color)

  boolean firstTime;    // true if we are displayed for the first time  

  PVector positionOffset;   // Offset to branch    

  Leaves(int middleTree_) {
    summerColor = lerpColor(TREE_LEAVE_COLOR1, TREE_LEAVE_COLOR2, random(1));
    autumnColor = lerpColor(TREE_AUTUMN_COLOR1, TREE_AUTUMN_COLOR2, random(1));
    springColor = TREE_BUD_COLOR;
    branchColor = TREE_BRANCH_COLOR;

    positionOffset = new PVector(random(-8, 8), random(-8, 8));

    middleTree = middleTree_;
    firstTime = true;
  }

  void display(float p_, boolean transition_) { 
    // if we are run for the first time we need to generate the leave sizes
    if (firstTime) {
      generateLeaveSizes();
      firstTime = false;
    }

    noStroke();

    // Make the leaves display depending on season and whether we are in a transition
    switch(season) {
    case 1: 
      if (transition_)
        transitionSpringSummer(p_);
      else
        leaves(summerColor);
      break;
    case 2: 
      if (transition_)
        transitionSummerAutumn(p_);
      else
        leaves(autumnColor);
      break;
    case 3: 
      if (transition_)
        transitionAutumnWinter(p_);
      break;
    case 4: 
      if (transition_)
        transitionWinterSpring(p_);
      else
        springLeaves();
      break;
    }
  }

  void leaves(color c_) {
    // Display Leaves
    fill(c_);
    ellipse(positionOffset.x, positionOffset.y, sizeLeaf, sizeLeaf);
    // Display shadows
    fill(backgroundColor, 100 - brightnessBackground);
    ellipse(positionOffset.x, positionOffset.y, sizeLeaf, sizeLeaf);
  }

  void springLeaves() {
    // Display Leaves
    fill(springColor);
    ellipse(positionOffset.x, positionOffset.y, sizeLeaf * 0.15f, sizeLeaf * 0.15f);
    // Display shadows
    fill(backgroundColor, 100 - brightnessBackground);
    ellipse(positionOffset.x, positionOffset.y, sizeLeaf * 0.15f, sizeLeaf * 0.15f);
  }

  void transitionSummerAutumn(float p_) {
    // Color transition from summerColor to autumnColor
    color c = lerpColor(summerColor, autumnColor, p_);
    // Display Leaves
    fill(c);
    ellipse(positionOffset.x, positionOffset.y, sizeLeaf, sizeLeaf);
    // Display Shadows
    fill(backgroundColor, 100 - brightnessBackground);
    ellipse(positionOffset.x, positionOffset.y, sizeLeaf, sizeLeaf);
  }

  void transitionWinterSpring(float p_) {
    // color transition and buds grow from 0% to 15% of normal size
    color c = lerpColor(branchColor, springColor, p_);
    float modifier = lerp(0f, .15f, p_);
    // Display Leaves
    fill(c);
    ellipse(positionOffset.x, positionOffset.y, sizeLeaf * modifier, sizeLeaf * modifier); 
    // Display Shadows
    fill(backgroundColor, 100 - brightnessBackground);
    ellipse(positionOffset.x, positionOffset.y, sizeLeaf * modifier, sizeLeaf * modifier);
  }

  void  transitionSpringSummer(float p_) {
    // color transitionf from spring whiteish to summer color and size grows from 15% to 100%
    color c = lerpColor(color(164, 180, 96), summerColor, p_);
    float modifier = lerp(0.15f, 1f, p_);
    // Display Leaves    
    fill(c);
    ellipse(positionOffset.x, positionOffset.y, sizeLeaf * modifier, sizeLeaf * modifier);
    // Display Shadows
    fill(backgroundColor, 100 - brightnessBackground);
    ellipse(positionOffset.x, positionOffset.y, sizeLeaf * modifier, sizeLeaf * modifier);
  }

  void transitionAutumnWinter(float p_) {
    // Makes leaves shrink from 100% to 15%
    p_ = p_-1;
    // Display Leaves
    fill(autumnColor);
    ellipse(positionOffset.x, positionOffset.y, sizeLeaf * p_, sizeLeaf * p_);
    // Display Shadows
    fill(backgroundColor, 100 - brightnessBackground);
    ellipse(positionOffset.x, positionOffset.y, sizeLeaf * p_, sizeLeaf * p_);
  }

  void generateLeaveSizes() {
    // Size of a leaf depens on how far it is from center on x axis
    sizeLeaf =(int)(85 - abs((int)(middleTree -  modelX(positionOffset.x, positionOffset.y, 0))) / 1.2);
    // However we set a minumum size of 30
    if (sizeLeaf < 30) 
      sizeLeaf = 30;
  }
}
