import 'package:equatable/equatable.dart';

abstract class BoardsEvent extends Equatable {
  const BoardsEvent();

  @override
  List<Object?> get props => [];
}

class LoadBoards extends BoardsEvent {}

class EditBoard extends BoardsEvent {
  final String boardId;
  final String newName;
  final String newRoom;

  const EditBoard({
    required this.boardId,
    required this.newName,
    required this.newRoom,
  });

  @override
  List<Object?> get props => [boardId, newName, newRoom];
}

class RemoveBoard extends BoardsEvent {
  final String boardId;
  final String userId;

  const RemoveBoard(this.boardId, this.userId);

  @override
  List<Object?> get props => [boardId, userId];
}

class AddBoard extends BoardsEvent {
  final String boardId;
  final String name;
  final String room;

  const AddBoard({
    required this.boardId,
    required this.name,
    required this.room,
  });

  @override
  List<Object?> get props => [boardId, name, room];
}

class SelectBoard extends BoardsEvent {
  final String boardId;

  const SelectBoard(this.boardId);

  @override
  List<Object?> get props => [boardId];
}
