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
    on<ToggleLed>(_onToggleLed);
    on<ToggleMotionSensor>(_onToggleMotionSensor);
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

        await logsRepository.addLogEntry(LogEntry(
          timestamp: DateTime.now(),
          message: 'Dodano urządzenie: ${event.device.name}',
          device: 'Device',
          boardId: boardId,
          userId: userId,
          severity: 'info',
          status: event.device.status ?? 'off',
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
        // Convert extraFields to Map<String, String> if necessary
        final extraFields = event.extraFields?.map((key, value) {
          return MapEntry(key, value.toString()); // Ensure all values are strings
        });

        // Update the device in the repository, including extraFields if provided
        await devicesRepository.updateDevice(
          event.deviceId,
          event.newName,
          event.newType,
          event.newPort,
          extraFields: extraFields, // Pass extraFields
        );

        // Add a log entry
        await logsRepository.addLogEntry(LogEntry(
          timestamp: DateTime.now(),
          message: 'Zedytowano urządzenie: ${event.deviceId} z dodatkowymi polami ${event.extraFields}',
          device: 'Device',
          boardId: boardId,
          userId: userId,
          severity: 'info',
          status: null,
          eventType: 'edit_device',
        ));

        // Fetch updated devices and emit new state
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

        await logsRepository.addLogEntry(LogEntry(
          timestamp: DateTime.now(),
          message: 'Usunięto urządzenie: ${event.deviceId}',
          device: 'Device',
          boardId: boardId,
          userId: userId,
          severity: 'info',
          status: null,
          eventType: 'remove_device',
        ));

        final devices = await devicesRepository.fetchDevices();
        emit(DevicesLoaded(devices));
      } catch (e) {
        emit(DevicesError(e.toString()));
      }
    }
  }

  Future<void> _onToggleLed(ToggleLed event, Emitter<DevicesState> emit) async {
    if (state is DevicesLoaded) {
      try {
        print("_onToggleLed: $boardId");
        await devicesRepository.toggleLed(event.deviceId, event.newStatus);
        await logsRepository.addLogEntry(LogEntry(
          timestamp: DateTime.now(),
          message: event.newStatus ? 'Włączono LED: ${event.deviceId}' : 'Wyłączono LED: ${event.deviceId} $boardId' ,
          device: 'Device',
          boardId: boardId,
          userId: userId,
          severity: 'info',
          status: event.newStatus ? 'on' : 'off',
          eventType: event.newStatus ? 'led_on' : 'led_off',
        ));
        final devices = await devicesRepository.fetchDevices();
        emit(DevicesLoaded(devices));
      } catch (e) {
        print('Error in _onToggleLed: $e');
        emit(DevicesError(e.toString()));
      }
    }
  }

  Future<void> _onToggleMotionSensor(ToggleMotionSensor event, Emitter<DevicesState> emit) async {
    if (state is DevicesLoaded) {
      try {
        print("_onToggleMotionSensor: $boardId");
        await devicesRepository.toggleMotionSensor(event.deviceId, event.newStatus);
        await logsRepository.addLogEntry(LogEntry(
          timestamp: DateTime.now(),
          message: event.newStatus ? 'Włączono sensor ruchu: ${event.deviceId}' : 'Wyłączono sensor ruchu: ${event.deviceId} $boardId' ,
          device: 'Device',
          boardId: boardId,
          userId: userId,
          severity: 'info',
          status: event.newStatus ? 'on' : 'off',
          eventType: event.newStatus ? 'motion_sensor_on' : 'motion_sensor_off',
        ));
        final devices = await devicesRepository.fetchDevices();
        emit(DevicesLoaded(devices));
      } catch (e) {
        print('Error in _onToggleLed: $e');
        emit(DevicesError(e.toString()));
      }
    }
  }

}
