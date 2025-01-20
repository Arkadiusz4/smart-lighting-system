import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/boards/board_bloc.dart';
import 'package:mobile_app/blocs/boards/board_event.dart';
import 'package:mobile_app/styles/color.dart';

import '../../../models/device.dart';
import '../../../models/log_entry.dart';
import '../../../repositories/devices_repository.dart';
import '../../../repositories/logs_repository.dart';

class AddPeripheralBoardScreen extends StatefulWidget {
  const AddPeripheralBoardScreen({super.key});

  @override
  _AddPeripheralBoardScreenState createState() => _AddPeripheralBoardScreenState();
}

class _AddPeripheralBoardScreenState extends State<AddPeripheralBoardScreen> {
  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController();
  String? _selectedRoom;

  final List<String> _rooms = [
    'Salon',
    'Sypialnia',
    'Kuchnia',
    'Łazienka',
    'Biuro',
    'Korytarz',
    'Inne',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRoom = _rooms.first;
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dodaj urządzenie periphral',
          style: TextStyle(
            color: textColor,
            fontSize: 24.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: darkBackground,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _deviceIdController,
              style: const TextStyle(
                color: textColor,
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                labelText: 'Id urządzenia',
                labelStyle: TextStyle(
                  color: textColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            TextField(
              controller: _deviceNameController,
              style: const TextStyle(
                color: textColor,
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                labelText: 'Nazwa urządzenia',
                labelStyle: TextStyle(
                  color: textColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              style: const TextStyle(
                color: textColor,
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
              dropdownColor: Colors.indigo,
              value: _selectedRoom,
              decoration: const InputDecoration(
                labelText: 'Pokój',
                labelStyle: TextStyle(
                  color: textColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
              items: _rooms.map((room) {
                return DropdownMenuItem(
                  value: room,
                  child: Text(room),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRoom = value;
                });
              },
            ),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _deviceIdController.text.isNotEmpty && _deviceNameController.text.isNotEmpty
                        ? () async {
                            final newName = _deviceNameController.text.trim();
                            final boardId = _deviceIdController.text.trim();
                            final newRoom = _selectedRoom ?? '';
                            context.read<BoardsBloc>().add(
                                  AddPeripheralBoard(
                                    boardId: boardId,
                                    name: newName,
                                    room: newRoom,
                                    peripheral: true,
                                  ),
                                );

                            await Future.delayed(const Duration(seconds: 2));
                            final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
                            final device = Device(
                              deviceId: deviceId,
                              name: "Żarówka",
                              type: "LED",
                              port: "GPIO5",
                              boardId: boardId,
                              status: "off",
                            );
                            final LogEntry log = LogEntry(
                                timestamp: DateTime.now(),
                                message: "Dodano urządzenie",
                                device: device.name,
                                boardId: boardId,
                                userId: FirebaseAuth.instance.currentUser!.uid,
                                severity: "info");

                            await DevicesRepository(boardId: boardId).addDevice(device);

                            await LogsRepository().addLogEntry(log);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Urządzenie peripheral zostało dodane!',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                            await Future.delayed(const Duration(seconds: 1));

                            Navigator.pop(context);
                          }
                        : null,
                    child: const Text('Connect'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
