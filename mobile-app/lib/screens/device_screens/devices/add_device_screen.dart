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
  final TextEditingController _ledOnDurationController = TextEditingController();
  final TextEditingController _pirCooldownTimeController = TextEditingController();

  final List<String> _devices = ['LED', 'Sensor ruchu', 'Czujnik zmierzchu'];
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
    'GPIO16',
    'UART0',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ledOnDurationController.dispose();
    _pirCooldownTimeController.dispose();
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
      body: SingleChildScrollView(
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
              value: _selectedDevice ?? _devices.first,
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
              value: _selectedPort ?? _ports.first,
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
            if (_selectedDevice == 'Sensor ruchu') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _ledOnDurationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  labelText: 'Led On Duration (s)',
                  labelStyle: TextStyle(
                    color: textColor,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pirCooldownTimeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  labelText: 'PIR Cooldown Time (s)',
                  labelStyle: TextStyle(
                    color: textColor,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 50.0),
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nazwa urządzenia nie może być pusta'),
                    ),
                  );
                  return;
                }

                // If device is "Sensor ruchu", validate durations
                if (_selectedDevice == 'Sensor ruchu') {
                  final ledDuration = int.tryParse(_ledOnDurationController.text.trim());
                  final pirCooldown = int.tryParse(_pirCooldownTimeController.text.trim());

                  if (ledDuration == null || ledDuration <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Led On Duration musi być liczbą większą od 0'),
                      ),
                    );
                    return;
                  }

                  if (pirCooldown == null || pirCooldown <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PIR Cooldown Time musi być liczbą większą od 0'),
                      ),
                    );
                    return;
                  }
                }

                final type = _selectedDevice ?? _devices.first;
                final port = _selectedPort ?? _ports.first;
                final devicesBloc = context.read<DevicesBloc>();
                final deviceId = DateTime.now().millisecondsSinceEpoch.toString();

                final extraFields = _selectedDevice == 'Sensor ruchu'
                    ? {
                  'led_on_duration': _ledOnDurationController.text,
                  'pir_cooldown_time': _pirCooldownTimeController.text,
                }
                    : null;

                final device = Device(
                  deviceId: deviceId,
                  name: name,
                  type: type,
                  port: port,
                  boardId: widget.boardId,
                  extraFields: extraFields,
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
