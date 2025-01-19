import 'package:flutter/material.dart';
import 'package:mobile_app/blocs/devices/devices_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
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
  }

  @override
  void dispose() {

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

      ],
    );
  }
}

