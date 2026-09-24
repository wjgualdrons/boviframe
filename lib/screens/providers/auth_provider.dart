import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  late final FirebaseAuth _auth;

  AuthProvider() {
    _auth = FirebaseAuth.instance;
  }

  User? _user;
  User? get user => _user;

  Future<void> checkAuthState() async {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<String?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) { 
      return _handleFirebaseError(e);
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuario no registrado';
      case 'wrong-password':
        return 'ContraseÃ±a incorrecta';
      case 'invalid-email':
        return 'Correo electrÃ³nico invÃ¡lido';
      default:
        return 'Error de autenticaciÃ³n: ${e.message}';
    }
  }
}


