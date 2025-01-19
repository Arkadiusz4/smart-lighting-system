import json


def publish_device_update(mqtt_client, board_id, device_id, device_data):
    topic = f"boards/{board_id}/devices/{device_id}"

    payload_data = {
        "status": device_data.get("status", "unknown"),
        "deviceId": device_id,
        "port": device_data.get("port", "unknown"),
        "type": device_data.get("type", "unknown"),
    }

    # Jeśli typ to "Sensor ruchu", dodaj dodatkowe pola
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

        elif change.type.name == "REMOVED":
            device_id = change.document.id
            print(f"Device removed: {device_id}")

            # Publikujemy JSON z "status": "removed"
            topic = f"boards/{board_id}/devices/{device_id}"
            payload = json.dumps({
                "deviceId": device_id,
                "status": "removed"
            })
            mqtt_client.publish(topic, payload)
            print(f"Published 'removed' for {device_id}: {payload}")
