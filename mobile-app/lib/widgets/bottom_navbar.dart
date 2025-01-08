import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/navigation/navigation_bloc.dart';
import 'package:mobile_app/blocs/navigation/navigation_event.dart';
import 'package:mobile_app/blocs/navigation/navigation_state.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return BottomNavigationBar(
          currentIndex: state.selectedIndex,
          onTap: (index) {
            context.read<NavigationBloc>().add(PageTapped(index));
          },
          selectedIconTheme: const IconThemeData(size: 30),
          unselectedIconTheme: const IconThemeData(size: 22),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.devices),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: '',
            ),
          ],
        );
      },
    );
  }
}
