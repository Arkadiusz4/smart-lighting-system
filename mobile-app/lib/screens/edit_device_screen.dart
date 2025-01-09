import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/boards/board_bloc.dart';
import 'package:mobile_app/blocs/boards/board_event.dart';
import 'package:mobile_app/models/board.dart';
import 'package:mobile_app/styles/color.dart';

class EditDeviceScreen extends StatefulWidget {
  final Board board;

  const EditDeviceScreen({super.key, required this.board});

  @override
  _EditDeviceScreenState createState() => _EditDeviceScreenState();
}

class _EditDeviceScreenState extends State<EditDeviceScreen> {
  late TextEditingController _nameController;

  String? _selectedRoom;

  final List<String> _rooms = ['Salon', 'Sypialnia', 'Kuchnia', 'Łazienka', 'Korytarz', 'Biuro'];

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
        title: const Text('Edycja urządzenia'),
        backgroundColor: darkBackground,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nazwa urządzenia',
                hintStyle: TextStyle(color: textColor),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              style: const TextStyle(color: textColor, fontSize: 18),
              dropdownColor: Colors.indigo[800],
              borderRadius: BorderRadius.circular(10),
              value: _selectedRoom,
              decoration: const InputDecoration(labelText: 'Pokój'),
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
            const SizedBox(height: 20),
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
              child: const Text('Zapisz zmiany'),
            ),
          ],
        ),
      ),
    );
  }
}
