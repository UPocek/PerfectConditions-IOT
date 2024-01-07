import paho.mqtt.client as paho
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS
import sys
import json

def on_message_received(client, userdata, message):
    try:
        data = json.loads(message.payload.decode('utf-8'))
        write_api = influxdb_client.write_api(write_options=SYNCHRONOUS)
        point = (
        Point("readings")
        .tag("sensor_id", str(data["sensor_id"]))
        .field("lux", float(data["lux"]))
        .field("moisture", int(data["moisture"]))
        .field("temperature", float(data["temperature"]))
        .field("humidity", float(data["humidity"]))
        .field("heat_index", float(data["heat_index"]))
        .field("pressure", float(data["pressure"]))
    )
        write_api.write(bucket=bucket, org=org, record=point)
        print("Data written:", data)
    except Exception as e:
        print("error: ")
        print(e)
        return
    
def on_connect(client, userdata, flags, rc):
    print("Server connected")

def connect_mqtt():
    client = paho.Client()
    client.username_pw_set("devuser", password="changeme")
    client.on_message = on_message_received
    client.on_connect = on_connect
    if client.connect("localhost", 1883, 60) != 0:
        print("Couldn't connect to the mqtt broker")
        sys.exit(1)
    return client

def get_influxdb_client():
    token = "MQwOxvkIKz-EbDCKYLrM-YRNiaz3NrfcchDJIxuNtH_K8umlis9tUZqEPEq-SxSM9gLiM15cYsVrZqEfGbelbQ=="
    url = "http://192.168.1.27:8087"
    influxdb_client = InfluxDBClient(url=url, token=token, org=org)
    return influxdb_client


if __name__ == "__main__":
    bucket = "iot-server"
    org = "iot-server"

    client = connect_mqtt()
    influxdb_client = get_influxdb_client()
    client.subscribe(f"sensors")
    client.loop_forever()