import 'package:bloc/bloc.dart';
import 'account_event.dart';
import 'account_state.dart';
import 'package:mobile_app/repositories/auth_repository.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AuthRepository _authRepository;

  AccountBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AccountInitial()) {
    on<AccountLogoutRequested>(_onLogoutRequested);
    on<AccountDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLogoutRequested(AccountLogoutRequested event, Emitter<AccountState> emit) async {
    emit(AccountLoading());
    try {
      await _authRepository.signOut();
      emit(const AccountSuccess('Wylogowano pomyślnie.'));
    } catch (e) {
      emit(AccountFailure('Błąd podczas wylogowania: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteRequested(AccountDeleteRequested event, Emitter<AccountState> emit) async {
    emit(AccountLoading());
    try {
      await _authRepository.deleteAccount();
      emit(const AccountSuccess('Konto zostało usunięte.'));
    } catch (e) {
      emit(AccountFailure('Błąd podczas usuwania konta: ${e.toString()}'));
    }
  }
}
