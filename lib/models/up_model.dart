import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'evaluacion_model.dart';

class UnidadProduccion {
  final String nombre;
  final String direccion;
  final String estado;
  final String municipio;
  final String epoca;
  final String tipoExplotacion;
  final String manejo;
  final String planSanitario;
  final List<DateTime> fechasVacunacion;
  final List<EvaluacionAnimal> evaluaciones;

  UnidadProduccion({
    required this.nombre,
    required this.direccion,
    required this.estado,
    required this.municipio,
    required this.epoca,
    required this.tipoExplotacion,
    required this.manejo,
    required this.planSanitario,
    required this.fechasVacunacion,
    required this.evaluaciones,
  });
}



