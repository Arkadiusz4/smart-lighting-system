class LogEntry {
  final DateTime timestamp;
  final String message;
  final String device;
  final String boardId;

  LogEntry({
    required this.timestamp,
    required this.message,
    required this.device,
    required this.boardId,
  });
}
