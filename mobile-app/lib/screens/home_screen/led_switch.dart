import 'package:flutter/material.dart';
import 'package:mobile_app/blocs/devices/devices_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
import 'package:mobile_app/models/device.dart';
import 'package:mobile_app/styles/color.dart';

class LedSwitch extends StatefulWidget {
  final Device device;
  final String userId;
  final DevicesBloc devicesBloc;

  const LedSwitch({
    super.key,
    required this.device,
    required this.userId,
    required this.devicesBloc,
  });

  @override
  _LedSwitchState createState() => _LedSwitchState();
}

class _LedSwitchState extends State<LedSwitch> {
  late bool currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.device.status == 'on';
  }

  @override
  void didUpdateWidget(covariant LedSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.status != widget.device.status) {
      setState(() {
        currentValue = widget.device.status == 'on';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text(
        'Włącz/wyłącz LED',
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
        print("Toggle LED clicked, new value: $value, ${widget.device.boardId}");
        widget.devicesBloc.add(
          ToggleLed(widget.device.deviceId, value, widget.device.name),
        );
      },
    );
  }
}
