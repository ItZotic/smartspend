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

  static AuthService get instance => _instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static final AuthService _instance = AuthService._internal();

  Future<User?> register(
    String email,
    String password, {
    Map<String, dynamic>? profileData,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set(
          {
            'email': normalizedEmail,
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
    final normalizedEmail = _normalizeEmail(email);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
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

  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthException(e));
    } catch (_) {
      throw const AuthException(
        'Failed to send password reset email. Please try again later.',
      );
    }
  }

  String _normalizeEmail(String email) => email.trim();

  String _mapFirebaseAuthException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'missing-email':
        return 'Please enter an email address.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for the provided email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'The provided credentials are invalid.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
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

