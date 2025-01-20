import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        text:
            (widget.device.extraFields?['pir_cooldown_time'] ?? '').toString(),
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
              style:
                  const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
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
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Czas świecenia diody (LED On Duration)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _pirCooldownTimeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Czas chłodzenia czujnika PIR (PIR Cooldown Time)',
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final newName = _nameController.text.trim();
                final newPort = _portController.text.trim();

// Validate that device name is not empty
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nazwa urządzenia nie może być pusta.'),
                    ),
                  );
                  return;
                }

                Map<String, dynamic>? extraFields;
// Validate decimal fields for sensor ruchu
                if (widget.device.type.toLowerCase() == 'sensor ruchu') {
                  final ledDurationText =
                      _ledOnDurationController?.text.trim() ?? '';
                  final pirCooldownText =
                      _pirCooldownTimeController?.text.trim() ?? '';

// Try parsing the decimal values
                  final ledDuration = int.tryParse(ledDurationText);
                  final pirCooldown = int.tryParse(pirCooldownText);

                  if (ledDuration == null || pirCooldown == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Proszę wprowadzić poprawne wartości liczbowe dla LED Duration i PIR Cooldown Time.',
                        ),
                      ),
                    );
                    return;
                  }

                  extraFields = {
                    'led_on_duration': ledDuration,
                    'pir_cooldown_time': pirCooldown,
                  };
                }

// Dispatch update event
                context.read<DevicesBloc>().add(UpdateDevice(
                      deviceId: widget.device.deviceId,
                      newName: newName,
                      newType: widget.device.type,
                      newPort: newPort,
                      extraFields: extraFields,
                    ));

                Navigator.of(context).pop(); // Go back to the previous screen
              },
              child: const Text('Zapisz zmiany'),
            ),
          ],
        ),
      ),
    );
  }
}
