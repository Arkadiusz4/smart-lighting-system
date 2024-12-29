import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/auth/auth_bloc.dart';
import 'package:mobile_app/blocs/auth/auth_event.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strona Główna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLoggedOut());
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Witaj, ${FirebaseAuth.instance.currentUser?.email}'),
      ),
    );
  }
}
