import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/models/device.dart';

import '../models/motion_sensor.dart';

class DevicesRepository {
  final String boardId;

  DevicesRepository({
    required this.boardId,
  });

  CollectionReference get _devicesCollection =>
      FirebaseFirestore.instance.collection('boards').doc(boardId).collection('devices');

  Future<List<Device>> fetchDevices() async {
    final snapshot = await _devicesCollection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Check if the device is a MotionSensor
      if (data['type'] == 'motion_sensor') {
        return MotionSensor(
          deviceId: doc.id,
          name: data['name'] ?? '',
          type: data['type'] ?? '',
          port: data['port'] ?? '',
          boardId: boardId,
          status: data['status'],
          ledOnDuration: data['led_on_duration'] ?? 0,
          pirCooldownTime: data['pir_cooldown_time'] ?? 0,
        );
      }

      // Generic device with extra fields
      return Device(
        deviceId: doc.id,
        name: data['name'] ?? '',
        type: data['type'] ?? '',
        port: data['port'] ?? '',
        boardId: boardId,
        status: data['status'],
        extraFields: {
          'led_on_duration': data['led_on_duration'] ?? 0,
          'pir_cooldown_time': data['pir_cooldown_time'] ?? 0,
        }, // Assign extra fields here
      );
    }).toList();
  }

  Future<void> addDevice(Device device) async {
    // Prepare the data to be sent
    Map<String, dynamic> deviceData = {
      'name': device.name,
      'type': device.type,
      'port': device.port,
      'boardId': device.boardId,
      'status': device.status ?? 'off',
    };

    // Add extraFields if present
    if (device.extraFields != null) {
      deviceData.addAll(device.extraFields!);
    }

    // Send data to the Firestore collection
    await _devicesCollection.doc(device.deviceId).set(deviceData);
  }

  Future<void> updateDevice(
      String deviceId,
      String newName,
      String newType,
      String newPort, {
        Map<String, String>? extraFields, // Optional extraFields parameter
      }) async {
    // Prepare the update data
    final updateData = {
      'name': newName,
      'type': newType,
      'port': newPort,
    };

    // If extraFields are provided, merge them with the update data
    if (extraFields != null) {
      updateData.addAll(extraFields); // Merge extraFields into the update data
    }

    // Perform the update
    await _devicesCollection.doc(deviceId).update(updateData);
  }
  Future<void> removeDevice(String deviceId) async {
    await _devicesCollection.doc(deviceId).delete();
  }

  Future<void> toggleLed(String deviceId, bool status) async {
    print("toggleLed $deviceId $boardId");
    await _devicesCollection.doc(deviceId).update({
      'status': status ? 'on' : 'off',
    });
  }

  Future<void> toggleMotionSensor(String deviceId, bool status) async {
    print("toggleMotionSense $deviceId $boardId");
    await _devicesCollection.doc(deviceId).update({
      'status': status ? 'on' : 'off',
    });
  }
}
