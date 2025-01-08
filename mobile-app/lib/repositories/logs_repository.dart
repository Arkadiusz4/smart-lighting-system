import 'dart:async';
import 'package:mobile_app/models/log_entry.dart';

class LogsRepository {
  Future<List<LogEntry>> fetchLogs({DateTime? since}) async {
    await Future.delayed(const Duration(seconds: 1));

    List<LogEntry> allLogs = [
      LogEntry(
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        message: 'LED1 turned on',
        device: 'LED',
        boardId: 'ESP32_1',
      ),
      LogEntry(
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        message: 'Motion detected',
        device: 'Motion Sensor',
        boardId: 'ESP32_1',
      ),
      LogEntry(
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        message: 'LED2 turned off',
        device: 'LED',
        boardId: 'ESP32_2',
      ),
      LogEntry(
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        message: 'LED3 brightness changed',
        device: 'LED',
        boardId: 'ESP32_2',
      ),
      LogEntry(
        timestamp: DateTime.now().subtract(const Duration(days: 30)),
        message: 'System rebooted',
        device: 'System',
        boardId: 'ESP32_1',
      ),
    ];

    if (since != null) {
      return allLogs.where((log) => log.timestamp.isAfter(since)).toList();
    }
    return allLogs;
  }
}
