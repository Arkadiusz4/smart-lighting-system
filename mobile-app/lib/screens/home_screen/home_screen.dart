import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/home/home_bloc.dart';
import 'package:mobile_app/blocs/home/home_event.dart';
import 'package:mobile_app/blocs/home/home_state.dart';
import 'package:mobile_app/models/device.dart';
import 'package:mobile_app/screens/home_screen/led_switch.dart';
import 'package:mobile_app/styles/color.dart';
import 'package:mobile_app/repositories/home_repository.dart';

class HomeScreen extends StatelessWidget {
  final String userId;
  final String boardId;
  final String room;

  const HomeScreen({Key? key, required this.userId, required this.boardId, required this.room}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final homeRepository = HomeRepository(userId: userId);
        final homeBloc = HomeBloc(homeRepository: homeRepository);
        homeBloc.add(LoadHomeData());
        return homeBloc;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ekran Główny'),
          backgroundColor: darkBackground,
        ),
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is HomeLoaded) {
              final devicesByRoom = state.devicesByRoom;
              if (devicesByRoom.isEmpty) {
                return const Center(child: Text('Brak urządzeń.', style: TextStyle(color: textColor)));
              }

              return ListView(
                children: devicesByRoom.entries.map((entry) {
                  final roomName = entry.key;
                  final devices = entry.value;

                  return Card(
                    margin: const EdgeInsets.all(8),
                    color: darkBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pokój: $roomName',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                          const SizedBox(height: 8),
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
                    ),
                  );
                }).toList(),
              );
            } else if (state is HomeError) {
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
}
