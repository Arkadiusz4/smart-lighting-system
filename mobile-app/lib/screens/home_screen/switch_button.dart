import 'package:flutter/material.dart';
import 'package:mobile_app/blocs/devices/devices_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
import 'package:mobile_app/models/device.dart';
import 'package:mobile_app/styles/color.dart';

class SwitchButton extends StatefulWidget {
  final Device device;
  final String userId;
  final DevicesBloc devicesBloc;

  const SwitchButton({
    super.key,
    required this.device,
    required this.userId,
    required this.devicesBloc,
  });

  @override
  _SwitchButtonState createState() => _SwitchButtonState();
}

class _SwitchButtonState extends State<SwitchButton> {
  late bool currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.device.status == 'on';
  }

  @override
  void didUpdateWidget(covariant SwitchButton oldWidget) {
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
        'Wyłącz/włącz czujnik',
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
