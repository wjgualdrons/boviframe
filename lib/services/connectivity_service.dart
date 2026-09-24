import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/database_service.dart';
import '../services/offline_session_service.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static Future<bool> hasRealInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) return false;

    try {
      final result = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return result.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

void iniciarEscuchaInternet() {
  Connectivity().onConnectivityChanged.listen((result) async {
    if (result != ConnectivityResult.none) {
      final tieneInternet =
          await ConnectivityService.hasRealInternetConnection();
      if (tieneInternet) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          // Sincronizar animales offline
          await DatabaseService.uploadOfflineEvaluations(userId);
          // Sincronizar evaluaciones offline
          await OfflineSessionService.uploadOfflineSessions(userId);
          // Sincronizar sesiones offline
          await OfflineSessionService.uploadOfflineCreatedSessions(userId);
          debugPrint('âœ… SincronizaciÃ³n offline completada');
        }
      }
    }
  });
}



