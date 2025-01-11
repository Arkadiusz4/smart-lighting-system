import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
import 'package:mobile_app/blocs/devices/devices_state.dart';
import 'package:mobile_app/models/device.dart';
import 'package:mobile_app/repositories/devices_repository.dart';
import 'package:mobile_app/repositories/logs_repository.dart';
import 'package:mobile_app/styles/color.dart';
import 'package:mobile_app/screens/home_screen/led_switch.dart';

class HomeScreen extends StatelessWidget {
  final String userId;
  final String boardId;
  final String room;

  const HomeScreen({
    Key? key,
    required this.userId,
    required this.boardId,
    required this.room,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DevicesBloc>(
      create: (_) => DevicesBloc(
        devicesRepository: DevicesRepository(userId: userId, boardId: boardId),
        logsRepository: LogsRepository(),
        userId: userId,
        boardId: boardId,
      )..add(LoadDevices()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ekran Główny'),
          backgroundColor: darkBackground,
        ),
        body: BlocBuilder<DevicesBloc, DevicesState>(
          builder: (context, state) {
            if (state is DevicesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is DevicesLoaded) {
              final devices = state.devices;
              if (devices.isEmpty) {
                return const Center(
                  child: Text('Brak urządzeń.', style: TextStyle(color: textColor)),
                );
              }

              final Map<String, List<Device>> devicesByRoom = {
                room: devices,
              };

              return ListView(
                children: devicesByRoom.entries.map((entry) {
                  final roomName = entry.key;
                  final devices = entry.value;

                  return Card(
                    margin: const EdgeInsets.all(8),
                    color: darkBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      side: const BorderSide(color: primaryColor, width: 2.0),
                    ),
                    elevation: 5,
                    shadowColor: primaryColor.withOpacity(0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExpansionTile(
                            initiallyExpanded: false,
                            leading: Icon(getRoomIcon(roomName), color: primaryColor),
                            title: Text(
                              roomName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            children: [
                              if (devices.isEmpty)
                                const Text('Brak urządzeń w tym pokoju.', style: TextStyle(color: textColor))
                              else
                                Column(
                                  children: devices.map((Device device) {
                                    if (device.type.toLowerCase() == 'led') {
                                      return ExpansionTile(
                                        initiallyExpanded: false,
                                        leading: Icon(getDeviceIcon(device.type), color: primaryColor),
                                        title: Text(device.name, style: const TextStyle(color: textColor)),
                                        subtitle: Text(
                                          'Port: ${device.port}, status: ${device.status ?? 'off'}',
                                          style: const TextStyle(color: textColor),
                                        ),
                                        children: [
                                          LedSwitch(device: device, userId: userId),
                                        ],
                                      );
                                    } else {
                                      return ListTile(
                                        leading: Icon(getDeviceIcon(device.type), color: primaryColor),
                                        title: Text(device.name, style: const TextStyle(color: textColor)),
                                        subtitle: Text(
                                          'Port: ${device.port}, status: ${device.status ?? 'off'}',
                                          style: const TextStyle(color: textColor),
                                        ),
                                      );
                                    }
                                  }).toList(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            } else if (state is DevicesError) {
              return Center(child: Text('Błąd: ${state.message}', style: const TextStyle(color: textColor)));
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  IconData getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'led':
        return Icons.lightbulb;
      case 'sensor':
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
