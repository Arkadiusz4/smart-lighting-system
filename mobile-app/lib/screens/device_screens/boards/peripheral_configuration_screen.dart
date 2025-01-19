import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/boards/board_bloc.dart';
import 'package:mobile_app/blocs/boards/board_event.dart';
import 'package:mobile_app/styles/color.dart';

class AddPeripheralBoardScreen extends StatefulWidget {
  const AddPeripheralBoardScreen({super.key});

  @override
  _AddPeripheralBoardScreenState createState() =>
      _AddPeripheralBoardScreenState();
}

class _AddPeripheralBoardScreenState extends State<AddPeripheralBoardScreen> {
  final TextEditingController _deviceIdController = TextEditingController();
  String? _selectedRoom;
  String? clientId;

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
                    onPressed: _deviceIdController.text.isNotEmpty
                        ? () async {
                      final newName = _deviceIdController.text;
                      final newRoom = _selectedRoom ?? '';
                      context.read<BoardsBloc>().add(
                        AddPeripheralBoard(
                          boardId: _deviceIdController.text,
                          name: newName,
                          room: newRoom,
                          peripheral: true,
                        ),
                      );

                      // Display a success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Urządzenie peripheral zostało dodane!',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      );

                      // Wait for a short duration before popping the screen
                      await Future.delayed(const Duration(seconds: 2));

                      // Pop the current screen to go back
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
