class LogEntry {
  final DateTime timestamp;
  final String message;
  final String device;
  final String boardId;
  final String userId;
  final String severity;
  final String? status;
  final String? wifiStatus;
  final String? eventType;

  LogEntry({
    required this.timestamp,
    required this.message,
    required this.device,
    required this.boardId,
    required this.userId,
    required this.severity,
    this.status,
    this.wifiStatus,
    this.eventType,
  });
}
