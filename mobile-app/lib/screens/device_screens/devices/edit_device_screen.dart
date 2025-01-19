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
  late TextEditingController _portController;
  TextEditingController? _ledOnDurationController;
  TextEditingController? _pirCooldownTimeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
    _portController = TextEditingController(text: widget.device.port);

    // Initialize controllers for motion sensor specific fields if applicable
    if (widget.device.type.toLowerCase() == 'sensor ruchu') {
      _ledOnDurationController = TextEditingController(
        text: (widget.device.extraFields?['led_on_duration'] ?? '').toString(),
      );
      _pirCooldownTimeController = TextEditingController(
        text: (widget.device.extraFields?['pir_cooldown_time'] ?? '').toString(),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _portController.dispose();
    _ledOnDurationController?.dispose();
    _pirCooldownTimeController?.dispose();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nazwa urządzenia'),
            ),
            const SizedBox(height: 10),
            Text(
              'Typ urządzenia: ${widget.device.type}',
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(labelText: 'Port'),
            ),
            if (widget.device.type.toLowerCase() == 'sensor ruchu') ...[
              const SizedBox(height: 20),
              TextField(
                controller: _ledOnDurationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Czas świecenia diody (LED On Duration)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _pirCooldownTimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Czas chłodzenia czujnika PIR (PIR Cooldown Time)',
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final newName = _nameController.text;
                final newPort = _portController.text;

                // Prepare extra fields for motion sensor
                final extraFields = widget.device.type.toLowerCase() == 'motion sensor'
                    ? {
                  'led_on_duration': int.tryParse(_ledOnDurationController?.text ?? '0'),
                  'pir_cooldown_time': int.tryParse(_pirCooldownTimeController?.text ?? '0'),
                }
                    : null;

                // Dispatch update event
                context.read<DevicesBloc>().add(UpdateDevice(
                  deviceId: widget.device.deviceId,
                  newName: newName,
                  newType: widget.device.type, // Keep type unchanged
                  newPort: newPort,
                  extraFields: extraFields, // Include extra fields if present
                ));

                Navigator.of(context).pop(); // Go back to the devices list
              },
              child: const Text('Zapisz zmiany'),
            ),
          ],
        ),
      ),
    );
  }
}
