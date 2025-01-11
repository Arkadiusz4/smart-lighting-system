import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
import 'package:mobile_app/models/device.dart';
import 'package:mobile_app/styles/color.dart';

class AddDeviceScreen extends StatefulWidget {
  final String boardId;

  const AddDeviceScreen({super.key, required this.boardId});

  @override
  _AddDeviceScreenState createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedPort;
  String? _selectedDevice;

  final List<String> _devices = ['LED', 'Sensor ruchu', 'Czujnik dymu', 'Czujnik gazu'];
  final List<String> _ports = ['GPIO1', 'GPIO2', 'GPIO3', 'UART0'];

  @override
  void dispose() {
    _nameController.dispose();
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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Typ urządzenia'),
              value: _devices.first,
              items: _devices.map((device) {
                return DropdownMenuItem(
                  value: device,
                  child: Text(device),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDevice = value;
                });
              },
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
                final type = _selectedDevice ?? _devices.first;
                final port = _selectedPort ?? _ports.first;

                final devicesBloc = context.read<DevicesBloc>();

                final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
                final device = Device(
                  deviceId: deviceId,
                  name: name,
                  type: type,
                  port: port,
                  boardId: widget.boardId,
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
