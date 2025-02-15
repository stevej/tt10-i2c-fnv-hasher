#include <Wire.h>
#define HASHER_ADDRESS 0x71

void setup()  {
    Wire.begin();        // join i2c bus (address optional for master)
    Serial.begin(9600);  // start serial for output
}

void loop() {
    // Write 4 bytes
    Wire.beginTransmission(HASHER_ADDRESS);
    Wire.write(0x1);
    Wire.write(0x2);
    Wire.write(0x3);
    Wire.write(0x4);
    Wire.endTransmission();

    // Read the 32-bit response
    Wire.requestFrom(HASHER_ADDRESS, 4);    // request x bytes from sensor
    byte x3 = Wire.read();
    byte x2 = Wire.read();
    byte x1 = Wire.read();
    byte x0 = Wire.read();
    Serial.println(x3);
    Serial.println(x2);
    Serial.println(x1);
    Serial.println(x0);
    delay(1000);
}