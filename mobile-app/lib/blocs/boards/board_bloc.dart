import 'package:bloc/bloc.dart';
import 'package:mobile_app/blocs/boards/board_event.dart';
import 'package:mobile_app/blocs/boards/board_state.dart';
import 'package:mobile_app/models/log_entry.dart';
import 'package:mobile_app/repositories/boards_repository.dart';
import 'package:mobile_app/repositories/logs_repository.dart';

class BoardsBloc extends Bloc<BoardsEvent, BoardsState> {
  final BoardsRepository boardsRepository;
  final String userId;
  final LogsRepository logsRepository;

  BoardsBloc({
    required this.boardsRepository,
    required this.userId,
    required this.logsRepository,
  }) : super(BoardsInitial()) {
    on<LoadBoards>(_onLoadBoards);
    on<EditBoard>(_onEditBoard);
    on<RemoveBoard>(_onRemoveBoard);
    on<AddBoard>(_onAddBoard);
    on<AddPeripheralBoard>(_onAddPeripheralBoard);
  }

  Future<void> _onLoadBoards(LoadBoards event, Emitter<BoardsState> emit) async {
    emit(BoardsLoading());
    try {
      final boards = await boardsRepository.fetchBoards(userId);

      final defaultBoardId = boards.isNotEmpty ? boards.first.boardId : null;

      emit(BoardsLoaded(
        boards: boards,
        currentBoardId: defaultBoardId,
      ));
    } catch (e) {
      emit(BoardsError(e.toString()));
    }
  }

  void _onSelectBoard(SelectBoard event, Emitter<BoardsState> emit) {
    final currentState = state;
    if (currentState is BoardsLoaded) {
      emit(BoardsLoaded(
        boards: currentState.boards,
        currentBoardId: event.boardId,
      ));
    }
  }

  Future<void> _onEditBoard(EditBoard event, Emitter<BoardsState> emit) async {
    try {
      await boardsRepository.updateBoard(event.boardId, event.newName, event.newRoom);

      await logsRepository.addLogEntry(LogEntry(
        timestamp: DateTime.now(),
        message: 'Zedytowano board: ${event.newName}',
        device: 'Board',
        boardId: event.boardId,
        userId: userId,
        severity: 'info',
        status: null,
        wifiStatus: null,
        eventType: 'edit_board',
      ));

      final boards = await boardsRepository.fetchBoards(userId);
      final defaultBoardId = boards.isNotEmpty ? boards.first.boardId : null;

      emit(BoardsLoaded(
        boards: boards,
        currentBoardId: defaultBoardId,
      ));
    } catch (e) {
      emit(BoardsError(e.toString()));
    }
  }

  Future<void> _onRemoveBoard(RemoveBoard event, Emitter<BoardsState> emit) async {
    try {
      if(event.isPeripheral){

        await boardsRepository.removeDevices(event.boardId);

        await boardsRepository.removeBoard(event.boardId);

        await logsRepository.addLogEntry(LogEntry(
          timestamp: DateTime.now(),
          message: 'Usunięto board: ${event.boardName}',
          device: 'Board',
          boardId: event.boardId,
          userId: userId,
          severity: 'info',
          status: null,
          wifiStatus: null,
          eventType: 'remove_board',
        ));
        final boards = await boardsRepository.fetchBoards(userId);
        final defaultBoardId = boards.isNotEmpty ? boards.first.boardId : null;

        emit(BoardsLoaded(
          boards: boards,
          currentBoardId: defaultBoardId,
        ));
      }
      else {
        await boardsRepository.unassignBoard(event.boardId, event.userId);

        await logsRepository.addLogEntry(LogEntry(
          timestamp: DateTime.now(),
          message: 'Usunięto board: ${event.boardName}',
          device: 'Board',
          boardId: event.boardId,
          userId: userId,
          severity: 'info',
          status: null,
          wifiStatus: null,
          eventType: 'unassign_board',
        ));

        final boards = await boardsRepository.fetchBoards(userId);
        final defaultBoardId = boards.isNotEmpty ? boards.first.boardId : null;

        emit(BoardsLoaded(
          boards: boards,
          currentBoardId: defaultBoardId,
        ));
      }
    } catch (e) {
      emit(BoardsError(e.toString()));
    }
  }

  Future<void> _onAddBoard(AddBoard event, Emitter<BoardsState> emit) async {
    try {
      await boardsRepository.registerBoard(
        userId: userId,
        boardId: event.boardId,
        name: event.name,
        room: event.room,
        peripheral: event.peripheral,
      );

      await logsRepository.addLogEntry(LogEntry(
        timestamp: DateTime.now(),
        message: 'Dodano board: ${event.name}',
        device: 'Board',
        boardId: event.boardId,
        userId: userId,
        severity: 'info',
        status: null,
        wifiStatus: null,
        eventType: 'add_board',
      ));

      final boards = await boardsRepository.fetchBoards(userId);
      final defaultBoardId = boards.isNotEmpty ? boards.first.boardId : null;

      emit(BoardsLoaded(
        boards: boards,
        currentBoardId: defaultBoardId,
      ));
    } catch (e) {
      emit(BoardsError(e.toString()));
    }
  }

  Future<void> _onAddPeripheralBoard(AddPeripheralBoard event, Emitter<BoardsState> emit) async {
    try {
      await boardsRepository.registerPeripheralBoard(
        userId: userId,
        boardId: event.boardId,
        name: event.name,
        room: event.room,
        peripheral: event.peripheral,
      );

      await logsRepository.addLogEntry(LogEntry(
        timestamp: DateTime.now(),
        message: 'Dodano board: ${event.name}',
        device: 'Board',
        boardId: event.boardId,
        userId: userId,
        severity: 'info',
        status: null,
        wifiStatus: null,
        eventType: 'add_board',
      ));

      final boards = await boardsRepository.fetchBoards(userId);
      final defaultBoardId = boards.isNotEmpty ? boards.first.boardId : null;

      emit(BoardsLoaded(
        boards: boards,
        currentBoardId: defaultBoardId,
      ));
    } catch (e) {
      emit(BoardsError(e.toString()));
    }
  }
}
