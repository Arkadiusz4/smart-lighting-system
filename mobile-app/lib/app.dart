import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'repositories/auth_repository.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final AuthRepository _authRepository = AuthRepository();

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _authRepository,
      child: BlocProvider(
        create: (context) => AuthBloc(authRepository: _authRepository)..add(AuthStarted()),
        child: MaterialApp(
          title: 'Smart Lighting',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          routes: {
            '/login': (context) => LoginScreen(),
            '/register': (context) => RegisterScreen(),
            '/home': (context) => const HomeScreen(),
          },
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return const HomeScreen();
              } else if (state is AuthLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
