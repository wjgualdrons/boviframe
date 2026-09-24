
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? nombreUsuario;
  String? emailUsuario;
  String? empresaUsuario;

  // Por ejemplo, un mÃ©todo para cargar datos desde SettingsScreen:
  void actualizarDatos({
    required String nombre,
    required String email,
    required String empresa,
  }) {
    nombreUsuario = nombre;
    emailUsuario   = email;
    empresaUsuario = empresa;
    notifyListeners();
  }
}



