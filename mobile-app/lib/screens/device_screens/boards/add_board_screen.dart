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
      final scannedString = result as String;
      final parts = scannedString.split(';');
      String? mac;
      for (var part in parts) {
        if (part.startsWith('MAC:')) {
          mac = part.substring(4);
          break;
        }
      }
      if (mac != null) {
        mac = mac.replaceAll(":", "");
      }
      setState(() {
        _scannedBoardId = mac ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dodaj urządzenie',
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
            ElevatedButton.icon(
              onPressed: _scanQRCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text(
                'Zeskanuj QR Code',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              _scannedBoardId != null && _scannedBoardId!.isNotEmpty
                  ? 'Zeskanowany Board ID: $_scannedBoardId'
                  : 'Brak zeskanowanego Board ID',
              style: const TextStyle(color: textColor),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
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
                    child: const Text(
                      'Dodaj urządzenie',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
            ),
          ],
        ),
      ),
    );
  }
}
