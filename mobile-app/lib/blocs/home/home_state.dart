import 'package:mobile_app/models/device.dart';

abstract class HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final Map<String, List<Device>> devicesByRoom;

  HomeLoaded(this.devicesByRoom);
}

class HomeError extends HomeState {
  final String message;

  HomeError(this.message);
}
