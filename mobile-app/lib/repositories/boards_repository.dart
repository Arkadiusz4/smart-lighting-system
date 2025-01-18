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
  }) async {
    print('Próba rejestracji boarda: $boardId dla użytkownika: $userId');
    final boardRef = _firestore.collection('boards').doc(boardId);
    final boardDoc = await boardRef.get();

    final mqttClientRef = _firestore
        .collection('mqtt_clients')
        .where('boardId', isEqualTo: boardId)
        .where('clientId', isEqualTo: userId);

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
      });
    }

    if (querySnapshot.docs.isEmpty) {
      // If no document matches the query, create a new mqtt_client document
      print("Klient nie istnieje, tworzenie nowego mqtt_clienta");
      await _firestore.collection('mqtt_clients').add({
        'boardId': boardId,
        'mqtt_password': '',
        'userId': userId,
      });
    } else {
      // If a document exists, process it
      final mqttClientDoc = querySnapshot.docs.first;
      final data = mqttClientDoc.data();
      print('MqttClient już istnieje: $data');

      if (data != null && data['userId'] != null && data['userId'] != userId) {
        // Throw an error if the device is already assigned to another user
        throw Exception('Urządzenie jest już przypisane do innego użytkownika.');
      }

      // Update the existing document
      await mqttClientDoc.reference.update({
        'mqtt_password': '',
        'userId': userId,
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

      final mqttClientRef = _firestore
          .collection('mqtt_clients')
          .where('boardId', isEqualTo: boardId)
          .where('userId', isEqualTo: userId);
          print("After query");
          print(boardId);
          print(userId);

      final querySnapshot = await mqttClientRef.get();
      if (querySnapshot.docs.isNotEmpty){
        final mqttClientDoc = querySnapshot.docs.first;
        print("Inside if");
        mqttClientDoc.reference.delete();
      }


      print('Board $boardId został unassignowany, a wszystkie urządzenia zostały usunięte.');
    } catch (e) {
      throw Exception('Error unassigning board: $e');
    }
  }
}
