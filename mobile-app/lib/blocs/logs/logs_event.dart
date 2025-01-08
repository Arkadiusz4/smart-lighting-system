import 'package:equatable/equatable.dart';

abstract class LogsEvent extends Equatable {
  const LogsEvent();
}

class LoadLogs extends LogsEvent {
  final DateTime? since;

  const LoadLogs({this.since});

  @override
  List<Object?> get props => [since];
}
