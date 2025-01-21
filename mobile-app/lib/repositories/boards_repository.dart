import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/models/board.dart';

class BoardsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Pobiera boardy przypisane do konkretnego użytkownika.
  Future<List<Board>> fetchBoards(String userId) async {
    try {
      final snapshot = await _firestore.collection('boards').where('assigned_to', isEqualTo: userId).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Board(
          boardId: doc.id,
          name: data['name'] ?? '',
          room: data['room'] ?? '',
          peripheral: data['peripheral'] ?? false,
        );
      }).toList();
    } catch (e) {
      throw Exception('Błąd pobierania boardów: $e');
    }
  }

  /// Rejestruje board dla użytkownika, tworząc lub aktualizując dokument.
  Future<void> registerBoard({
    required String userId,
    required String boardId,
    required String name,
    required String room,
    required bool peripheral,
  }) async {
    print('Próba rejestracji boarda: $boardId dla użytkownika: $userId');
    final boardRef = _firestore.collection('boards').doc(boardId);
    final boardDoc = await boardRef.get();

    final mqttClientRef =
        _firestore.collection('mqtt_clients').where('boardId', isEqualTo: boardId).where('clientId', isEqualTo: userId);

    final querySnapshot = await mqttClientRef.get();

    if (!boardDoc.exists) {
      print('Board nie istnieje, tworzenie nowego dokumentu');

      await boardRef.set({
        'mac_address': boardId,
        'encryption_key': '',
        'status': 'assigned',
        'registered_at': FieldValue.serverTimestamp(),
        'assigned_to': userId,
        'name': name,
        'room': room,
        'peripheral': peripheral,
      });
      final devicesCollectionRef = boardRef.collection('devices');

      await devicesCollectionRef.add({
        'device_id': 'placeholder_device',
        'name': 'Placeholder Device',
        'status': 'inactive',
        'created_at': FieldValue.serverTimestamp(),
      });


    } else {
      final data = boardDoc.data();
      print('Board już istnieje: $data');
      if (data != null && data['assigned_to'] != null) {
        throw Exception('Urządzenie jest już przypisane do innego użytkownika.');
      }
      print('Aktualizacja istniejącego boarda');
      await boardRef.update({
        'status': 'assigned',
        'registered_at': FieldValue.serverTimestamp(),
        'assigned_to': userId,
        'name': name,
        'room': room,
        'peripheral':peripheral,
      });
      final devicesCollectionRef = boardRef.collection('devices');

      await devicesCollectionRef.add({
        'device_id': 'placeholder_device',
        'name': 'Placeholder Device',
        'status': 'inactive',
        'created_at': FieldValue.serverTimestamp(),
      });

    }

    if (querySnapshot.docs.isEmpty) {
      print("Klient nie istnieje, tworzenie nowego mqtt_clienta");
      final mqttPassword = generateMqttPassword(16);
      await _firestore.collection('mqtt_clients').add({
        'boardId': boardId,
        'mqtt_password': mqttPassword,
        'userId': userId,
      });
    } else {
      final mqttClientDoc = querySnapshot.docs.first;
      final data = mqttClientDoc.data();
      print('MqttClient już istnieje: $data');

      if (data['userId'] != null && data['userId'] != userId) {
        throw Exception('Urządzenie jest już przypisane do innego użytkownika.');
      }

      await mqttClientDoc.reference.update({
        'mqtt_password': '',
        'userId': userId,
      });
    }
  }

  Future<void> registerPeripheralBoard({
    required String userId,
    required String boardId,
    required String name,
    required String room,
    required bool peripheral,
  }) async {
    print('Attempting to register peripheral board: $boardId for user: $userId');

    final boardRef = _firestore.collection('boards').doc(boardId);

    final boardDoc = await boardRef.get();

    if (!boardDoc.exists) {
      print('Board does not exist, creating a new document');
      await boardRef.set({
        'peripheral_id': boardId,
        'status': 'assigned',
        'registered_at': FieldValue.serverTimestamp(),
        'assigned_to': userId,
        'name': name,
        'room': room,
        'peripheral': peripheral,
      });
    } else {
      final data = boardDoc.data();
      print('Board already exists: $data');
      if (data != null && data['assigned_to'] != null) {
        throw Exception('The device is already assigned to another user.');
      }
      print('Updating existing board');
      await boardRef.update({
        'status': 'assigned',
        'registered_at': FieldValue.serverTimestamp(),
        'assigned_to': userId,
        'name': name,
        'room': room,
      });
    }
  }

  Future<void> updateBoard(String boardId, String newName, String newRoom) async {
    try {
      await _firestore.collection('boards').doc(boardId).update({
        'name': newName,
        'room': newRoom,
      });
    } catch (e) {
      throw Exception('Error updating board: $e');
    }
  }

  Future<void> removeBoard(String boardId) async {
    try {
      await _firestore.collection('boards').doc(boardId).delete();
    } catch (e) {
      throw Exception('Error removing board: $e');
    }
  }

  Future<void> removeDevices(String boardId) async {
    try {
      CollectionReference devicesRef = _firestore.collection('boards').doc(boardId).collection('devices');

      QuerySnapshot devicesSnapshot = await devicesRef.get();

      for (DocumentSnapshot doc in devicesSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Error unassigning board: $e');
    }
  }

  Future<void> unassignBoard(String boardId, String userId) async {
    try {
      CollectionReference devicesRef = _firestore.collection('boards').doc(boardId).collection('devices');

      QuerySnapshot devicesSnapshot = await devicesRef.get();

      for (DocumentSnapshot doc in devicesSnapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('boards').doc(boardId).update({
        'status': 'available',
        'registered_at': null,
        'assigned_to': null,
        'name': null,
        'room': null,
      });

      final mqttClientRef =
          _firestore.collection('mqtt_clients').where('boardId', isEqualTo: boardId).where('userId', isEqualTo: userId);
      print("After query");
      print(boardId);
      print(userId);

      final querySnapshot = await mqttClientRef.get();
      if (querySnapshot.docs.isNotEmpty) {
        final mqttClientDoc = querySnapshot.docs.first;
        print("Inside if");
        mqttClientDoc.reference.delete();
      }

      print('Board $boardId został unassignowany, a wszystkie urządzenia zostały usunięte.');
    } catch (e) {
      throw Exception('Error unassigning board: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchMqttClient(String boardId, String userId) async {
    final snapshot = await _firestore
        .collection('mqtt_clients')
        .where('boardId', isEqualTo: boardId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }

  Future<String?> fetchBoardForUserId(String userId) async {
    final doc = await _firestore.collection('boards').doc(userId).get();
    if (!doc.exists) return null;

    return doc.data()?['boardId'] as String?;
  }

  String generateMqttPassword(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
}
