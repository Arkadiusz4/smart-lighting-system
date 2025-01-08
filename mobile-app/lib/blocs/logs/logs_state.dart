import 'package:equatable/equatable.dart';
import 'package:mobile_app/models/log_entry.dart';

abstract class LogsState extends Equatable {
  const LogsState();
}

class LogsInitial extends LogsState {
  @override
  List<Object?> get props => [];
}

class LogsLoading extends LogsState {
  @override
  List<Object?> get props => [];
}

class LogsLoaded extends LogsState {
  final List<LogEntry> logs;

  const LogsLoaded(this.logs);

  @override
  List<Object?> get props => [logs];
}

class LogsError extends LogsState {
  final String message;

  const LogsError(this.message);

  @override
  List<Object?> get props => [message];
}
