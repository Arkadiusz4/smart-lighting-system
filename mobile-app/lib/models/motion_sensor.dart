import 'device.dart';

class MotionSensor extends Device {
  final int ledOnDuration;
  final int pirCooldownTime;

  MotionSensor({
    required super.deviceId,
    required super.name,
    required super.type,
    required super.port,
    required super.boardId,
    super.status,
    required this.ledOnDuration,
    required this.pirCooldownTime,
  });

  factory MotionSensor.fromDevice(Device device,
      {required int ledOnDuration, required int pirCooldownTime}) {
    return MotionSensor(
      deviceId: device.deviceId,
      name: device.name,
      type: device.type,
      port: device.port,
      boardId: device.boardId,
      status: device.status,
      ledOnDuration: ledOnDuration,
      pirCooldownTime: pirCooldownTime,
    );
  }
}
