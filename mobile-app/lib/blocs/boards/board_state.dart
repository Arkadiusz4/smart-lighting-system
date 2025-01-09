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

  const BoardsLoaded(this.boards);

  @override
  List<Object?> get props => [boards];
}

class BoardsError extends BoardsState {
  final String message;

  const BoardsError(this.message);

  @override
  List<Object?> get props => [message];
}
