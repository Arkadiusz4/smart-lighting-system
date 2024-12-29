import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class AuthStarted extends AuthEvent {
  @override
  List<Object?> get props => [];
}

class AuthLoggedIn extends AuthEvent {
  final String email;
  final String password;

  const AuthLoggedIn({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegistered extends AuthEvent {
  final String email;
  final String password;

  const AuthRegistered({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthLoggedOut extends AuthEvent {
  @override
  List<Object?> get props => [];
}
