import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
import 'package:mobile_app/models/device.dart';
import 'package:mobile_app/styles/color.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  _AddDeviceScreenState createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  String? _selectedPort;

  final List<String> _ports = ['GPIO1', 'GPIO2', 'GPIO3', 'UART0'];

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
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
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Typ urządzenia'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Port'),
              value: _ports.first,
              items: _ports.map((port) {
                return DropdownMenuItem(
                  value: port,
                  child: Text(port),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPort = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text;
                final type = _typeController.text;
                final port = _selectedPort ?? _ports.first;

                final devicesBloc = context.read<DevicesBloc>();

                final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
                final device = Device(
                  deviceId: deviceId,
                  name: name,
                  type: type,
                  port: port,
                );
                devicesBloc.add(AddDevice(device));
                Navigator.of(context).pop();
              },
              child: const Text('Dodaj urządzenie'),
            ),
          ],
        ),
      ),
    );
  }
}
