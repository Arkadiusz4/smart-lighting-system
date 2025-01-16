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

  Future<void> unassignBoard(String boardId) async {
    try {
      await _firestore.collection('boards').doc(boardId).update({
        'status': 'available',
        'registered_at': null,
        'assigned_to': null,
        'name': null,
        'room': null,
      });
    } catch (e) {
      throw Exception('Error unassigning board: $e');
    }
  }
}
