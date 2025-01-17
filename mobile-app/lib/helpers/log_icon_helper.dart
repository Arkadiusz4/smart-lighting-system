import 'package:flutter/material.dart';
import 'package:mobile_app/models/log_entry.dart';
import 'package:mobile_app/styles/color.dart';

class LogIconHelper {
  static IconData getIcon(LogEntry log) {
    switch (log.severity) {
      case 'critical':
        return Icons.error;
      case 'warning':
        return Icons.warning;
    }

    if (log.eventType == 'add_board') {
      return Icons.add;
    } else if (log.eventType == 'edit_board') {
      return Icons.edit;
    } else if (log.eventType == 'unassign_board') {
      return Icons.delete;
    } else if (log.eventType == 'add_device') {
      return Icons.add_box;
    } else if (log.eventType == 'edit_device') {
      return Icons.edit;
    } else if (log.eventType == 'remove_device') {
      return Icons.delete_forever;
    }

    if (log.device == 'Network') {
      if (log.wifiStatus == 'no_wifi') {
        return Icons.signal_wifi_off;
      } else if (log.wifiStatus == 'connected') {
        return Icons.wifi;
      }
    }
    if (log.device == 'Device') {
      if (log.eventType == 'led_on') {
        return Icons.lightbulb;
      } else if (log.eventType == 'led_off') {
        return Icons.lightbulb_outline;
      }
    }
    if (log.device == 'Motion Sensor') {
      return Icons.directions_run;
    }
    return Icons.device_unknown;
  }

  static Color getIconColor(LogEntry log) {
    switch (log.severity) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
    }

    if (log.eventType == 'add_board' || log.eventType == 'add_device') {
      return Colors.green;
    } else if (log.eventType == 'edit_board' || log.eventType == 'edit_device') {
      return Colors.blue;
    } else if (log.eventType == 'unassign_board' || log.eventType == 'remove_device') {
      return Colors.red;
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
