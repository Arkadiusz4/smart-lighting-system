import 'package:bloc/bloc.dart';
import 'package:mobile_app/repositories/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;

  HomeBloc({required this.homeRepository}) : super(HomeLoading()) {
    on<LoadHomeData>((event, emit) async {
      emit(HomeLoading());
      try {
        final devicesByRoom = await homeRepository.fetchDevicesGroupedByRoom();
        emit(HomeLoaded(devicesByRoom));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });
  }
}
