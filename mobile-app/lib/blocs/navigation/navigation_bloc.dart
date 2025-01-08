import 'package:bloc/bloc.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState(selectedIndex: 0)) {
    on<PageTapped>((event, emit) {
      emit(NavigationState(selectedIndex: event.index));
    });
  }
}
