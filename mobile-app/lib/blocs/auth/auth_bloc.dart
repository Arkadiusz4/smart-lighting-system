import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoggedIn>(_onLoggedIn);
    on<AuthRegistered>(_onRegistered);
    on<AuthLoggedOut>(_onLoggedOut);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final User? user = _authRepository.currentUser;
    if (user != null) {
      print('AuthStarted: User is authenticated');
      emit(AuthAuthenticated(user: user));
    } else {
      print('AuthStarted: User is unauthenticated');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedIn(AuthLoggedIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    print('AuthLoggedIn: Attempting to log in user with email ${event.email}');
    try {
      final User? user = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      if (user != null) {
        print('AuthLoggedIn: User logged in');
        emit(AuthAuthenticated(user: user));
      } else {
        print('AuthLoggedIn: User is unauthenticated');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      print('AuthLoggedIn Error: $e');
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegistered(AuthRegistered event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    print('AuthRegistered: Attempting to register user with email ${event.email}');
    try {
      final User? user = await _authRepository.signUp(
        email: event.email,
        password: event.password,
      );
      if (user != null) {
        print('AuthRegistered: User registered and authenticated');
        await createUserDocument(user.uid);
        emit(AuthAuthenticated(user: user));
      } else {
        print('AuthRegistered: User is unauthenticated');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      print('AuthRegistered Error: $e');
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLoggedOut(AuthLoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    print('AuthLoggedOut: Attempting to log out user');
    try {
      await _authRepository.signOut();
      print('AuthLoggedOut: User logged out');
      emit(AuthUnauthenticated());
    } catch (e) {
      print('AuthLoggedOut Error: $e');
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> createUserDocument(String userId, {Map<String, dynamic>? additionalData}) async {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userDocRef.set({
      ...?additionalData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createEmptyBoard(String userId) async {
    final boardsCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection('boards');
    await boardsCollection.doc('placeholder').set({
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
