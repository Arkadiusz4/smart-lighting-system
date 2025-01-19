import paho.mqtt.client as mqtt


def on_boards_snapshot(col_snapshot, changes, read_time, db, device_listeners):
    for change in changes:
        if change.type.name == "ADDED":
            board_id = change.document.id
            print(f"New board added: {board_id}")

            devices_ref = db.collection(f"boards/{board_id}/devices")
            from .device_listeners import on_devices_snapshot

            board_ref = db.collection("boards").document(board_id)
            board_data = board_ref.get().to_dict()
            if not board_data:
                print(f"[WARNING] board {board_id} has no data or doesn't exist.")
                continue

            print(f"Board data: {board_data}")
            username = board_data.get("assigned_to")
            if not username:
                print(f"[WARNING] board {board_id} has no 'userId'. Skipping.")
                continue

            mqtt_ref = db.collection("mqtt_clients").where("userId", "==", username).limit(1)
            mqtt_docs = mqtt_ref.get()

            if not mqtt_docs:
                print(f"[WARNING] No matching user found in mqtt_clients for userId = {username}")
                continue

            mqtt_ref_data = mqtt_docs[0].to_dict()
            password = mqtt_ref_data.get("mqtt_password")
            if not password:
                print(f"[WARNING] Document in mqtt_clients for userId={username} has no 'mqtt_password'.")
                continue

            mqtt_client = mqtt.Client()
            mqtt_client.username_pw_set(username=username, password=password)

            def on_connect(client, userdata, flags, rc):
                if rc == 0:
                    print(f"Klient {username} połączony z brokerem, można publikować.")
                else:
                    print(f"Błąd połączenia MQTT: {rc}")

            mqtt_client.on_connect = on_connect

            mqtt_client.connect("192.168.0.145", 2137, 60)
            mqtt_client.loop_start()

            from .device_listeners import on_devices_snapshot
            device_listeners[board_id] = devices_ref.on_snapshot(
                lambda col_snapshot, changes, read_time: on_devices_snapshot(
                    board_id, mqtt_client, col_snapshot, changes, read_time
                )
            )
            print(f"Subscribed to devices for board: {board_id}")

        elif change.type.name == "REMOVED":
            board_id = change.document.id
            print(f"Board removed: {board_id}")
            if board_id in device_listeners:
                device_listeners[board_id].unsubscribe()
                del device_listeners[board_id]
                print(f"Unsubscribed from devices for board: {board_id}")
