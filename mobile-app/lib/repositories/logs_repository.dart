import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/models/log_entry.dart';

class LogsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<LogEntry>> fetchLogsFromAllBoards(String userId, {DateTime? since}) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('logs')
          .orderBy('timestamp', descending: true);

      if (since != null) {
        Timestamp timestampSince = Timestamp.fromDate(since);
        query = query.where('timestamp', isGreaterThanOrEqualTo: timestampSince);
      }

      final logsSnapshot = await query.get();

      return logsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return LogEntry(
          timestamp: (data?['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          message: data?['message'] ?? '',
          device: data?['device'] ?? '',
          boardId: data?['boardId'] ?? '',
          userId: data?['userId'] ?? '',
          severity: data?['severity'] ?? 'info',
          status: data?['status'],
          wifiStatus: data?['wifiStatus'],
          eventType: data?['eventType'],
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
