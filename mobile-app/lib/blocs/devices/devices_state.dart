import 'package:equatable/equatable.dart';
import 'package:mobile_app/models/device.dart';

abstract class DevicesState extends Equatable {
  const DevicesState();

  @override
  List<Object?> get props => [];
}

class DevicesInitial extends DevicesState {}

class DevicesLoading extends DevicesState {}

class DevicesLoaded extends DevicesState {
  final List<Device> devices;

  const DevicesLoaded(this.devices);

  @override
  List<Object?> get props => [devices];
}

class DevicesError extends DevicesState {
  final String message;

  const DevicesError(this.message);

  @override
  List<Object?> get props => [message];
}
