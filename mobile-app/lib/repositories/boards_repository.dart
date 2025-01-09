import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/models/board.dart';

class BoardsRepository {
  Future<List<Board>> fetchBoards(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(userId).collection('boards').get();

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
}
