import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/boards/board_bloc.dart';
import 'package:mobile_app/blocs/boards/board_event.dart';
import 'package:mobile_app/blocs/boards/board_state.dart';
import 'package:mobile_app/repositories/boards_repository.dart';
import 'package:mobile_app/screens/edit_device_screen.dart';
import 'package:mobile_app/styles/color.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return BlocProvider(
      create: (context) => BoardsBloc(
        boardsRepository: BoardsRepository(),
        userId: userId,
      )..add(LoadBoards()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Zarządzanie Urządzeniami'),
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
                      style: const TextStyle(color: textColor),
                    ),
                    subtitle: Text(
                      board.room.isNotEmpty ? board.room : 'Nieprzypisany pokój',
                      style: const TextStyle(color: textColor),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: primaryColor),
                          onPressed: () {
                            final board = boards[index];
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                        value: BlocProvider.of<BoardsBloc>(context),
                                        child: EditDeviceScreen(board: board),
                                      )),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            final board = boards[index];
                            context.read<BoardsBloc>().add(RemoveBoard(board.boardId));
                          },
                        ),
                      ],
                    ),
                    onTap: () {},
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
            // Navigator.push(context, MaterialPageRoute(builder: (_) => AddBoardScreen()));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
