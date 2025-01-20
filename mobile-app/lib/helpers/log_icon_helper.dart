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
      if (log.eventType == 'wifi_connected') {
        return Icons.wifi;
      } else if (log.wifiStatus == 'wifi_disconnected') {
        return Icons.wifi_off;
      }
    }
    if (log.device == 'Device') {
      if (log.eventType == 'led_on') {
        return Icons.lightbulb;
      } else if (log.eventType == 'led_off') {
        return Icons.lightbulb_outline;
      }
    }
    if (log.device == 'Device') {
      if (log.eventType == 'motion_sensor_on') {
        return Icons.directions_run;
      } else if (log.eventType == 'motion_sensor_off') {
        return Icons.sensors_off;
      }
    }
    if (log.device == 'Network') {
      if (log.eventType == 'connection_lost') {
        return Icons.wifi_tethering_off;
      } else if (log.eventType == 'connection_restored') {
        return Icons.wifi_tethering;
      }
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
      if (log.eventType == 'wifi_connected') {
        return Colors.green;
      } else if (log.wifiStatus == 'wifi_disconnected') {
        return Colors.red;
      }
    }
    if (log.device == 'Device') {
      if (log.eventType == 'led_on') {
        return Colors.yellow;
      } else if (log.eventType == 'led_off') {
        return primaryColor;
      }
    }
    if (log.device == 'Device') {
      if (log.eventType == 'motion_sensor_on') {
        return Colors.green;
      } else if (log.eventType == 'motion_sensor_off') {
        return Colors.red;
      }
    }
    return primaryColor;
  }
}
