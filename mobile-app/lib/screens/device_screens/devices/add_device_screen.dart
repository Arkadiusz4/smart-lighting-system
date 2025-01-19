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
  final List<String> _ports = [
    'GPIO1',
    'GPIO2',
    'GPIO3',
    'GPIO4',
    'GPIO5',
    'GPIO6',
    'GPIO7',
    'GPIO8',
    'GPIO9',
    'GPIO10',
    'UART0',
  ];

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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.indigo,
              style: const TextStyle(
                color: textColor,
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                labelText: 'Typ urządzenia',
                labelStyle: TextStyle(
                  color: textColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
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
              dropdownColor: Colors.indigo,
              style: const TextStyle(
                color: textColor,
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                labelText: 'Port',
                labelStyle: TextStyle(
                  color: textColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
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
            const SizedBox(height: 50.0),
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
              child: const Text(
                'Dodaj urządzenie',
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
