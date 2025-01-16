import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/models/log_entry.dart';

class LogsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<LogEntry>> fetchLogsFromAllBoards(String userId) async {
    try {
      final logsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .get();

      return logsSnapshot.docs.map((doc) {
        final data = doc.data();
        return LogEntry(
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          message: data['message'] ?? '',
          device: data['device'] ?? '',
          boardId: data['boardId'] ?? '',
          userId: data['userId'] ?? '',
          severity: data['severity'] ?? 'info',
          status: data['status'],
          wifiStatus: data['wifiStatus'],
          eventType: data['eventType'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching logs: $e');
      throw Exception('Błąd pobierania logów: $e');
    }
  }

  Future<List<LogEntry>> fetchLogs({DateTime? since, required String userId}) async {
    try {
      Query query = FirebaseFirestore.instance
          .collectionGroup('logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (since != null) {
        Timestamp timestampSince = Timestamp.fromDate(since);
        query = query.where('timestamp', isGreaterThanOrEqualTo: timestampSince);
      }

      final querySnapshot = await query.get();
      print('Fetched ${querySnapshot.docs.length} log(s) from Firestore.');
      print('Fetched ${querySnapshot.docs.length} log(s) from Firestore.');
      for (var doc in querySnapshot.docs) {
        print(doc.data());
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final extractedBoardId = doc.reference.parent.parent?.id ?? '';
        return LogEntry(
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          message: data['message'] ?? '',
          device: data['device'] ?? '',
          boardId: extractedBoardId,
          userId: data['userId'] ?? '',
          severity: data['severity'] ?? 'info',
          status: data['status'],
          wifiStatus: data['wifiStatus'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching logs: $e');
      throw Exception('Błąd pobierania logów: $e');
    }
  }

  Future<void> addLogEntry(LogEntry log) async {
    final CollectionReference logsCollection =
        FirebaseFirestore.instance.collection('users').doc(log.userId).collection('logs');

    await logsCollection.add({
      'timestamp': Timestamp.fromDate(log.timestamp),
      'message': log.message,
      'device': log.device,
      'boardId': log.boardId,
      'userId': log.userId,
      'severity': log.severity,
      'status': log.status,
      'wifiStatus': log.wifiStatus,
      'eventType': log.eventType,
    });
  }

  Future<void> addBoardLog(String boardId, LogEntry log) async {
    final CollectionReference logsCollection = _firestore.collection('boards').doc(boardId).collection('logs');

    await logsCollection.add({
      'timestamp': Timestamp.fromDate(log.timestamp),
      'message': log.message,
      'device': log.device,
      'boardId': log.boardId,
      'userId': log.userId,
      'severity': log.severity,
      'status': log.status,
      'wifiStatus': log.wifiStatus,
      'eventType': log.eventType,
    });
  }
}
