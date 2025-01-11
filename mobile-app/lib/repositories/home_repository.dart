import 'package:mobile_app/models/board.dart';
import 'package:mobile_app/models/device.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeRepository {
  final String userId;

  HomeRepository({required this.userId});

  Future<Map<String, List<Device>>> fetchDevicesGroupedByRoom() async {
    Map<String, List<Device>> devicesByRoom = {};

    final boardsSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).collection('boards').get();

    for (var boardDoc in boardsSnapshot.docs) {
      final boardData = boardDoc.data();
      final boardId = boardDoc.id;
      final room = boardData['room'] ?? 'Nieprzypisany pokój';

      final devicesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('boards')
          .doc(boardId)
          .collection('devices')
          .get();

      for (var deviceDoc in devicesSnapshot.docs) {
        final deviceData = deviceDoc.data();
        final device = Device(
          deviceId: deviceDoc.id,
          name: deviceData['name'] ?? '',
          type: deviceData['type'] ?? '',
          port: deviceData['port'] ?? '',
          boardId: deviceData['boardId'] ?? '',
        );

        devicesByRoom.putIfAbsent(room, () => []).add(device);
      }
    }

    return devicesByRoom;
  }
}
