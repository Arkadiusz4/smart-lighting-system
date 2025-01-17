def on_devices_snapshot(col_snapshot, changes, read_time):
    for change in changes:
        if change.type.name == "ADDED":
            print(f"New device added: {change.document.id} => {change.document.to_dict()}")
        elif change.type.name == "MODIFIED":
            print(f"Device modified: {change.document.id} => {change.document.to_dict()}")
        elif change.type.name == "REMOVED":
            print(f"Device removed: {change.document.id}")
