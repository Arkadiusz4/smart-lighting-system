import firebase_admin
from firebase_admin import credentials, firestore
import paho.mqtt.client as mqtt
import json

# Initialize Firebase
cred = credentials.Certificate(
    "mqtt_firebase_connection_wrapper/smart-lighting-system-firebase-admin-sdk-credentials.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print("Connected to Firebase successfully!")

# MQTT Configuration
BROKER_ADDRESS = "localhost"
BROKER_PORT = 1883
MQTT_TOPICS = ["local/sensors/temperature", "test_sensor_data"]
device_listeners = {}

def write_to_firestore(collection_name, document_data):
    """Writes data to Firestore."""
    try:
        db.collection(collection_name).add(document_data)
        print(f"Data written to Firestore: {document_data}")
    except Exception as e:
        print(f"Error writing to Firestore: {e}")


def on_firestore_snapshot(col_snapshot, changes, read_time):
    """Callback for Firestore real-time updates."""
    for change in changes:
        if change.type.name == "ADDED":
            print(f"New document added: {change.document.id} => {change.document.to_dict()}")
        elif change.type.name == "MODIFIED":
            print(f"Document modified: {change.document.id} => {change.document.to_dict()}")
        elif change.type.name == "REMOVED":
            print(f"Document removed: {change.document.id}")



def on_devices_snapshot(col_snapshot, changes, read_time):
    """Callback for device subcollection updates."""
    for change in changes:
        if change.type.name == "ADDED":
            print(f"New device added: {change.document.id} => {change.document.to_dict()}")
        elif change.type.name == "MODIFIED":
            print(f"Device modified: {change.document.id} => {change.document.to_dict()}")
        elif change.type.name == "REMOVED":
            print(f"Device removed: {change.document.id}")


def on_boards_snapshot(col_snapshot, changes, read_time):
    """Callback for boards collection updates."""
    for change in changes:
        if change.type.name == "ADDED":
            board_id = change.document.id
            print(f"New board added: {board_id}")
            
            devices_ref = db.collection(f"boards/{board_id}/devices")
            device_listeners[board_id] = devices_ref.on_snapshot(on_devices_snapshot)
            print(f"Subscribed to devices for board: {board_id}")
        elif change.type.name == "REMOVED":
            board_id = change.document.id
            print(f"Board removed: {board_id}")
            
            if board_id in device_listeners:
                device_listeners[board_id].unsubscribe()
                del device_listeners[board_id]
                print(f"Unsubscribed from devices for board: {board_id}")

boards_ref = db.collection("boards")
boards_listener = boards_ref.on_snapshot(on_boards_snapshot)

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT broker!")
        for topic in MQTT_TOPICS:
            client.subscribe(topic)
            print(f"Subscribed to topic: {topic}")
    else:
        print(f"MQTT connection failed with code: {rc}")


def on_message(client, userdata, msg):
    try:
        payload = msg.payload.decode()
        data = json.loads(payload)  
        print(f"Received message on {msg.topic}: {data}")
        write_to_firestore("mqtt_data", {"topic": msg.topic, "data": data})
    except json.JSONDecodeError:
        print(f"Failed to decode message payload: {msg.payload}")


# MQTT Client Setup
mqtt_client = mqtt.Client()
mqtt_client.username_pw_set(username="your_username", password="your_password")
mqtt_client.on_connect = on_connect
mqtt_client.on_message = on_message

mqtt_client.connect(BROKER_ADDRESS, BROKER_PORT, 60)
mqtt_client.loop_start()

try:
    print("Application is running. Press Ctrl+C to stop.")
    while True:
        pass
except KeyboardInterrupt:
    print("Stopping application...")
    mqtt_client.loop_stop()
    mqtt_client.disconnect()
