import 'package:equatable/equatable.dart';
import 'package:mobile_app/models/device.dart';

abstract class DevicesEvent extends Equatable {
  const DevicesEvent();

  @override
  List<Object?> get props => [];
}

class LoadDevices extends DevicesEvent {}

class AddDevice extends DevicesEvent {
  final Device device;

  const AddDevice(this.device);

  @override
  List<Object?> get props => [device];
}

class UpdateDevice extends DevicesEvent {
  final String deviceId;
  final String newName;
  final String newType;
  final String newPort;
  final Map<String, dynamic>? extraFields; // Added extraFields parameter

  const UpdateDevice({
    required this.deviceId,
    required this.newName,
    required this.newType,
    required this.newPort,
    this.extraFields, // extraFields is optional
  });

  @override
  List<Object?> get props => [deviceId, newName, newType, newPort, extraFields]; // Include extraFields in props for equality checks
}
class RemoveDevice extends DevicesEvent {
  final String deviceId;
  final String deviceName;

  const RemoveDevice(this.deviceId, this.deviceName);

  @override
  List<Object?> get props => [deviceId];
}

class ToggleLed extends DevicesEvent {
  final String deviceId;
  final bool newStatus;
  final String deviceName;

  const ToggleLed(this.deviceId, this.newStatus, this.deviceName);

  @override
  List<Object?> get props => [deviceId, newStatus, deviceName];
}

class ToggleMotionSensor extends DevicesEvent {
  final String deviceId;
  final bool newStatus;
  final String deviceName;

  const ToggleMotionSensor(this.deviceId, this.newStatus, this.deviceName);

  @override
  List<Object?> get props => [deviceId, newStatus, deviceName];
}
