import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
import 'package:mobile_app/blocs/devices/devices_state.dart';
import 'package:mobile_app/models/device.dart';
import 'package:mobile_app/models/motion_sensor.dart';
import 'package:mobile_app/repositories/devices_repository.dart';
import 'package:mobile_app/repositories/logs_repository.dart';
import 'package:mobile_app/styles/color.dart';
import 'package:mobile_app/screens/home_screen/led_switch.dart';
import 'motion_sensor.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final Map<String, String> boardRoomMapping;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.boardRoomMapping,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<DevicesBloc> devicesBlocs;

  @override
  void initState() {
    super.initState();
    print(widget.boardRoomMapping);
    devicesBlocs = widget.boardRoomMapping.keys.map((boardId) {
      final repository = DevicesRepository(boardId: boardId);
      return DevicesBloc(
        devicesRepository: repository,
        logsRepository: LogsRepository(),
        userId: widget.userId,
        boardId: boardId,
      )..add(LoadDevices());
    }).toList();
  }

  @override
  void dispose() {
    for (final bloc in devicesBlocs) {
      bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<DevicesBloc>> groupedByRoom = {};
    for (final bloc in devicesBlocs) {
      final boardId = bloc.boardId;
      final room = widget.boardRoomMapping[boardId] ?? 'Nieznany pokój';
      groupedByRoom.putIfAbsent(room, () => []).add(bloc);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ekran Główny',
          style: TextStyle(
            color: textColor,
            fontSize: 24.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: darkBackground,
      ),
      body: MultiBlocProvider(
        providers: devicesBlocs.map((bloc) => BlocProvider<DevicesBloc>.value(value: bloc)).toList(),
        child: ListView(
          children: groupedByRoom.entries.map((entry) {
            final roomName = entry.key;
            final roomBlocs = entry.value;

            return Card(
              margin: const EdgeInsets.all(8.0),
              color: darkBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
                side: const BorderSide(color: primaryColor, width: 2.0),
              ),
              elevation: 5,
              shadowColor: primaryColor.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ExpansionTile(
                  leading: Icon(getRoomIcon(roomName), color: primaryColor),
                  title: Text(
                    roomName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  children: roomBlocs.map((bloc) {
                    return BlocBuilder<DevicesBloc, DevicesState>(
                      bloc: bloc,
                      builder: (context, state) {
                        if (state is DevicesLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (state is DevicesLoaded) {
                          if (state.devices.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(15.0),
                              child: Center(
                                child: Text(
                                  'Brak urządzeń.',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: state.devices.map((Device device) {
                              print(device.type);
                              if (device.type.toLowerCase() == 'led') {
                                return ExpansionTile(
                                  leading: Icon(getDeviceIcon(device.type), color: primaryColor),
                                  title: Text(
                                    device.name,
                                    style: const TextStyle(
                                      color: textColor,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Port: ${device.port}, status: ${device.status ?? 'off'}',
                                    style: const TextStyle(
                                      color: textColor,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  children: [
                                    LedSwitch(
                                      device: device,
                                      userId: widget.userId,
                                      devicesBloc: bloc,
                                    ),
                                  ],
                                );
                              } else if (device.type.toLowerCase() == 'sensor ruchu') {
                                final int ledOnDuration =
                                    int.tryParse(device.extraFields?['led_on_duration']?.toString() ?? '') ?? 1000;
                                final int pirCooldownTime =
                                    int.tryParse(device.extraFields?['pir_cooldown_time']?.toString() ?? '') ?? 5000;

                                final motionSensor = MotionSensor.fromDevice(
                                  device,
                                  ledOnDuration: ledOnDuration,
                                  pirCooldownTime: pirCooldownTime,
                                );

                                return ExpansionTile(
                                  leading: Icon(getDeviceIcon(device.type), color: primaryColor),
                                  title: Text(
                                    device.name,
                                    style: const TextStyle(
                                      color: textColor,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Port: ${device.port}, status: ${device.status ?? 'off'}',
                                    style: const TextStyle(
                                      color: textColor,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  children: [
                                    MotionSensorWidget(
                                      motionSensor: motionSensor,
                                      userId: widget.userId,
                                      devicesBloc: bloc,
                                    ),
                                  ],
                                );
                              } else {
                                return ListTile(
                                  leading: Icon(getDeviceIcon(device.type), color: primaryColor),
                                  title: Text(
                                    device.name,
                                    style: const TextStyle(
                                      color: textColor,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Port: ${device.port}, status: ${device.status ?? 'off'}',
                                    style: const TextStyle(
                                      color: textColor,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                );
                              }
                            }).toList(),
                          );
                        } else if (state is DevicesError) {
                          return ListTile(
                            title: Text('Błąd: ${state.message}', style: const TextStyle(color: textColor)),
                          );
                        }
                        return const SizedBox();
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'led':
        return Icons.lightbulb;
      case 'sensor ruchu':
        return Icons.directions_run_outlined;
      default:
        return Icons.device_unknown;
    }
  }

  IconData getRoomIcon(String room) {
    switch (room.toLowerCase()) {
      case 'kuchnia':
        return Icons.kitchen;
      case 'salon':
        return Icons.weekend;
      case 'sypialnia':
        return Icons.king_bed;
      case 'łazienka':
        return Icons.bathtub;
      default:
        return Icons.home;
    }
  }
}
