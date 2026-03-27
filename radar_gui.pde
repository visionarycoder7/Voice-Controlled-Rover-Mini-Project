import processing.serial.*;

Serial myPort;
float angle = 0;
float distance = 0;
String data = "";

// Stores detected objects as trails that fade out
float[] trailAngles = new float[500];
float[] trailDists  = new float[500];
float[] trailAlpha  = new float[500];
int trailCount = 0;

// Sweep line fade trail
float[] sweepAngles = new float[30];
int sweepIndex = 0;

void setup() {
  size(800, 600);

  println("Available serial ports:");
  println(Serial.list());

  // ✅ Change "COM5" to your port (e.g. "/dev/ttyUSB0" on Linux/Mac)
  try {
    myPort = new Serial(this, "COM5", 9600);
    myPort.bufferUntil('\n');
    println("Serial connected.");
  } catch (Exception e) {
    println("Serial port not found. Running in demo mode.");
  }

  for (int i = 0; i < sweepAngles.length; i++) {
    sweepAngles[i] = 0;
  }
}

void draw() {
  background(0);
  translate(width / 2, height - 60);

  int maxRadius = 340;

  // ── Fading sweep trail ──────────────────────────────────
  for (int i = 0; i < sweepAngles.length; i++) {
    float alpha = map(i, 0, sweepAngles.length - 1, 5, 60);
    float rad   = radians(sweepAngles[i]);
    stroke(0, 255, 0, alpha);
    strokeWeight(1.5);
    line(0, 0, maxRadius * cos(rad), -maxRadius * sin(rad));
  }

  // ── Radar arcs ──────────────────────────────────────────
  strokeWeight(1);
  noFill();
  int[] rings  = {85, 170, 255, 340};
  int[] labels = {25,  50,  75, 100};
  for (int i = 0; i < rings.length; i++) {
    stroke(0, 200, 0, 120);
    arc(0, 0, rings[i] * 2, rings[i] * 2, PI, TWO_PI);
    fill(0, 180, 0, 160);
    noStroke();
    textSize(10);
    textAlign(RIGHT);
    text(labels[i] + " cm", -rings[i] - 4, 0);
    noFill();
    stroke(0, 200, 0, 120);
  }

  // ── Angle guide lines every 30° ─────────────────────────
  stroke(0, 150, 0, 80);
  strokeWeight(0.5);
  for (int a = 0; a <= 180; a += 30) {
    float r = radians(a);
    line(0, 0, maxRadius * cos(r), -maxRadius * sin(r));
    fill(0, 180, 0, 160);
    noStroke();
    textSize(10);
    textAlign(CENTER);
    float lx = (maxRadius + 16) * cos(r);
    float ly = (maxRadius + 16) * -sin(r);
    text(a + "°", lx, ly);
    noFill();
    stroke(0, 150, 0, 80);
  }

  // ── Fading object trail ─────────────────────────────────
  for (int i = trailCount - 1; i >= 0; i--) {
    trailAlpha[i] -= 0.8;
    if (trailAlpha[i] <= 0) {
      for (int j = i; j < trailCount - 1; j++) {
        trailAngles[j] = trailAngles[j + 1];
        trailDists[j]  = trailDists[j + 1];
        trailAlpha[j]  = trailAlpha[j + 1];
      }
      trailCount--;
      continue;
    }
    float tr = radians(trailAngles[i]);
    float td = map(trailDists[i], 0, 100, 0, maxRadius);
    float tx = td * cos(tr);
    float ty = -td * sin(tr);
    fill(255, 0, 0, trailAlpha[i]);
    noStroke();
    ellipse(tx, ty, 10, 10);
  }

  // ── Live detection dot ───────────────────────────────────
  float rad = radians(angle);
  if (distance > 0 && distance < 100) {
    float d  = map(distance, 0, 100, 0, maxRadius);
    float dx = d * cos(rad);
    float dy = -d * sin(rad);

    // Glow ring
    noFill();
    stroke(255, 0, 0, 80);
    strokeWeight(1);
    ellipse(dx, dy, 22, 22);

    // Solid dot
    fill(255, 30, 30);
    noStroke();
    ellipse(dx, dy, 12, 12);

    // Store in trail
    if (trailCount < trailAngles.length) {
      trailAngles[trailCount] = angle;
      trailDists[trailCount]  = distance;
      trailAlpha[trailCount]  = 220;
      trailCount++;
    }
  }

  // ── Active sweep line ────────────────────────────────────
  stroke(0, 255, 0, 255);
  strokeWeight(2);
  line(0, 0, maxRadius * cos(rad), -maxRadius * sin(rad));

  // ── HUD text ─────────────────────────────────────────────
  resetMatrix();
  fill(0, 255, 0);
  noStroke();
  textAlign(LEFT);
  textSize(14);
  text("ANGLE    : " + nf(angle, 1, 1) + "°",                                          20, height - 50);
  text("DISTANCE : " + (distance > 0 && distance < 100 ? nf(distance, 1, 1) + " cm" : "---"), 20, height - 30);
  text("STATUS   : " + (distance > 0 && distance < 100 ? "OBJECT DETECTED" : "CLEAR"), 20, height - 10);

  fill(0, 180, 0, 160);
  textSize(11);
  textAlign(RIGHT);
  text(myPort != null ? "SERIAL OK  |  9600 baud" : "NO SERIAL — DEMO MODE", width - 20, height - 10);

  textAlign(CENTER);
  textSize(13);
  fill(0, 200, 0, 180);
  text("HC-SR04 RADAR SCANNER", width / 2, 20);

  // ── Store sweep history ──────────────────────────────────
  sweepAngles[sweepIndex] = angle;
  sweepIndex = (sweepIndex + 1) % sweepAngles.length;
}

// ── Serial data handler ──────────────────────────────────────
void serialEvent(Serial port) {
  data = port.readStringUntil('\n');
  if (data != null) {
    data = trim(data);
    String[] values = split(data, ',');
    if (values.length == 2) {
      try {
        float a = float(values[0]);
        float d = float(values[1]);
        if (a >= 0 && a <= 180) angle    = a;
        if (d >= 0)             distance = d;
      } catch (Exception e) {
        println("Parse error: " + data);
      }
    }
  }
}
