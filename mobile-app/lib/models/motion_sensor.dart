import 'device.dart';

class MotionSensor extends Device {
final int ledOnDuration;
final int pirCooldownTime;

MotionSensor({
required String deviceId,
required String name,
required String type,
required String port,
required String boardId,
String? status,
required this.ledOnDuration,
required this.pirCooldownTime,
}) : super(
deviceId: deviceId,
name: name,
type: type,
port: port,
boardId: boardId,
status: status,
);

factory MotionSensor.fromDevice(Device device, {required int ledOnDuration, required int pirCooldownTime}) {
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
