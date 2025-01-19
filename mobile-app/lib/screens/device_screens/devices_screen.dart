import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/boards/board_bloc.dart';
import 'package:mobile_app/blocs/boards/board_event.dart';
import 'package:mobile_app/blocs/boards/board_state.dart';
import 'package:mobile_app/screens/device_screens/boards/add_board_screen.dart';
import 'package:mobile_app/screens/device_screens/devices/devices_list_screen.dart';
import 'package:mobile_app/screens/device_screens/boards/edit_board_screen.dart';
import 'package:mobile_app/styles/color.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Zarządzanie Urządzeniami',
          style: TextStyle(
            color: textColor,
            fontSize: 24.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: darkBackground,
      ),
      body: BlocBuilder<BoardsBloc, BoardsState>(
        builder: (context, state) {
          if (state is BoardsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BoardsLoaded) {
            final boards = state.boards;
            if (boards.isEmpty) {
              return const Center(
                child: Text(
                  'Brak dodanych urządzeń.',
                  style: TextStyle(color: textColor),
                ),
              );
            }
            return ListView.builder(
              itemCount: boards.length,
              itemBuilder: (context, index) {
                final board = boards[index];
                return ListTile(
                  title: Text(
                    board.name.isNotEmpty ? board.name : board.boardId,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    board.room.isNotEmpty ? board.room : 'Nieprzypisany pokój',
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: primaryColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: BlocProvider.of<BoardsBloc>(context),
                                child: EditBoardScreen(board: board),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final devicesBloc = context.read<BoardsBloc>();

                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: darkBackground,
                                title: const Text(
                                  "Potwierdzenie",
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                content: const Text(
                                  "Czy na pewno chcesz usunąć to urządzenie?",
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      "Nie",
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      devicesBloc.add(RemoveBoard(board.boardId,userId, board.name));
                                    },
                                    child: const Text(
                                      "Tak",
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DevicesListScreen(userId: userId, boardId: board.boardId,  isPeripheral: board.peripheral),
                      ),
                    );
                  },
                );
              },
            );
          } else if (state is BoardsError) {
            return Center(
              child: Text(
                'Błąd: ${state.message}',
                style: const TextStyle(color: textColor),
              ),
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () {
          final boardsBloc = context.read<BoardsBloc>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                return BlocProvider.value(
                  value: boardsBloc,
                  child: const AddBoardScreen(),
                );
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
