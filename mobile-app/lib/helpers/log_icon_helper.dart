import 'package:flutter/material.dart';
import 'package:mobile_app/styles/color.dart';
import 'package:mobile_app/models/log_entry.dart';

class LogIconHelper {
  static IconData getIcon(LogEntry log) {
    switch (log.severity) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning;
    }

    if (log.device == 'Network') {
      if (log.wifiStatus == 'no_wifi') {
        return Icons.signal_wifi_off;
      } else if (log.wifiStatus == 'connected') {
        return Icons.wifi;
      }
    }

    if (log.device == 'LED') {
      if (log.status == 'on') {
        return Icons.lightbulb;
      } else if (log.status == 'off') {
        return Icons.lightbulb_outline;
      }
    }

    if (log.device == 'Motion Sensor') {
      return Icons.directions_run;
    }

    return log.device == 'LED' ? Icons.lightbulb : Icons.sensors;
  }

  static Color getIconColor(LogEntry log) {
    switch (log.severity) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        break;
    }

    if (log.device == 'Network') {
      if (log.wifiStatus == 'no_wifi') {
        return Colors.red;
      } else if (log.wifiStatus == 'connected') {
        return Colors.green;
      }
    }

    if (log.device == 'LED') {
      if (log.status == 'on') {
        return Colors.yellow;
      } else if (log.status == 'off') {
        return primaryColor;
      }
    }

    if (log.device == 'Motion Sensor') {
      return Colors.yellow;
    }

    return primaryColor;
  }
}
