import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/boards/board_bloc.dart';
import 'package:mobile_app/blocs/boards/board_event.dart';
import 'package:mobile_app/screens/device_screens/others/qr_code_scanner_screen.dart';
import 'package:mobile_app/screens/device_screens/others/scan_esp32_screen.dart';
import 'package:mobile_app/styles/color.dart';

class AddBoardScreen extends StatefulWidget {
  const AddBoardScreen({super.key});

  @override
  _AddBoardScreenState createState() => _AddBoardScreenState();
}

class _AddBoardScreenState extends State<AddBoardScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedRoom;
  String? _scannedBoardId;

  final List<String> _rooms = ['Salon', 'Sypialnia', 'Kuchnia', 'Łazienka'];

  @override
  void initState() {
    super.initState();
    _selectedRoom = _rooms.first;
    _scannedBoardId = '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRCodeScannerScreen()),
    );

    if (result != null) {
      setState(() {
        _scannedBoardId = result as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj urządzenie'),
        backgroundColor: darkBackground,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nazwa urządzenia'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _scanQRCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Zeskanuj QR Code'),
            ),
            const SizedBox(height: 16),
            Text(
              _scannedBoardId != null && _scannedBoardId!.isNotEmpty
                  ? 'Zeskanowany Board ID: $_scannedBoardId'
                  : 'Brak zeskanowanego Board ID',
              style: const TextStyle(color: textColor),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_scannedBoardId == null || _scannedBoardId!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Najpierw zeskanuj QR Code')),
                      );
                      return;
                    }
                    final newName = _nameController.text;
                    final newRoom = _selectedRoom ?? '';
                    context.read<BoardsBloc>().add(
                          AddBoard(
                            boardId: _scannedBoardId!,
                            name: newName,
                            room: newRoom,
                          ),
                        );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Dodaj urządzenie'),
                ),
                if (_scannedBoardId != null && _scannedBoardId!.isNotEmpty)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScanEsp32Screen()),
                      );
                    },
                    child: const Text('Skonfiguruj'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
