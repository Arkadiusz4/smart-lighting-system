import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth}) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<User?> signUp({required String email, required String password}) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      print('AuthRepository: User signed up with email ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      print('AuthRepository signUp Error: $e');
      throw Exception(e.toString());
    }
  }

  Future<User?> signIn({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      print('AuthRepository: User signed in with email ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      print('AuthRepository signIn Error: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      print('AuthRepository: User signed out');
    } catch (e) {
      print('AuthRepository signOut Error: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> deleteAccount() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
        print('AuthRepository: Account deleted');
      } else {
        throw Exception('No user logged in');
      }
    } catch (e) {
      print('AuthRepository deleteAccount Error: $e');
      throw Exception(e.toString());
    }
  }

  Stream<User?> get user => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;
}
