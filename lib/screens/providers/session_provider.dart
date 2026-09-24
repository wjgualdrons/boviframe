import 'dart:typed_data';
import 'package:flutter/material.dart';

class SessionProvider with ChangeNotifier {
  String? sessionId;
  Map<String, dynamic> _datosProductor = {};

  String? numero;
  String? registro;
  String? estadoAnimal;
  String? sexo;
  String? fechaNac;
  String? fechaDest;
  String? pesoNac;
  String? pesoDest;
  String? pesoAjus;
  String? edadDias;

  Map<String, String?> _epmuras = {
    'E': null,
    'P': null,
    'M': null,
    'U': null,
    'R': null,
    'A': null,
    'S': null,
  };
  Uint8List? imageBytes;

  VoidCallback? _resetEvaluationCallback;

  // Getters:
  Map<String, dynamic> get datosProductor => _datosProductor;
  Map<String, String?> get epmuras       => _epmuras;

  // Registrar callback para resetear UI de AnimalEvaluation
  void registerResetEvaluationForm(VoidCallback callback) {
    _resetEvaluationCallback = callback;
  }
  void triggerResetEvaluationForm() {
    if (_resetEvaluationCallback != null) {
      _resetEvaluationCallback!();
    }
  }

  // Setter: datos del productor completos
  void setDatosProductor(Map<String, dynamic> data) {
    _datosProductor = data;
    notifyListeners();
  }

  // Setter: datos del animal
  void setDatosAnimal({
    String? numero,
    String? registro,
    String? estadoAnimal,
    String? sexo,
    String? fechaNac,
    String? fechaDest,
    String? pesoNac,
    String? pesoDest,
    String? pesoAjus,
    String? edadDias,
  }) {
    this.numero       = numero;
    this.registro     = registro;
    this.estadoAnimal = estadoAnimal;
    this.sexo         = sexo;
    this.fechaNac     = fechaNac;
    this.fechaDest    = fechaDest;
    this.pesoNac      = pesoNac;
    this.pesoDest     = pesoDest;
    this.pesoAjus     = pesoAjus;
    this.edadDias     = edadDias;
    notifyListeners();
  }

  // Setter: epmuras
  void setEpmuras(Map<String, String?> ep) {
    _epmuras = ep;
    notifyListeners();
  }

  // Setter: foto en bytes
  void setImage(Uint8List? bytes) {
    imageBytes = bytes;
    notifyListeners();
  }

  // Limpiar solo los campos de evaluaciÃ³n (AnimalEvaluationScreen)
  void limpiarCamposEvaluacion() {
    numero       = null;
    registro     = null;
    estadoAnimal = null;
    sexo         = null;
    fechaNac     = null;
    fechaDest    = null;
    pesoNac      = null;
    pesoDest     = null;
    pesoAjus     = null;
    edadDias     = null;
    _epmuras.updateAll((key, value) => null);
    imageBytes = null;
    notifyListeners();
  }

  // Limpiar TODO: datosProductor + evaluaciÃ³n + sessionId
  void clearAll() {
    _datosProductor = {};
    limpiarCamposEvaluacion();
    sessionId = null;
    notifyListeners();
  }
}



