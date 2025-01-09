import 'package:equatable/equatable.dart';

abstract class BoardsEvent extends Equatable {
  const BoardsEvent();

  @override
  List<Object?> get props => [];
}

class LoadBoards extends BoardsEvent {}
