/******* class LampPost *************
 Creates lamp posts that:
 - go on when it is dark with a random threshold
 - when they go on they have to warm up first
 *********************************/
class LampPost {
  int onThreshold;  // Threshold of darkness before the lamp goes on
  int warmingUp;    // Warmth of the lamp when it is turned on

  PImage lampPost;  // Image of the lamppost
  PVector pos;      // Position of the lamppost base
  PShape lightBeam; // Shape of the light beam

  LampPost(int x_) {
    lampPost = loadImage("lamppost.png");

    pos = new PVector(x_, height - MAX_TERRAIN_HEIGHT + terrainHeight[x_ + lampPost.width / 2] - lampPost.height * 0.95);
    onThreshold = (int)random(0, 100);

    // Create the shape of light beam
    lightBeam = createShape();
    lightBeam.beginShape();
    lightBeam.fill(255, 252, 0, 150);
    lightBeam.noStroke();
    lightBeam.vertex(lampPost.width/2 + lampPost.width/10, lampPost.height/7);
    lightBeam.vertex(lampPost.width +  tan(.7) * (height - pos.y), height - pos.y);
    lightBeam.vertex(-tan(.7) * (height - pos.y), height - pos.y);
    lightBeam.vertex(lampPost.width/2 - lampPost.width/10, lampPost.height/7);
    lightBeam.endShape(CLOSE);
    lightBeam.disableStyle();
  }

  void drawLampPost() { 
    pushMatrix();
    pushStyle();

    translate(pos.x, pos.y);
    smooth(8);

    // apply shadow
    tint(brightnessBackground + 50);

    // check if lamp post is on
    if (brightnessBackground < onThreshold ) {
      // if we just went on we keep warming up
      if (warmingUp < 150)
        warmingUp++;
      // display light bulb, lamp post and light beam  
      fill(255, warmingUp, 0, 75 - brightnessBackground);
      ellipse(lampPost.width / 2, lampPost.height / 7, 10, 20);
      image(lampPost, 0, 0);
      shape(lightBeam, 0, 0);
    } else {
      image(lampPost, 0, 0);
      warmingUp = 0; 
    }

    popStyle();
    popMatrix();
  }
}
