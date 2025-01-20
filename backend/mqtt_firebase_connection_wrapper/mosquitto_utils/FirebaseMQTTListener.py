import subprocess
import time
import json
from datetime import datetime

import paho.mqtt.client as mqtt
from firebase_admin import firestore

BROKER_ADDRESS = "192.168.0.145"
BROKER_PORT = 2137


def create_on_connect_callback(user_id, boardId):
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print(f"[INFO] Client {user_id} connected to MQTT broker on board {boardId}!")
            client.subscribe(f"boards/{boardId}/#")
            client.subscribe("central/command/#")
        else:
            print(f"[ERROR] Client {user_id} connection failed with code: {rc}")
            if rc == 5:
                print("[ERROR] Not authorized. Check username/password in Mosquitto.")

    return on_connect


class FirebaseMQTTListener:
    def __init__(self, db, mqtt_user_manager, acl_manager):
        self.db = db
        self.mqtt_user_manager = mqtt_user_manager
        self.acl_manager = acl_manager
        self.user_clients = {}
        self.last_heartbeat = {}
        self.board_user_map = {}
        self.lost_boards = set()

    def create_on_message_callback(self):
        def on_message(client, userdata, msg):
            try:
                payload = msg.payload.decode()
                try:
                    data = json.loads(payload)
                except json.JSONDecodeError:
                    data = None

                print(f"Received message on {msg.topic}: {payload}")

                # Obsługa heartbeat
                if msg.topic.endswith("/heartbeat"):
                    board_id = msg.topic.split('/')[1]
                    self.last_heartbeat[board_id] = datetime.utcnow()
                    print(f"Heartbeat received from board {board_id} at {self.last_heartbeat[board_id]}")
                    return

                # Dla wiadomości ruchu lub sieci
                log_entry = None
                if msg.topic.endswith("/motion"):
                    log_entry = {
                        "timestamp": firestore.SERVER_TIMESTAMP,
                        "message": "Wykryto ruch!",
                        "eventType": "motion_detected",
                        "device": data.get("deviceId") if data else None,
                        "severity": "warning",
                        "boardId": msg.topic.split('/')[1]
                    }
                elif msg.topic.endswith("/network") and payload == "connected":
                    log_entry = {
                        "timestamp": firestore.SERVER_TIMESTAMP,
                        "message": "Połączono z Wi-Fi!",
                        "eventType": "wifi_connected",
                        "device": "Network",
                        "severity": "info",
                        "boardId": msg.topic.split('/')[1]
                    }
                else:
                    print(f"Unhandled message on {msg.topic}: {payload}")
                    return

                board_id = msg.topic.split('/')[1]
                user_id = self.board_user_map.get(board_id)

                if user_id:
                    self.db.collection("users").document(user_id) \
                        .collection("logs").add(log_entry)
                else:
                    self.db.collection("logs").add(log_entry)
                print("Log entry added to Firestore.")
            except Exception as e:
                print(f"Error processing message: {e}")

        return on_message

    def on_mqtt_clients_snapshot(self, col_snapshot, changes, read_time):
        for change in changes:
            doc = change.document
            data = doc.to_dict()
            user_id = data.get("userId")
            mqtt_password = data.get("mqtt_password")
            board_id = data.get("boardId")
            topic = f"boards/{board_id}/#"

            if board_id and user_id:
                self.board_user_map[board_id] = user_id

            if change.type.name in ("ADDED", "MODIFIED"):
                print(f"Aktualizacja lub dodanie użytkownika: {user_id}")
                print("[INFO] Updating Mosquitto configuration...")

                if user_id and mqtt_password:
                    self.mqtt_user_manager.add_or_update_user(user_id, mqtt_password)
                    self.acl_manager.add_or_update_rule(user_id, topic, permission="readwrite")
                    restart_mosquitto()
                    print("[INFO] Waiting for Mosquitto to restart...")
                    time.sleep(5)

                    if user_id not in self.user_clients:
                        client = mqtt.Client(client_id=f"client_{user_id}")
                        client.username_pw_set(username=user_id, password=mqtt_password)
                        client.on_connect = create_on_connect_callback(user_id, board_id)
                        client.on_message = self.create_on_message_callback()

                        max_retries = 5
                        for attempt in range(max_retries):
                            try:
                                client.connect(BROKER_ADDRESS, BROKER_PORT, 60)
                                client.loop_start()
                                print(f"MQTT client for user {user_id} started.")
                                self.user_clients[user_id] = client
                                break
                            except Exception as e:
                                print(f"Błąd przy uruchomieniu klienta MQTT dla {user_id}: {e}")
                                print(f"Próba {attempt + 1} nie powiodła się: {e}")
                                time.sleep(2)
                    else:
                        client = self.user_clients[user_id]
                        client.disconnect()
                        client.username_pw_set(username=user_id, password=mqtt_password)
                        try:
                            client.reconnect()
                            print(f"MQTT client for user {user_id} reconnected with updated credentials.")
                        except Exception as e:
                            print(f"Błąd przy aktualizacji klienta MQTT dla {user_id}: {e}")

            elif change.type.name == "REMOVED":
                print(f"Dokument usunięty: {doc.id}")
                if user_id in self.user_clients:
                    client = self.user_clients[user_id]
                    client.loop_stop()
                    client.disconnect()
                    del self.user_clients[user_id]
                    print(f"MQTT client for user {user_id} stopped and removed.")

    def start_listening(self, collection_path):
        collection_ref = self.db.collection(collection_path)
        collection_ref.on_snapshot(self.on_mqtt_clients_snapshot)

    def monitor_heartbeats(self, check_interval=60, timeout=120):
        while True:
            now = datetime.utcnow()
            for board_id, last_time in self.last_heartbeat.items():
                if (now - last_time).total_seconds() > timeout and board_id not in self.lost_boards:
                    print(f"No heartbeat from board {board_id} since {last_time}, logging error.")
                    user_id = self.board_user_map.get(board_id)
                    log_entry = {
                        "timestamp": firestore.SERVER_TIMESTAMP,
                        "message": f"BRAK POŁĄCZENIA Z {board_id}",
                        "eventType": "connection_lost",
                        "device": 'Network',
                        "severity": "critical",
                        "boardId": board_id
                    }
                    if user_id:
                        self.db.collection("users").document(user_id) \
                            .collection("logs").add(log_entry)
                    else:
                        self.db.collection("logs").add(log_entry)
                    self.lost_boards.add(board_id)

            for board_id in list(self.lost_boards):
                if board_id in self.last_heartbeat:
                    time_since_last = (now - self.last_heartbeat[board_id]).total_seconds()
                    if time_since_last <= timeout:
                        print(f"Heartbeat restored for board {board_id}, removing from lost_boards.")
                        self.lost_boards.remove(board_id)

                        user_id = self.board_user_map.get(board_id)
                        log_entry = {
                            "timestamp": firestore.SERVER_TIMESTAMP,
                            "message": f"POŁĄCZENIE PRZYWRÓCONE Z {board_id}",
                            "eventType": "connection_restored",
                            "device": 'Network',
                            "severity": "info",
                            "boardId": board_id
                        }
                        if user_id:
                            self.db.collection("users").document(user_id) \
                                .collection("logs").add(log_entry)
                        else:
                            self.db.collection("logs").add(log_entry)
                        print(f"Connection restored log entry added for board {board_id}.")

            time.sleep(check_interval)


def restart_mosquitto():
    try:
        print("[INFO] Restarting Mosquitto service...")
        result = subprocess.run(
            ["brew", "services", "restart", "mosquitto"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            print("[INFO] Mosquitto service restarted successfully.")
        else:
            print(f"[ERROR] Failed to restart Mosquitto: {result.stderr}")
    except Exception as e:
        print(f"[ERROR] Exception occurred while restarting Mosquitto: {e}")
