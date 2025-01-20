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
  TextEditingController? _ledOnDurationController;
  TextEditingController? _pirCooldownTimeController;

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

  String? _selectedPort;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
    // Inicjalizacja wybranego portu na podstawie danych urządzenia
    _selectedPort = widget.device.port;

    // Inicjalizacja kontrolerów dla specyficznych pól czujnika ruchu
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
            // Zastąpienie TextField listą rozwijaną dla portu z dostosowanym stylem
            DropdownButtonFormField<String>(
              value: _selectedPort,
              decoration: const InputDecoration(
                labelText: 'Port',
                labelStyle: TextStyle(color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),           // Kolor tekstu wybranego elementu
              dropdownColor: Colors.black,                           // Kolor tła menu rozwijanego
              items: _ports.map((port) {
                return DropdownMenuItem(
                  value: port,
                  child: Text(
                    port,
                    style: const TextStyle(color: Colors.white),    // Kolor tekstu opcji
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedPort = newValue;
                });
              },
            ),
            if (widget.device.type.toLowerCase() == 'sensor ruchu') ...[
              const SizedBox(height: 20),
              TextField(
                controller: _ledOnDurationController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                final newPort = _selectedPort?.trim() ?? '';

                // Walidacja: nazwa urządzenia nie może być pusta
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nazwa urządzenia nie może być pusta.'),
                    ),
                  );
                  return;
                }

                Map<String, dynamic>? extraFields;
                // Walidacja pól dla 'sensor ruchu'
                if (widget.device.type.toLowerCase() == 'sensor ruchu') {
                  final ledDurationText = _ledOnDurationController?.text.trim() ?? '';
                  final pirCooldownText = _pirCooldownTimeController?.text.trim() ?? '';

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

                // Wywołanie zdarzenia aktualizacji urządzenia
                context.read<DevicesBloc>().add(UpdateDevice(
                  deviceId: widget.device.deviceId,
                  newName: newName,
                  newType: widget.device.type,
                  newPort: newPort,
                  extraFields: extraFields,
                ));

                Navigator.of(context).pop(); // Powrót do poprzedniego ekranu
              },
              child: const Text('Zapisz zmiany'),
            ),
          ],
        ),
      ),
    );
  }
}
