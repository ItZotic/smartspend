import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService._internal()
      : _auth = FirebaseAuth.instance,
        _firestore = FirebaseFirestore.instance;

  factory AuthService() => _instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static final AuthService _instance = AuthService._internal();

  Future<User?> register(
    String email,
    String password, {
    Map<String, dynamic>? profileData,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set(
          {
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
            if (profileData != null) ...profileData,
          },
          SetOptions(merge: true),
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthException(e));
    } catch (_) {
      throw const AuthException('Failed to register. Please try again later.');
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthException(e));
    } catch (_) {
      throw const AuthException('Failed to login. Please try again later.');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _mapFirebaseAuthException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for the provided email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return exception.message ?? 'Authentication failed. Please try again.';
    }
  }
}
