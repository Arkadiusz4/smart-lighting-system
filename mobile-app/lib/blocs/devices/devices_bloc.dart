import 'package:bloc/bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
import 'package:mobile_app/blocs/devices/devices_state.dart';
import 'package:mobile_app/models/log_entry.dart';
import 'package:mobile_app/repositories/devices_repository.dart';
import 'package:mobile_app/repositories/logs_repository.dart';

class DevicesBloc extends Bloc<DevicesEvent, DevicesState> {
  final DevicesRepository devicesRepository;
  final LogsRepository logsRepository;
  final String userId;
  final String boardId;

  DevicesBloc({
    required this.devicesRepository,
    required this.logsRepository,
    required this.userId,
    required this.boardId,
  }) : super(DevicesInitial()) {
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

        // Dodaj log dla dodania urządzenia
        await logsRepository.addLogEntry(LogEntry(
          timestamp: DateTime.now(),
          message: 'Dodano urządzenie: ${event.device.name}',
          device: 'Device',
          boardId: boardId,
          userId: userId,
          severity: 'info',
          status: null,
          wifiStatus: null,
          eventType: 'add_device',
        ));

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

        // Dodaj log dla edycji urządzenia
        await logsRepository.addLogEntry(LogEntry(
          timestamp: DateTime.now(),
          message: 'Zedytowano urządzenie: ${event.deviceId}',
          device: 'Device',
          boardId: boardId,
          userId: userId,
          severity: 'info',
          status: null,
          wifiStatus: null,
          eventType: 'edit_device',
        ));

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

        // Dodaj log dla usunięcia urządzenia
        await logsRepository.addLogEntry(LogEntry(
          timestamp: DateTime.now(),
          message: 'Usunięto urządzenie: ${event.deviceId}',
          device: 'Device',
          boardId: boardId,
          userId: userId,
          severity: 'info',
          status: null,
          wifiStatus: null,
          eventType: 'remove_device',
        ));

        final devices = await devicesRepository.fetchDevices();
        emit(DevicesLoaded(devices));
      } catch (e) {
        emit(DevicesError(e.toString()));
      }
    }
  }
}