import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
import 'package:mobile_app/blocs/devices/devices_state.dart';
import 'package:mobile_app/repositories/devices_repository.dart';
import 'package:mobile_app/repositories/logs_repository.dart';
import 'package:mobile_app/screens/device_screens/devices/add_device_screen.dart';
import 'package:mobile_app/screens/device_screens/devices/edit_device_screen.dart';
import 'package:mobile_app/styles/color.dart';

class DevicesListScreen extends StatelessWidget {
  final String userId;
  final String boardId;
  final bool isPeripheral;

  const DevicesListScreen({super.key, required this.userId, required this.boardId, required this.isPeripheral});

  @override
  Widget build(BuildContext context) {

    return BlocProvider(
      create: (context) => DevicesBloc(
        devicesRepository: DevicesRepository(boardId: boardId),
        logsRepository: LogsRepository(),
        userId: userId,
        boardId: boardId,
      )..add(LoadDevices()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Urządzenia na boardzie $boardId',
            style: const TextStyle(
              color: textColor,
              fontSize: 24.0,
              fontWeight: FontWeight.w700,
            ),
          ),
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
                  child: Text(
                    'Brak urządzeń.',
                    style: TextStyle(color: textColor, fontSize: 22.0, fontWeight: FontWeight.w500),
                  ),
                );
              }
              return ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return ListTile(
                    title: Text(
                      device.name,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Typ: ${device.type}, Port: ${device.port}',
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    trailing:  isPeripheral == false ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: primaryColor),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<DevicesBloc>(),
                                  child: EditDeviceScreen(device: device),
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            final devicesBloc = context.read<DevicesBloc>();

                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: darkBackground,
                                  title: const Text(
                                    "Potwierdzenie",
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  content: const Text(
                                    "Czy na pewno chcesz usunąć to urządzenie?",
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        "Nie",
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        devicesBloc.add(RemoveDevice(device.deviceId, device.name));
                                      },
                                      child: const Text(
                                        "Tak",
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ): null,
                  );
                },
              );
            } else if (state is DevicesError) {
              return Center(
                child: Text('Błąd: ${state.message}', style: const TextStyle(color: textColor)),
              );
            }
            return const SizedBox();
          },
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            backgroundColor: primaryColor,
            onPressed: () {
              final devicesBloc = context.read<DevicesBloc>();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: devicesBloc,
                    child: AddDeviceScreen(boardId: boardId),
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
