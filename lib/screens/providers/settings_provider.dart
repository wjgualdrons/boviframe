import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  String? _userName;
  String? _userEmail;
  String? _userCompany;

  String get userName    => _userName    ?? '';
  String get userEmail   => _userEmail   ?? '';
  String get userCompany => _userCompany ?? '';

  /// Guarda o actualiza los datos del usuario (nombre, correo, empresa).
  void setUserData({
    required String name,
    required String email,
    required String company,
  }) {
    _userName    = name;
    _userEmail   = email;
    _userCompany = company;
    notifyListeners();
  }

  /// Limpia todos los datos (por ejemplo, al cerrar sesiÃ³n).
  void clear() {
    _userName = _userEmail = _userCompany = null;
    notifyListeners();
  }
}



