#include <Arduino.h>
#include <BH1750.h>
#include "DHT.h"
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BMP280.h>
#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <string>
#include <sstream>

#define DHTTYPE DHT11
#define DHTPIN 2

BH1750 lightMeter(0x23);
DHT dht(DHTPIN, DHTTYPE);
Adafruit_BMP280 bmp;

const int soil_moisture_sensor_pin = A0;

float light_intensity();
int soil_moisture();
float get_temperature();
float get_humidity();
float get_heat_index(float temp, float humid);
float get_pressure();
void callback(char *topic, byte *payload, unsigned int length);
void setup_wifi();
void reconnect();

// MQTT

const char *ssid = "UVTNet";
const char *password = "tasauki123!";
const char *mqtt_server = "192.168.1.41";
const char *topic = "sensors";
const char *mqtt_username = "devuser";
const char *mqtt_password = "changeme";
const int mqtt_port = 1883;

WiFiClient espClient;
PubSubClient client(espClient);

void setup()
{
    Serial.begin(115200);

    // WiFi
    setup_wifi();

    // MQTT
    client.setServer(mqtt_server, mqtt_port);
    client.setCallback(callback);
    while (!client.connected())
    {
        String client_id = "esp8266-client-";
        client_id += String(WiFi.macAddress());
        Serial.printf("The client %s connects to the public mqtt broker\n", client_id.c_str());
        if (client.connect(client_id.c_str(), mqtt_username, mqtt_password))
        {
            Serial.println("Connected");
        }
        else
        {
            Serial.println("Failed");
            delay(2000);
        }
    }

    client.subscribe(topic);

    // BMP280
    bmp.begin();
    bmp.setSampling(Adafruit_BMP280::MODE_FORCED,
                    Adafruit_BMP280::SAMPLING_X2,
                    Adafruit_BMP280::SAMPLING_X16,
                    Adafruit_BMP280::FILTER_X16,
                    Adafruit_BMP280::STANDBY_MS_1000);

    // BH1750
    Wire.begin(12, 14);
    if (lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE))
    {
        Serial.println(F("BH1750 Advanced begin"));
    }
    else
    {
        Serial.println(F("Error initialising BH1750"));
    }

    // DHT
    dht.begin();
}

unsigned long lastMsg = 0;
float lux = 0;
int moisture = 0;
float temperature = 0;
float humidity = 0;
float heat_index = 0;
float pressure = 0;
void loop()
{
    if (!client.connected())
    {
        reconnect();
    }
    client.loop();

    unsigned long now = millis();

    if (now - lastMsg > 2000)
    {
        std::ostringstream oss;
        oss << "{\"lux\":" << lux << ",\"moisture\":" << moisture << ",\"temperature\":" << temperature << ",\"humidity\":" << humidity << ",\"heat_index\":" << heat_index << ",\"pressure\":" << pressure << "}";
        lastMsg = now;
        client.publish(topic, oss.str().c_str());
    }

    lux = light_intensity();
    Serial.print("Light: ");
    Serial.print(lux);
    Serial.println(" lx");

    moisture = soil_moisture();
    Serial.print("Moisture = ");
    Serial.print(moisture);
    Serial.println(" %");

    temperature = get_temperature();
    Serial.print("Temeprature:");
    Serial.print(temperature);
    Serial.println(" °C");

    humidity = get_humidity();
    Serial.print("Humidity:");
    Serial.print(humidity);
    Serial.println(" %");

    heat_index = get_heat_index(temperature, humidity);
    Serial.print("Heat index:");
    Serial.print(heat_index);
    Serial.println(" °C");

    pressure = get_pressure();
    Serial.print("Pressure = ");
    Serial.print(pressure);
    Serial.println(" hPa");

    delay(1000);
}

void callback(char *topic, byte *payload, unsigned int length)
{
    Serial.print("Message: ");
    for (unsigned int i = 0; i < length; i++)
    {
        Serial.print((char)payload[i]);
    }

    Serial.println();
    Serial.println("-----------------------");
}

float get_pressure()
{
    if (bmp.takeForcedMeasurement())
    {
        // float temp = bmp.readTemperature();
        // float altitude = bmp.readAltitude(1013.25);

        float pressure = bmp.readPressure() * 0.01;
        return pressure;
    }
    return 1013.25;
}

float get_humidity()
{
    float old_humidity = 0;
    float new_humidity = dht.readHumidity();

    if (isnan(new_humidity))
    {
        return old_humidity;
    }
    old_humidity = new_humidity;
    return new_humidity;
}

float get_temperature()
{
    float old_temperature = 0;
    float new_temperature = dht.readTemperature();

    if (isnan(new_temperature))
    {
        return old_temperature;
    }
    old_temperature = new_temperature;
    return new_temperature;
}

float get_heat_index(float temp, float humid)
{
    return dht.computeHeatIndex(temp, humid, false);
}

float light_intensity()
{
    if (lightMeter.measurementReady())
    {
        return lightMeter.readLightLevel();
    }
    return 0;
}

int soil_moisture()
{
    int sensor_analog = analogRead(soil_moisture_sensor_pin);
    return (100 - ((sensor_analog / 1024.00) * 100));
}

void setup_wifi()
{
    delay(10);
    Serial.println("Connecting to WIFI ");

    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);

    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }

    randomSeed(micros());
}

void reconnect()
{
    // Loop until we're reconnected
    while (!client.connected())
    {
        Serial.print("Attempting MQTT connection...");
        // Create a random client ID
        String clientId = "ESP8266Client-";
        clientId += String(random(0xffff), HEX);
        // Attempt to connect
        if (client.connect(clientId.c_str()))
        {
            Serial.println("Reconnected");
        }
        else
        {
            Serial.print("failed, rc=");
            Serial.print(client.state());
            Serial.println(" try again in 5 seconds");
            // Wait 5 seconds before retrying
            delay(5000);
        }
    }
}