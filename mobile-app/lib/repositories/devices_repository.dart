import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/models/device.dart';

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
      return Device(
        deviceId: doc.id,
        name: data['name'] ?? '',
        type: data['type'] ?? '',
        port: data['port'] ?? '',
        boardId: boardId,
        status: data['status'],
      );
    }).toList();
  }

  Future<void> addDevice(Device device) async {
    await _devicesCollection.doc(device.deviceId).set({
      'name': device.name,
      'type': device.type,
      'port': device.port,
      'boardId': device.boardId,
      'status': device.status ?? 'off',
    });
  }

  Future<void> updateDevice(String deviceId, String newName, String newType, String newPort) async {
    await _devicesCollection.doc(deviceId).update({
      'name': newName,
      'type': newType,
      'port': newPort,
    });
  }

  Future<void> removeDevice(String deviceId) async {
    await _devicesCollection.doc(deviceId).delete();
  }

  Future<void> toggleLed(String deviceId, bool status) async {
    await _devicesCollection.doc(deviceId).update({
      'status': status ? 'on' : 'off',
    });
  }
}
