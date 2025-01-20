#include <DHT.h>

// Define the DHT sensor types
#define DHTTYPE DHT22

// Define pins for the sensors
#define DHT22UP 8
#define DHT22DOWN 5

// Define pins for gears (relays)
#define Gear1 22
#define Gear2 23
#define Light 28
// Other RELAYS
#define Relay1 24
#define Relay2 25
#define Relay3 26
#define Relay4 27
#define Relay5 29
#define Relay6 32
#define Relay7 33
#define MiddleLeft 13

//DEFINE pins for ultrasonic and pumps
#define UltrasonicUpEcho 51
#define UltrasonicUpTrig 53
#define UltrasonicDownEcho 50
#define UltrasonicDownTrig 52
#define WaterResivourEcho 49
#define WaterResivourTrig 48

#define PumpUpPin 30
#define PumpDownPin 31

long durationUp, durationDown;
int distanceUp, distanceDown;

// Define pins for IR speed sensors
#define IRSensor1 2
#define IRSensor2 3

// Initialize variables
float tempUp = 0.0;
float humUp = 0.0;
float tempDown = 0.0;
float humDown = 0.0;
long WaterResivourDistance;
int WaterResivourPercentage; 

// Create DHT objects
DHT dhtUp(DHT22UP, DHTTYPE);
DHT dhtDown(DHT22DOWN, DHTTYPE);

void setup() {
  // Initialize serial communication
  Serial.begin(9600);

  // Start DHT sensors
  dhtUp.begin();
  dhtDown.begin();

  // Set gear pins as outputs and turn them OFF initially
  pinMode(Gear1, OUTPUT);
  pinMode(Gear2, OUTPUT);
  pinMode(Light, OUTPUT);
  pinMode(Relay1, OUTPUT);
  pinMode(Relay2, OUTPUT);
  pinMode(Relay3, OUTPUT);
  pinMode(Relay4, OUTPUT);
  pinMode(Relay5, OUTPUT);
  pinMode(Relay6, OUTPUT);
  pinMode(Relay7, OUTPUT);
  digitalWrite(Gear1, LOW);  // Gear ON
  digitalWrite(Gear2, LOW);  // Gear ON
  digitalWrite(Light, HIGH);  // Light OFF
  digitalWrite(Relay1, LOW);
  digitalWrite(Relay2, LOW);
  digitalWrite(Relay3, LOW);
  digitalWrite(Relay4, LOW);
  digitalWrite(Relay5, LOW);
  digitalWrite(Relay6, LOW);
  digitalWrite(Relay7, LOW);

  // Initialize ultrasonic sensor pins
  pinMode(UltrasonicUpTrig, OUTPUT);
  pinMode(UltrasonicUpEcho, INPUT);
  pinMode(UltrasonicDownTrig, OUTPUT);
  pinMode(UltrasonicDownEcho, INPUT);
  pinMode(WaterResivourTrig, OUTPUT);
  pinMode(WaterResivourEcho, INPUT);
  
  // Initialize pump pins
  pinMode(PumpUpPin, OUTPUT);
  pinMode(PumpDownPin, OUTPUT);
  digitalWrite(PumpUpPin, HIGH);
  digitalWrite(PumpDownPin, LOW);

  // Set IR sensors as inputs
  pinMode(IRSensor1, INPUT);
  pinMode(IRSensor2, INPUT);
}

void loop() {
  // Listen to serial input
  if (Serial.available() > 0) {
    char command = Serial.read();

    // Switch case to handle commands
    switch (command) {
      case '1':  // If "1" is received, trigger IR speed sensors
        TurnOffGear();
        digitalWrite(Light, LOW);  // Light ON
        break;

      case '2':  // If "1" is received, trigger IR speed sensors
        digitalWrite(Gear1, LOW);
        digitalWrite(Gear2, LOW);
        digitalWrite(Light, HIGH);  // Light OFF
        delay(500)
        GearTilt();
        break;

      default:
        // Handle other commands if necessary
        break;
    }
  }
  TempAndHumidity();
  HumidityWater();
  WaterResivour();

  // Format the UploadPrint string
  String UploadPrint = "Upload," + String(tempUp, 2) + "," + String(humUp, 2) + "," + String(tempDown, 2) + "," + String(humDown, 2) + "," + String(WaterResivourPercentage);

  // Print the UploadPrint string
  Serial.println(UploadPrint);

  // Wait for 2 seconds before the next reading
  delay(2000);
}

void TempAndHumidity() {
  // Read temperature and humidity from DHT22UP
  tempUp = dhtUp.readTemperature();
  tempUp -= 3.10;
  humUp = dhtUp.readHumidity();
  humUp += 13.60;

  // Read temperature and humidity from DHT22DOWN
  tempDown = dhtDown.readTemperature();
  tempDown += 1;
  humDown = dhtDown.readHumidity();
  humDown -= 1.80;

  // Check if readings are valid
  if (isnan(tempUp) || isnan(humUp)) {
    Serial.println("Failed to read from DHT22UP sensor!");
    tempUp = 0.0;  // Set default value
    humUp = 0.0;   // Set default value
  }

  if (isnan(tempDown) || isnan(humDown)) {
    Serial.println("Failed to read from DHT22DOWN sensor!");
    tempDown = 0.0;  // Set default value
    humDown = 0.0;   // Set default value
  }
}

void TurnOffGear() {
  // Continuously check the state of the IR speed sensors in a while loop
  while (true) {
    int sensor1State = digitalRead(IRSensor1);  // Read the state of IRSensor1

    // If IRSensor1 is HIGH, set Gear1 to HIGH and break the loop
    if (sensor1State == LOW) {
      digitalWrite(Gear1, HIGH);  // Turn ON Gear1 (LOW turns on the relay)
      break;  // Exit the while loop once Gear1 is activated
    } else {
      digitalWrite(Gear1, LOW);  // Turn OFF Gear1
    }
  }
  delay(100);
  // Now check IRSensor2 after IRSensor1 has been handled
  while (true) {
    int sensor2State = digitalRead(IRSensor2);  // Read the state of IRSensor2

    // If IRSensor2 is HIGH, set Gear2 to LOW (active state)
    if (sensor2State == LOW) {
      digitalWrite(Gear2, HIGH);  // Turn ON Gear2 (LOW turns on the relay)
      Serial.println("Gear,Done");
      break;  // Exit the while loop once Gear2 is activated
    } else {
      digitalWrite(Gear2, LOW);  // Turn OFF Gear2
    }
  }
delay(1000);
}

void GearTilt() {
  unsigned long gear1HighTime = 0;  // Store the time when Gear1 is set HIGH
  unsigned long gear2HighTime = 0;  // Store the time when Gear2 is set HIGH
  
  bool gear1Active = false;  // Track if Gear1 is currently ON
  bool gear2Active = false;  // Track if Gear2 is currently ON

  while (true) {
    // Check IRSensor1
    int sensor1State = digitalRead(IRSensor1);
    if (sensor1State == LOW) {
      if (!gear1Active) {
        digitalWrite(Gear1, LOW);  // Turn ON Gear1
        gear1HighTime = millis();   // Record the time Gear1 was activated
        gear1Active = true;
      }
    } else if (gear1Active && (millis() - gear1HighTime >= 3000)) {
      // If Gear1 has been ON for 3 seconds, turn it OFF
      digitalWrite(Gear1, HIGH);
      gear1Active = false;
    }

    // Check IRSensor2
    int sensor2State = digitalRead(IRSensor2);
    if (sensor2State == LOW) {
      if (!gear2Active) {
        digitalWrite(Gear2, LOW);  // Turn ON Gear2
        gear2HighTime = millis();   // Record the time Gear2 was activated
        gear2Active = true;
      }
    } else if (gear2Active && (millis() - gear2HighTime >= 3000)) {
      // If Gear2 has been ON for 3 seconds, turn it OFF
      digitalWrite(Gear2, HIGH);
      gear2Active = false;
    }
    delay(10); // Small delay to prevent excessive looping
  }
}


void HumidityWater(){
  
  // Read the distance for the Ultrasonic Up sensor (Top sensor)
  digitalWrite(UltrasonicUpTrig, LOW);
  delayMicroseconds(2);
  digitalWrite(UltrasonicUpTrig, HIGH);
  delayMicroseconds(10);
  digitalWrite(UltrasonicUpTrig, LOW);
  durationUp = pulseIn(UltrasonicUpEcho, HIGH);
  distanceUp = durationUp * 0.034 / 2;  // Calculate distance in cm
  
  // Read the distance for the Ultrasonic Down sensor (Bottom sensor)
  digitalWrite(UltrasonicDownTrig, LOW);
  delayMicroseconds(2);
  digitalWrite(UltrasonicDownTrig, HIGH);
  delayMicroseconds(10);
  digitalWrite(UltrasonicDownTrig, LOW);
  durationDown = pulseIn(UltrasonicDownEcho, HIGH);
  distanceDown = durationDown * 0.034 / 2;  // Calculate distance in cm

  // Control the top pump based on the top sensor distance
  if (distanceUp >= 8) {
    digitalWrite(PumpUpPin, LOW);  // Turn on the top pump
  } else if (distanceUp <= 1) {
    digitalWrite(PumpUpPin, HIGH);  // Turn off the top pump
  }

  // Control the bottom pump based on the bottom sensor distance
  if (distanceDown >= 8) {
    digitalWrite(PumpDownPin, LOW);  // Turn on the bottom pump
  } else if (distanceDown <= 1) {
    digitalWrite(PumpDownPin, HIGH);  // Turn off the bottom pump
  }
}

void WaterResivour(){
  digitalWrite(WaterResivourTrig, LOW);
  delayMicroseconds(2);
  digitalWrite(WaterResivourTrig, HIGH);
  delayMicroseconds(10);
  digitalWrite(WaterResivourTrig, LOW);
  
  WaterResivourDistance = pulseIn(WaterResivourEcho, HIGH); 
  WaterResivourDistance = WaterResivourDistance * 0.034 / 2;  // Calculate distance in cm
  
  // Map the distance to a percentage (13 cm = 100%, 0 cm = 0%)
  WaterResivourPercentage = map(WaterResivourDistance, 0, 13, 0, 100);
}