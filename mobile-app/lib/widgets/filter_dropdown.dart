import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/logs/logs_bloc.dart';
import 'package:mobile_app/blocs/logs/logs_event.dart';
import 'package:mobile_app/styles/color.dart';

class FilterDropdown extends StatefulWidget {
  const FilterDropdown({super.key});

  @override
  _FilterDropdownState createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<FilterDropdown> {
  String _selectedFilter = 'Ostatni dzień';

  final Map<String, Duration> filterOptions = {
    'Ostatnia godzina': const Duration(hours: 1),
    'Ostatni dzień': const Duration(days: 1),
    'Ostatni tydzień': const Duration(days: 7),
    'Ostatni miesiąc': const Duration(days: 30),
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedFilter,
      dropdownColor: darkBackground,
      style: const TextStyle(color: textColor),
      underline: Container(
        height: 2,
        color: primaryColor,
      ),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedFilter = newValue;
          });
          final duration = filterOptions[newValue]!;
          final since = DateTime.now().subtract(duration);
          context.read<LogsBloc>().add(LoadLogs(since: since));
        }
      },
      items: filterOptions.keys.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
