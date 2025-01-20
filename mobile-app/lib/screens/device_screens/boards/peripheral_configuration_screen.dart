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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dodaj urządzenie peripheral',
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
        child: Form(
          key: _formKey, // Assign the form key
          child: Column(
            children: [
              TextFormField(
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Id urządzenia nie może być puste.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nazwa urządzenia nie może być pusta.';
                  }
                  return null;
                },
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
                      onPressed: () async {
                        // Validate the form fields
                        if (!_formKey.currentState!.validate()) {
                          return; // Stop if validation fails
                        }
                        final newName = _deviceNameController.text.trim();
                        final boardId = _deviceIdController.text.trim();
                        final newRoom = _selectedRoom ?? '';

                        // Dispatch event to add peripheral board
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
                          port: "GPIO6",
                          boardId: boardId,
                          status: "off",
                        );
                        await Future.delayed(const Duration(seconds: 1));
                        final deviceIdDrguie = DateTime.now().millisecondsSinceEpoch.toString();
                        final deviceCzujnikZmierzchu = Device(deviceId: deviceIdDrguie,
                            name: "Czujnik zmierzchu", type: "Czujnik zmierzchu",
                            port: "ADC0", boardId: boardId, status: "off");

                        final LogEntry log = LogEntry(
                          timestamp: DateTime.now(),
                          message: "Dodano urządzenie",
                          device: device.name,
                          boardId: boardId,
                          userId: FirebaseAuth.instance.currentUser!.uid,
                          severity: "info",
                        );

                        final LogEntry logDrugi = LogEntry(
                          timestamp: DateTime.now(),
                          message: "Dodano urządzenie",
                          device: deviceCzujnikZmierzchu.name,
                          boardId: boardId,
                          userId: FirebaseAuth.instance.currentUser!.uid,
                          severity: "info",
                        );


                        await DevicesRepository(boardId: boardId).addDevice(device);
                        await LogsRepository().addLogEntry(log);

                        print("I am testing here");
                        await Future.delayed(const Duration(seconds: 2));

                        await DevicesRepository(boardId: boardId).addDevice(deviceCzujnikZmierzchu);
                        await LogsRepository().addLogEntry(logDrugi);

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
                      },
                      child: const Text('Connect'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

