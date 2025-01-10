import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
import 'package:mobile_app/blocs/devices/devices_state.dart';
import 'package:mobile_app/repositories/devices_repository.dart';
import 'package:mobile_app/repositories/logs_repository.dart';
import 'package:mobile_app/screens/add_device_screen.dart';
import 'package:mobile_app/screens/edit_device_screen.dart';
import 'package:mobile_app/styles/color.dart';

class DevicesListScreen extends StatelessWidget {
  final String userId;
  final String boardId;

  const DevicesListScreen({Key? key, required this.userId, required this.boardId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DevicesBloc(
        devicesRepository: DevicesRepository(userId: userId, boardId: boardId),
        logsRepository: LogsRepository(),
        userId: userId,
        boardId: boardId,
      )..add(LoadDevices()),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Urządzenia na boardzie $boardId'),
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
              return ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return ListTile(
                    title: Text(device.name, style: const TextStyle(color: textColor)),
                    subtitle:
                        Text('Typ: ${device.type}, Port: ${device.port}', style: const TextStyle(color: textColor)),
                    trailing: Row(
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
                            context.read<DevicesBloc>().add(RemoveDevice(device.deviceId));
                          },
                        ),
                      ],
                    ),
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
                    child: const AddDeviceScreen(),
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
