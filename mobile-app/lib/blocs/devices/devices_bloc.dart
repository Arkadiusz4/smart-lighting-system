import 'package:bloc/bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
import 'package:mobile_app/blocs/devices/devices_state.dart';
import 'package:mobile_app/repositories/devices_repository.dart';

class DevicesBloc extends Bloc<DevicesEvent, DevicesState> {
  final DevicesRepository devicesRepository;

  DevicesBloc({required this.devicesRepository}) : super(DevicesInitial()) {
    on<LoadDevices>(_onLoadDevices);
    on<AddDevice>(_onAddDevice);
    on<UpdateDevice>(_onUpdateDevice);
    on<RemoveDevice>(_onRemoveDevice);
  }

  Future<void> _onLoadDevices(LoadDevices event, Emitter<DevicesState> emit) async {
    emit(DevicesLoading());
    try {
      final devices = await devicesRepository.fetchDevices();
      emit(DevicesLoaded(devices));
    } catch (e) {
      emit(DevicesError(e.toString()));
    }
  }

  Future<void> _onAddDevice(AddDevice event, Emitter<DevicesState> emit) async {
    if (state is DevicesLoaded) {
      try {
        await devicesRepository.addDevice(event.device);
        final devices = await devicesRepository.fetchDevices();
        emit(DevicesLoaded(devices));
      } catch (e) {
        emit(DevicesError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateDevice(UpdateDevice event, Emitter<DevicesState> emit) async {
    if (state is DevicesLoaded) {
      try {
        await devicesRepository.updateDevice(event.deviceId, event.newName, event.newType, event.newPort);
        final devices = await devicesRepository.fetchDevices();
        emit(DevicesLoaded(devices));
      } catch (e) {
        emit(DevicesError(e.toString()));
      }
    }
  }

  Future<void> _onRemoveDevice(RemoveDevice event, Emitter<DevicesState> emit) async {
    if (state is DevicesLoaded) {
      try {
        await devicesRepository.removeDevice(event.deviceId);
        final devices = await devicesRepository.fetchDevices();
        emit(DevicesLoaded(devices));
      } catch (e) {
        emit(DevicesError(e.toString()));
      }
    }
  }
}
