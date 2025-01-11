import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/account/account_bloc.dart';
import 'package:mobile_app/blocs/boards/board_bloc.dart';
import 'package:mobile_app/blocs/boards/board_state.dart';
import 'package:mobile_app/blocs/navigation/navigation_bloc.dart';
import 'package:mobile_app/blocs/navigation/navigation_state.dart';
import 'package:mobile_app/repositories/auth_repository.dart';
import 'package:mobile_app/screens/home_screen/home_screen.dart';
import 'package:mobile_app/screens/device_screens/devices_screen.dart';
import 'package:mobile_app/screens/logs_screens/logs_screen.dart';
import 'package:mobile_app/screens/account_screens/account_screen.dart';
import 'package:mobile_app/widgets/bottom_navbar.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, navState) {
          switch (navState.selectedIndex) {
            case 0:
              final boardsBloc = context.watch<BoardsBloc>();
              final boardsState = boardsBloc.state;

              String? currentBoardId;
              String room = "Nieznany pokój";

              if (boardsState is BoardsLoaded && boardsState.currentBoardId != null && boardsState.boards.isNotEmpty) {
                currentBoardId = boardsState.currentBoardId;
                final selectedBoard = boardsState.boards.firstWhere(
                  (board) => board.boardId == currentBoardId,
                  orElse: () => boardsState.boards.first,
                );
                room = selectedBoard.room;
              }

              if (currentBoardId == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return HomeScreen(
                userId: userId,
                boardId: currentBoardId,
                room: room,
              );

            case 1:
              return const DevicesScreen();
            case 2:
              return const LogsScreen();
            case 3:
              return BlocProvider(
                create: (_) => AccountBloc(
                  authRepository: RepositoryProvider.of<AuthRepository>(context),
                ),
                child: const AccountScreen(),
              );
            default:
              return const Center(child: Text('Nieznany stan'));
          }
        },
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
