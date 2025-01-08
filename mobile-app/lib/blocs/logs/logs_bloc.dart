import 'package:bloc/bloc.dart';
import 'package:mobile_app/blocs/logs/logs_event.dart';
import 'package:mobile_app/blocs/logs/logs_state.dart';
import 'package:mobile_app/repositories/logs_repository.dart';

class LogsBloc extends Bloc<LogsEvent, LogsState> {
  final LogsRepository logsRepository;

  LogsBloc({required this.logsRepository}) : super(LogsInitial()) {
    on<LoadLogs>(_onLoadLogs);
  }

  Future<void> _onLoadLogs(LoadLogs event, Emitter<LogsState> emit) async {
    emit(LogsLoading());
    try {
      final logs = await logsRepository.fetchLogs(since: event.since);
      emit(LogsLoaded(logs));
    } catch (e) {
      emit(LogsError(e.toString()));
    }
  }
}
