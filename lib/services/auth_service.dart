import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService()
      : _auth = FirebaseAuth.instance,
        _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<User?> register(String email, String password) async {
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
          },
          SetOptions(merge: true),
        );
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw Exception('Failed to register. Please try again later.');
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw Exception('Failed to login. Please try again later.');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
