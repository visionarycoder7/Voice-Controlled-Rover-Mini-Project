#include <Servo.h>

Servo radar;

// 🔧 YOUR PINS
const int trigPin = 7;
const int echoPin = 8;
const int servoPin = 9;

long duration;
int distance;

void setup() {

  radar.attach(servoPin);

  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);

  Serial.begin(9600);
}

void loop() {

  // Sweep left → right
  for (int angle = 15; angle <= 165; angle++) {

    radar.write(angle);
    delay(40);

    distance = getDistance();

    Serial.print(angle);
    Serial.print(",");
    Serial.println(distance);
  }

  // Sweep right → left
  for (int angle = 165; angle >= 15; angle--) {

    radar.write(angle);
    delay(40);

    distance = getDistance();

    Serial.print(angle);
    Serial.print(",");
    Serial.println(distance);
  }
}

// 📏 Distance Function (UPDATED)
int getDistance() {

  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);

  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH, 30000);

  if (duration == 0) return 400; // no echo

  int dist = duration * 0.034 / 2;

  return dist;
}
