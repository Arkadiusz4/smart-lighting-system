import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/models/log_entry.dart';

class LogsRepository {
  Future<List<LogEntry>> fetchLogsFromAllBoards(String userId) async {
    try {
      final boardsQuerySnapshot =
          await FirebaseFirestore.instance.collection('users').doc(userId).collection('boards').get();

      List<LogEntry> allLogs = [];

      for (var boardDoc in boardsQuerySnapshot.docs) {
        final boardId = boardDoc.id;

        final logsQuerySnapshot =
            await boardDoc.reference.collection('logs').orderBy('timestamp', descending: true).get();

        final mappedLogs = logsQuerySnapshot.docs.map((doc) {
          final data = doc.data();
          return LogEntry(
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            message: data['message'] ?? '',
            device: data['device'] ?? '',
            boardId: boardId,
            userId: userId,
            severity: data['severity'] ?? 'info',
            status: data['status'],
            wifiStatus: data['wifiStatus'],
          );
        }).toList();

        allLogs.addAll(mappedLogs);
      }

      return allLogs;
    } catch (e) {
      print('Error fetching logs from all boards: $e');
      throw Exception('Błąd pobierania logów ze wszystkich płytek: $e');
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
    final CollectionReference logsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(log.userId)
        .collection('boards')
        .doc(log.boardId)
        .collection('logs');

    await logsCollection.add({
      'timestamp': Timestamp.fromDate(log.timestamp),
      'message': log.message,
      'device': log.device,
      'severity': log.severity,
      'status': log.status,
      'wifiStatus': log.wifiStatus,
      'userId': log.userId,
    });
  }
}
