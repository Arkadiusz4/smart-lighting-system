import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/boards/board_bloc.dart';
import 'package:mobile_app/blocs/boards/board_event.dart';
import 'package:mobile_app/screens/device_screens/others/qr_code_scanner_screen.dart';
import 'package:mobile_app/screens/device_screens/others/scan_esp32_screen.dart';
import 'package:mobile_app/styles/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBoardScreen extends StatefulWidget {
  const AddBoardScreen({super.key});

  @override
  _AddBoardScreenState createState() => _AddBoardScreenState();
}

class _AddBoardScreenState extends State<AddBoardScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedRoom;
  String? _scannedBoardId;
  String? clientId;
  String? mqttPassword;

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

      if (_scannedBoardId != null && _scannedBoardId!.isNotEmpty) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await fetchMqttData(_scannedBoardId!, userId);
        }
      }
    }
  }

  Future<void> fetchMqttData(String boardId, String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('mqtt_clients')
          .where('boardId', isEqualTo: boardId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          clientId = data['clientId'] ?? data['userId'];
          mqttPassword = data['mqtt_password'];
        });
        print('Pobrano dane MQTT: clientId=$clientId, mqttPassword=$mqttPassword');
      } else {
        print('Nie znaleziono danych MQTT dla boardId=$boardId, userId=$userId');
      }
    } catch (e) {
      print('Błąd podczas pobierania danych MQTT: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
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
                  if (_scannedBoardId != null && _scannedBoardId!.isNotEmpty)
                    ElevatedButton(
                      onPressed: () async {
                        final newName = _nameController.text;
                        final newRoom = _selectedRoom ?? '';
                        context.read<BoardsBloc>().add(
                              AddBoard(
                                boardId: _scannedBoardId!,
                                name: newName,
                                room: newRoom,
                              ),
                            );

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );
                        await Future.delayed(const Duration(seconds: 5));
                        Navigator.of(context).pop();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScanEsp32Screen(),
                          ),
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
