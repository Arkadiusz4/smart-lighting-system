import json

import paho.mqtt.client as mqtt

BROKER_ADDRESS = "localhost"
BROKER_PORT = 1883


def create_on_message_callback(user_id):
    def on_message(client, userdata, msg):
        try:
            payload = msg.payload.decode()
            try:
                data = json.loads(payload)
                print(f"Client {user_id} received JSON on {msg.topic}: {data}")
            except json.JSONDecodeError:
                print(f"Client {user_id} received message on {msg.topic}: {payload}")
        except Exception as e:
            print(f"Client {user_id}: Error processing message: {e}")

    return on_message


def create_on_connect_callback(user_id, boardId):
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print(f"Client {user_id} connected to MQTT broker!")
            client.subscribe(f"boards/{boardId}/#")
        else:
            print(f"Client {user_id} connection failed with code: {rc}")

    return on_connect


class FirebaseMQTTListener:
    def __init__(self, db, mqtt_user_manager, acl_manager):
        self.db = db
        self.mqtt_user_manager = mqtt_user_manager
        self.acl_manager = acl_manager
        self.user_clients = {}

    def start_listening(self, collection_path):
        collection_ref = self.db.collection(collection_path)
        collection_ref.on_snapshot(self.on_mqtt_clients_snapshot)

    def on_mqtt_clients_snapshot(self, col_snapshot, changes, read_time):
        for change in changes:
            doc = change.document
            data = doc.to_dict()
            user_id = data.get("userId")
            mqtt_password = data.get("mqtt_password")
            board_id = data.get("boardId")
            topic = f"boards/{board_id}/#"

            if change.type.name in ("ADDED", "MODIFIED"):
                print(f"Aktualizacja lub dodanie użytkownika: {user_id}")
                if user_id and mqtt_password:
                    self.mqtt_user_manager.add_or_update_user(user_id, mqtt_password)
                    self.acl_manager.add_or_update_rule(user_id, topic, permission="readwrite")

                    if user_id not in self.user_clients:
                        client = mqtt.Client(client_id=f"client_{user_id}")
                        client.username_pw_set(username=user_id, password=mqtt_password)
                        client.on_connect = create_on_connect_callback(user_id, board_id)
                        client.on_message = create_on_message_callback(user_id)
                        try:
                            client.connect(BROKER_ADDRESS, BROKER_PORT, 60)
                            client.loop_start()
                            print(f"MQTT client for user {user_id} started.")
                            self.user_clients[user_id] = client
                        except Exception as e:
                            print(f"Błąd przy uruchomieniu klienta MQTT dla {user_id}: {e}")
                    else:
                        client = self.user_clients[user_id]
                        client.disconnect()
                        client.username_pw_set(username=user_id, password=mqtt_password)
                        try:
                            client.reconnect()
                            print(f"MQTT client for user {user_id} reconnected with updated credentials.")
                        except Exception as e:
                            print(f"Błąd przy aktualizacji klienta MQTT dla {user_id}: {e}")

                    # self.user_clients[user_id].subscribe(f"some/topic/for/{user_id}")
            elif change.type.name == "REMOVED":
                print(f"Dokument usunięty: {doc.id}")
                if user_id in self.user_clients:
                    client = self.user_clients[user_id]
                    client.loop_stop()
                    client.disconnect()
                    del self.user_clients[user_id]
                    print(f"MQTT client for user {user_id} stopped and removed.")
