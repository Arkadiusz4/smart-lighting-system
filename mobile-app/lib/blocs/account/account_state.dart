import 'package:equatable/equatable.dart';

abstract class AccountState extends Equatable {
  const AccountState();
}

class AccountInitial extends AccountState {
  @override
  List<Object?> get props => [];
}

class AccountLoading extends AccountState {
  @override
  List<Object?> get props => [];
}

class AccountSuccess extends AccountState {
  final String message;

  const AccountSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AccountFailure extends AccountState {
  final String error;

  const AccountFailure(this.error);

  @override
  List<Object?> get props => [error];
}
