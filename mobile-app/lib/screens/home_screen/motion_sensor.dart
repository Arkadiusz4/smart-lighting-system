import 'package:flutter/material.dart';
import 'package:mobile_app/blocs/devices/devices_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
import 'package:mobile_app/models/device.dart';
import 'package:mobile_app/styles/color.dart';

import '../../models/motion_sensor.dart';

class MotionSensorWidget extends StatefulWidget {
  final MotionSensor motionSensor;
  final String userId;
  final DevicesBloc devicesBloc;

  const MotionSensorWidget({
    super.key,
    required this.motionSensor,
    required this.userId,
    required this.devicesBloc,
  });

  @override
  _MotionSensorWidgetState createState() => _MotionSensorWidgetState();
}

class _MotionSensorWidgetState extends State<MotionSensorWidget> {
  late bool currentValue;
  late TextEditingController ledDurationController;
  late TextEditingController pirCooldownController;

  @override
  void initState() {
    super.initState();
    currentValue = widget.motionSensor.status == 'on';
    ledDurationController =
        TextEditingController(text: widget.motionSensor.ledOnDuration.toString());
    pirCooldownController =
        TextEditingController(text: widget.motionSensor.pirCooldownTime.toString());
  }

  @override
  void dispose() {
    ledDurationController.dispose();
    pirCooldownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text(
            'Włącz/wyłącz MotionSensor',
            style: TextStyle(
              color: textColor,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          value: currentValue,
          onChanged: (bool value) {
            setState(() {
              currentValue = value;
            });
            print(
                "Toggle MotionSensor clicked, new value: $value, ${widget.motionSensor.boardId}");
            widget.devicesBloc.add(
              ToggleMotionSensor(widget.motionSensor.deviceId, value),
            );
          },
        ),
        const SizedBox(height: 16.0),
        TextField(
          controller: ledDurationController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'LED On Duration (ms)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            print('New LED On Duration: $value');
          },
        ),
        const SizedBox(height: 16.0),
        TextField(
          controller: pirCooldownController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'PIR Cooldown Time (ms)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            print('New PIR Cooldown Time: $value');
          },
        ),
      ],
    );
  }
}

