import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/navigation/navigation_bloc.dart';
import 'package:mobile_app/blocs/navigation/navigation_event.dart';
import 'package:mobile_app/blocs/navigation/navigation_state.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    print('BottomNavBar: Building');
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return BottomNavigationBar(
          currentIndex: state.selectedIndex,
          onTap: (index) {
            print('BottomNavBar: tapped index $index');
            context.read<NavigationBloc>().add(PageTapped(index));
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Główny',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.devices),
              label: 'Urządzenia',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Logi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Konto',
            ),
          ],
        );
      },
    );
  }
}
