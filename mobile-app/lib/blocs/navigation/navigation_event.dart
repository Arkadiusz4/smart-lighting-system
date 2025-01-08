import 'package:equatable/equatable.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();
}

class PageTapped extends NavigationEvent {
  final int index;

  const PageTapped(this.index);

  @override
  List<Object?> get props => [index];
}
