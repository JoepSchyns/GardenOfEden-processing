/*** Constants ***/
final color elasticColor = color(102, 51, 0);  // Color of the elastic

/*** Variables ***/
PVector sPresPos;                     // Coordinates when left mouse button is pressed
boolean pressed = false;              // Whether left mouse button is pressed
boolean[] keys = new boolean[526];    // Whether a key is hold down

void elasticMousePressed() {
  // If left mouse button is pressed we start pulling
  if (mouseButton == LEFT) {
    pressed = true;
    sPresPos = new PVector(mouseX, mouseY);
  }
}

void mouseReleased() { 
  // When left mouse button is released we release the ball
  if (mouseButton == LEFT) {
    pressed = false;
    
    // coordinates of mouse when released
    PVector aPresPos = new PVector(mouseX, mouseY); 
    PVector speed = PVector.sub(sPresPos, aPresPos);
    
    //adjust strengt of elactic 
    speed.mult(0.1); 
    balls.add(new Ball(aPresPos, speed, balls.size()));
  }
}

void drawElastic() {
  // Draw line from starting press position to current position to simulate a elastic if LMB is pressed
  if (pressed) { 
    stroke(elasticColor);
    fill(elasticColor);
    
    //draw ellipse "that holds the ball which is shot"
    ellipse(mouseX, mouseY, 10, 10); 
    // draw a line from the point that the drag started to current mouse position
    line(round(sPresPos.x), round(sPresPos.y), mouseX, mouseY); 
  }
}

void keyPressed() {
  keys[keyCode] = true;
  droneKeyPressed();
}

void keyReleased() { 
  keys[keyCode] = false; 
}

void mousePressed() {
  elasticMousePressed();
  droneMousePressed();
}

boolean checkKey(int k) {
  if (keys.length >= k) {
    return keys[k];  
  }
  return false;
}
