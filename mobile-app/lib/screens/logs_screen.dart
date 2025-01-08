import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/logs/logs_bloc.dart';
import 'package:mobile_app/blocs/logs/logs_event.dart';
import 'package:mobile_app/blocs/logs/logs_state.dart';
import 'package:mobile_app/models/log_entry.dart';
import 'package:mobile_app/repositories/logs_repository.dart';
import 'package:mobile_app/styles/color.dart';
import 'package:mobile_app/widgets/filter_dropdown.dart';
import 'package:intl/intl.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LogsBloc(logsRepository: LogsRepository())..add(const LoadLogs()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Logi'),
          backgroundColor: darkBackground,
        ),
        body: Container(
          color: darkBackground,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilterDropdown(),
              ),
              Expanded(
                child: BlocBuilder<LogsBloc, LogsState>(
                  builder: (context, state) {
                    if (state is LogsLoaded) {
                      if (state.logs.isEmpty) {
                        return const Center(
                          child: Text('Brak logów do wyświetlenia', style: TextStyle(color: textColor)),
                        );
                      }

                      final Map<String, Map<String, List<LogEntry>>> groupedLogs = {};
                      for (var log in state.logs) {
                        final monthKey = DateFormat('LLLL yyyy', 'pl_PL').format(log.timestamp); // np. "styczeń 2025"
                        final dayKey =
                            DateFormat('d MMMM yyyy', 'pl_PL').format(log.timestamp); // np. "8 stycznia 2025"

                        groupedLogs.putIfAbsent(monthKey, () => {});
                        groupedLogs[monthKey]!.putIfAbsent(dayKey, () => []);
                        groupedLogs[monthKey]![dayKey]!.add(log);
                      }

                      final sortedMonths = groupedLogs.keys.toList()
                        ..sort((a, b) {
                          final dateA = DateFormat('LLLL yyyy', 'pl_PL').parse(a);
                          final dateB = DateFormat('LLLL yyyy', 'pl_PL').parse(b);
                          return dateB.compareTo(dateA);
                        });

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        itemCount: sortedMonths.length,
                        itemBuilder: (context, monthIndex) {
                          final monthKey = sortedMonths[monthIndex];
                          final daysMap = groupedLogs[monthKey]!;
                          final sortedDays = daysMap.keys.toList()
                            ..sort((a, b) {
                              final dateA = DateFormat('d MMMM yyyy', 'pl_PL').parse(a);
                              final dateB = DateFormat('d MMMM yyyy', 'pl_PL').parse(b);
                              return dateB.compareTo(dateA);
                            });

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                color: primaryColor.withOpacity(0.2),
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  monthKey,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              ...sortedDays.map((dayKey) {
                                final logsInDay = daysMap[dayKey]!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      color: primaryColor.withOpacity(0.1),
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      child: Text(
                                        dayKey,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    ...logsInDay.map((log) {
                                      final time = DateFormat('HH:mm').format(log.timestamp);
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Card(
                                          color: Colors.white.withOpacity(0.1),
                                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                          child: ListTile(
                                            leading: Icon(
                                              log.device == 'LED' ? Icons.lightbulb : Icons.sensors,
                                              color: primaryColor,
                                            ),
                                            title: Text(
                                              log.message,
                                              style: const TextStyle(
                                                  fontSize: 16, color: textColor, fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Text(
                                              '$time - ${log.device} (${log.boardId})',
                                              style: const TextStyle(fontSize: 14, color: textColor),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }),
                            ],
                          );
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
