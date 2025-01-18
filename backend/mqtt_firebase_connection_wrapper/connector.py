import time

import firebase_admin
from firebase_admin import credentials, firestore
import paho.mqtt.client as mqtt
import json

from mosquitto_utils.ACLManager import ACLManager
from mosquitto_utils.FirebaseMQTTListener import FirebaseMQTTListener
from mosquitto_utils.MQTTUserManager import MQTTUserManager

cred = credentials.Certificate("smart-lighting-system-firebase-admin-sdk-credentials.json")
from firestore_listeners.board_listeners import on_boards_snapshot

firebase_admin.initialize_app(cred)
db = firestore.client()
print("Connected to Firebase successfully!")

PASSWORD_FILE = "passwd"
ACL_FILE = "acl"

mqtt_user_manager = MQTTUserManager(PASSWORD_FILE)
acl_manager = ACLManager(ACL_FILE)

firebase_mqtt_listener = FirebaseMQTTListener(db, mqtt_user_manager, acl_manager)
firebase_mqtt_listener.start_listening("mqtt_clients")


def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT broker!")
    else:
        print(f"MQTT connection failed with code: {rc}")


def on_message(client, userdata, msg):
    try:
        payload = msg.payload.decode()
        data = json.loads(payload)
        print(f"Received message on {msg.topic}: {data}")
    except json.JSONDecodeError:
        print(f"Failed to decode message payload: {msg.payload}")


BROKER_ADDRESS = "localhost"
BROKER_PORT = 1883

mqtt_client = mqtt.Client()
creds_doc = db.collection("mqtt_clients").document("some_doc_id").get()
if creds_doc.exists:
    creds_data = creds_doc.to_dict()
    username = creds_data.get("userId")
    password = creds_data.get("mqtt_password")
    if username and password:
        mqtt_client.username_pw_set(username=username, password=password)

mqtt_client.on_connect = on_connect
mqtt_client.on_message = on_message

mqtt_client.connect(BROKER_ADDRESS, BROKER_PORT, 60)
mqtt_client.loop_start()

print("MQTT client started.")




device_listeners = {}

boards_ref = db.collection("boards")

def start_boards_listener():
    print("Setting up listener for boards...")
    boards_ref.on_snapshot(
        lambda col_snapshot, changes, read_time: on_boards_snapshot(
            col_snapshot, changes, read_time, db, device_listeners
        )
    )
    print("Listener for boards is active.")

start_boards_listener()











try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("Shutting down...")
finally:
    mqtt_client.loop_stop()
    mqtt_client.disconnect()
