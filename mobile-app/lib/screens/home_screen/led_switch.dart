import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_bloc.dart';
import 'package:mobile_app/blocs/devices/devices_event.dart';
import 'package:mobile_app/models/device.dart';
import 'package:mobile_app/styles/color.dart';

class LedSwitch extends StatefulWidget {
  final Device device;
  final String userId;

  const LedSwitch({Key? key, required this.device, required this.userId}) : super(key: key);

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
      title: const Text('Włącz/wyłącz LED', style: TextStyle(color: textColor)),
      value: currentValue,
      onChanged: (bool value) {
        setState(() {
          currentValue = value;
        });
        print("Toggle LED clicked, new value: $value");
        context.read<DevicesBloc>().add(
              ToggleLed(widget.device.deviceId, value),
            );
      },
    );
  }
}
