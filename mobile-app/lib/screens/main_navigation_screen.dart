import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/account/account_bloc.dart';
import 'package:mobile_app/blocs/navigation/navigation_bloc.dart';
import 'package:mobile_app/blocs/navigation/navigation_state.dart';
import 'package:mobile_app/repositories/auth_repository.dart';
import 'package:mobile_app/widgets/bottom_navbar.dart';
import 'home_screen.dart';
import 'devices_screen.dart';
import 'logs_screen.dart';
import 'account_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, state) {
          switch (state.selectedIndex) {
            case 0:
              return const HomeScreen();
            case 1:
              return const DevicesScreen();
            case 2:
              return const LogsScreen();
            case 3:
              return BlocProvider(
                create: (context) => AccountBloc(
                  authRepository: RepositoryProvider.of<AuthRepository>(context),
                ),
                child: const AccountScreen(),
              );
            default:
              return const HomeScreen();
          }
        },
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
