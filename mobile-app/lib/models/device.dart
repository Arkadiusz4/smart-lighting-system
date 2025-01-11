class Device {
  final String deviceId;
  final String name;
  final String type;
  final String port;
  final String boardId;
  final String? status;

  Device({
    required this.deviceId,
    required this.name,
    required this.type,
    required this.port,
    required this.boardId,
    this.status,
  });

  Device copyWith({
    String? deviceId,
    String? name,
    String? type,
    String? port,
    String? boardId,
    String? status,
  }) {
    return Device(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      type: type ?? this.type,
      port: port ?? this.port,
      boardId: boardId ?? this.boardId,
      status: status ?? this.status,
    );
  }
}
