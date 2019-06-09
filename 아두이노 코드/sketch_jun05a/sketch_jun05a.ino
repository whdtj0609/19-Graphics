#include <DHT.h>

int pin = A3;
DHT dht(pin, DHT11);
int SW_pin = 8;
int sensorPin = A2;
int X_axis = A0;
int Y_axis = A1;
int sensorValue = 0;

int temp_i;
int temp_f;
int humid_i;
int humid_f;

byte STX = -128;
byte ETX = -127;

bool serial_read = 0;

void setup() {
  dht.begin();
  pinMode(SW_pin, INPUT_PULLUP);
  Serial.begin(9600);
}

void loop() {
  int SW_val = digitalRead(SW_pin);
  int X_val = analogRead(X_axis);
  int Y_val = analogRead(Y_axis);
  sensorValue = analogRead(sensorPin);
  float temp = dht.readTemperature();
  float humi = dht.readHumidity();

  Serial.write(STX);
  Serial.write((int)temp);
  Serial.write((int)humi);
  Serial.write(sensorValue >> 8);
  Serial.write((byte)sensorValue);
  Serial.write(X_val >> 8);
  Serial.write((byte)X_val);
  Serial.write(Y_val >> 8);
  Serial.write((byte)Y_val);
  Serial.write(ETX);
  
  delay(200);
  
}
