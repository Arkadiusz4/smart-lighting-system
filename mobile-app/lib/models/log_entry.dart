class LogEntry {
  final DateTime timestamp;
  final String message;
  final String device;
  final String boardId;
  final String userId;
  final String severity;
  final String? status;
  final String? wifiStatus;

  LogEntry({
    required this.timestamp,
    required this.message,
    required this.device,
    required this.boardId,
    required this.userId,
    this.severity = 'info',
    this.status,
    this.wifiStatus,
  });
}
