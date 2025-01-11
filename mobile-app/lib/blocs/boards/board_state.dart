import 'package:equatable/equatable.dart';
import 'package:mobile_app/models/board.dart';

abstract class BoardsState extends Equatable {
  const BoardsState();

  @override
  List<Object?> get props => [];
}

class BoardsInitial extends BoardsState {}

class BoardsLoading extends BoardsState {}

class BoardsLoaded extends BoardsState {
  final List<Board> boards;
  final String? currentBoardId;

  const BoardsLoaded({
    required this.boards,
    this.currentBoardId,
  });

  @override
  List<Object?> get props => [boards, currentBoardId];
}

class BoardsError extends BoardsState {
  final String message;

  const BoardsError(this.message);

  @override
  List<Object?> get props => [message];
}
