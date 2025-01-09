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
}
