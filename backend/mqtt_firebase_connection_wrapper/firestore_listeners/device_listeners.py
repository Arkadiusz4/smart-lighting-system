import json

from mqtt_firebase_connection_wrapper.firestore_listeners.shared_state import peripheral_boards


def publish_device_update(mqtt_client, board_id, device_id, device_data):
    topic = f"boards/{board_id}/devices/{device_id}"
    payload_data = {
        "status": device_data.get("status", "unknown"),
        "deviceId": device_id,
        "port": device_data.get("port", "unknown"),
        "type": device_data.get("type", "unknown"),
    }
    if device_data.get("type") == "Sensor ruchu":
        payload_data["pir_cooldown_time"] = device_data.get("pir_cooldown_time", "0")
        payload_data["led_on_duration"] = device_data.get("led_on_duration", "0")
    payload = json.dumps(payload_data)
    print(f"{mqtt_client}")
    mqtt_client.publish(topic, payload)
    print(f"Published to {topic} => {payload}")


def on_devices_snapshot(board_id, mqtt_client, col_snapshot, changes, read_time):
    for change in changes:
        device_id = change.document.id
        device_data = change.document.to_dict()

        if change.type.name == "ADDED":
            print(f"New device added: {device_id} => {device_data}")
            publish_device_update(mqtt_client, board_id, device_id, device_data)

        elif change.type.name == "MODIFIED":
            print(f"Device modified: {device_id} => {device_data}")
            publish_device_update(mqtt_client, board_id, device_id, device_data)

            if device_data.get("type") == "LED" and board_id in peripheral_boards:
                status = device_data.get("status")
                if status == "on":
                    print(f"Publishing LED ON command for peripheral device {device_id}")
                    mqtt_client.publish("central/command/led_on", device_id)
                elif status == "off":
                    print(f"Publishing LED OFF command for peripheral device {device_id}")
                    mqtt_client.publish("central/command/led_off", device_id)


        elif change.type.name == "REMOVED":
            device_id = change.document.id
            print(f"Device removed: {device_id}")
            topic = f"boards/{board_id}/devices/{device_id}"
            payload = json.dumps({
                "deviceId": device_id,
                "status": "removed"
            })
            mqtt_client.publish(topic, payload)
            print(f"Published 'removed' for {device_id}: {payload}")
