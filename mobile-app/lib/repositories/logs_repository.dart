import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/models/log_entry.dart';

class LogsRepository {
  Future<List<LogEntry>> fetchLogs({DateTime? since, required String userId}) async {
    try {
      Query query = FirebaseFirestore.instance.collectionGroup('logs').orderBy('timestamp', descending: true);

      if (since != null) {
        Timestamp timestampSince = Timestamp.fromDate(since);
        query = query.where('timestamp', isGreaterThanOrEqualTo: timestampSince);
      }
      final querySnapshot = await query.get();

      print('Fetched ${querySnapshot.docs.length} log(s) from Firestore.');

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
}
