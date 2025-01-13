import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
import 'package:mobile_app/models/device.dart';
import 'package:mobile_app/styles/color.dart';

class EditDeviceScreen extends StatefulWidget {
  final Device device;

  const EditDeviceScreen({super.key, required this.device});

  @override
  _EditDeviceScreenState createState() => _EditDeviceScreenState();
}

class _EditDeviceScreenState extends State<EditDeviceScreen> {
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
    _typeController = TextEditingController(text: widget.device.type);
    _portController = TextEditingController(text: widget.device.port);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edytuj urządzenie'),
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
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Typ urządzenia'),
            ),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(labelText: 'Port'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final newName = _nameController.text;
                final newType = _typeController.text;
                final newPort = _portController.text;

                // Wyślij event aktualizacji urządzenia
                context.read<DevicesBloc>().add(UpdateDevice(
                      deviceId: widget.device.deviceId,
                      newName: newName,
                      newType: newType,
                      newPort: newPort,
                    ));

                Navigator.of(context).pop(); // Powrót do listy urządzeń
              },
              child: const Text('Zapisz zmiany'),
            ),
          ],
        ),
      ),
    );
  }
}
