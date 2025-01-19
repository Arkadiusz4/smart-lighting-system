import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/boards/board_bloc.dart';
import 'package:mobile_app/blocs/boards/board_event.dart';
import 'package:mobile_app/models/board.dart';
import 'package:mobile_app/styles/color.dart';
import 'edit_wifi_screen.dart'; // Import the EditWifiScreen

class EditBoardScreen extends StatefulWidget {
  final Board board;

  const EditBoardScreen({super.key, required this.board});

  @override
  _EditBoardScreenState createState() => _EditBoardScreenState();
}

class _EditBoardScreenState extends State<EditBoardScreen> {
  late TextEditingController _nameController;
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
    _nameController = TextEditingController(text: widget.board.name);
    _selectedRoom = widget.board.room.isNotEmpty ? widget.board.room : _rooms.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edycja urządzenia',
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
              controller: _nameController,
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
            const SizedBox(height: 50.0),
            ElevatedButton(
              onPressed: () {
                // Navigate to the EditWifiScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanEsp32ScreenEditWifi(), // Pass the board to EditWifiScreen
                  ),
                );
              },
              child: const Text(
                'Edytuj WiFi',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                final newName = _nameController.text;
                final newRoom = _selectedRoom ?? '';
                context.read<BoardsBloc>().add(
                      EditBoard(
                        boardId: widget.board.boardId,
                        newName: newName,
                        newRoom: newRoom,
                      ),
                    );
                Navigator.of(context).pop();
              },
              child: const Text(
                'Zapisz zmiany',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
