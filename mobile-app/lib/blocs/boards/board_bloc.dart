import 'package:bloc/bloc.dart';
import 'package:mobile_app/blocs/boards/board_event.dart';
import 'package:mobile_app/blocs/boards/board_state.dart';
import 'package:mobile_app/repositories/boards_repository.dart';

class BoardsBloc extends Bloc<BoardsEvent, BoardsState> {
  final BoardsRepository boardsRepository;
  final String userId;

  BoardsBloc({
    required this.boardsRepository,
    required this.userId,
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
      emit(BoardsLoaded(boards));
    } catch (e) {
      emit(BoardsError(e.toString()));
    }
  }

  Future<void> _onEditBoard(EditBoard event, Emitter<BoardsState> emit) async {
    try {
      await boardsRepository.updateBoard(userId, event.boardId, event.newName, event.newRoom);
      final boards = await boardsRepository.fetchBoards(userId);
      emit(BoardsLoaded(boards));
    } catch (e) {
      emit(BoardsError(e.toString()));
    }
  }

  Future<void> _onRemoveBoard(RemoveBoard event, Emitter<BoardsState> emit) async {
    try {
      await boardsRepository.removeBoard(userId, event.boardId);
      final boards = await boardsRepository.fetchBoards(userId);
      emit(BoardsLoaded(boards));
    } catch (e) {
      emit(BoardsError(e.toString()));
    }
  }

  Future<void> _onAddBoard(AddBoard event, Emitter<BoardsState> emit) async {
    try {
      await boardsRepository.addBoard(userId, event.boardId, event.name, event.room);
      final boards = await boardsRepository.fetchBoards(userId);
      emit(BoardsLoaded(boards));
    } catch (e) {
      emit(BoardsError(e.toString()));
    }
  }
}
