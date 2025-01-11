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
      await boardsRepository.updateBoard(userId, event.boardId, event.newName, event.newRoom);

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
      await boardsRepository.removeBoard(userId, event.boardId);

      await logsRepository.addLogEntry(LogEntry(
        timestamp: DateTime.now(),
        message: 'Usunięto board: ${event.boardId}',
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
    } catch (e) {
      emit(BoardsError(e.toString()));
    }
  }

  Future<void> _onAddBoard(AddBoard event, Emitter<BoardsState> emit) async {
    try {
      await boardsRepository.addBoard(userId, event.boardId, event.name, event.room);

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
