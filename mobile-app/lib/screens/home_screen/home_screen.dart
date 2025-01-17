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

class HomeScreen extends StatefulWidget {
  final String userId;
  final Map<String, String> boardRoomMapping; // Map of boardId to room

  const HomeScreen({
    super.key,
    required this.userId,
    required this.boardRoomMapping,
  }
  );

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekran Główny'),
        backgroundColor: darkBackground,
      ),
      body: MultiBlocProvider(
        providers: devicesBlocs
            .map((bloc) => BlocProvider<DevicesBloc>.value(value: bloc))
            .toList(),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: devicesBlocs.map((bloc) {
                  return BlocBuilder<DevicesBloc, DevicesState>(
                    bloc: bloc,
                    builder: (context, state) {
                      if (state is DevicesLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is DevicesLoaded) {
                        final devices = state.devices;

                        if (devices.isEmpty) {
                          return const Center(
                            child: Text('Brak urządzeń.',
                                style: TextStyle(color: textColor)),
                          );
                        }

                        // Retrieve the room name from the boardId
                        final boardId = bloc.boardId;

                        final roomName = widget.boardRoomMapping[boardId] ??
                            'Nieznany pokój';

                        return Card(
                          margin: const EdgeInsets.all(8),
                          color: darkBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            side: const BorderSide(
                                color: primaryColor, width: 2.0),
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
                                  leading: Icon(getRoomIcon(roomName),
                                      color: primaryColor),
                                  title: Text(
                                    roomName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  children: devices.map((Device device) {
                                    if (device.type.toLowerCase() == 'led') {
                                      return ExpansionTile(
                                        initiallyExpanded: false,
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
                                              userId: widget.userId),
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
                                          )
                                        ),
                                      );
                                    }
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (state is DevicesError) {
                        return Center(
                          child: Text('Błąd: ${state.message}',
                              style: const TextStyle(color: textColor)),
                        );
                      }
                      return const SizedBox();
                    },
                  );
                }).toList(),
              ),
            ),
          ],
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
