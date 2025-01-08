import 'package:equatable/equatable.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();
}

class AccountLogoutRequested extends AccountEvent {
  @override
  List<Object?> get props => [];
}

class AccountDeleteRequested extends AccountEvent {
  @override
  List<Object?> get props => [];
}
