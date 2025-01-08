import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/navigation/navigation_bloc.dart';
import 'repositories/auth_repository.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_navigation_screen.dart';

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final AuthRepository _authRepository = AuthRepository();

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _authRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(authRepository: _authRepository)..add(AuthStarted()),
          ),
          BlocProvider(
            create: (context) => NavigationBloc(),
          ),
        ],
        child: MaterialApp(
          title: 'Smart Lighting',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          routes: {
            '/login': (context) => LoginScreen(),
            '/register': (context) => RegisterScreen(),
          },
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              print('app.dart: Current AuthState: $state');
              if (state is AuthAuthenticated) {
                print('app.dart: Navigating to MainNavigationScreen for user: ${state.user.email}');
                return const MainNavigationScreen();
              } else if (state is AuthLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else {
                return LoginScreen();
              }
            },
          ),
        ),
      ),
    );
  }
}