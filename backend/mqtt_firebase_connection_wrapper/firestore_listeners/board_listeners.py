def on_boards_snapshot(col_snapshot, changes, read_time, db, device_listeners):
    for change in changes:
        if change.type.name == "ADDED":
            board_id = change.document.id
            print(f"New board added: {board_id}")
            devices_ref = db.collection(f"boards/{board_id}/devices")
            from .device_listeners import on_devices_snapshot
            device_listeners[board_id] = devices_ref.on_snapshot(on_devices_snapshot)
            print(f"Subscribed to devices for board: {board_id}")
        elif change.type.name == "REMOVED":
            board_id = change.document.id
            print(f"Board removed: {board_id}")
            if board_id in device_listeners:
                device_listeners[board_id].unsubscribe()
                del device_listeners[board_id]
                print(f"Unsubscribed from devices for board: {board_id}")
