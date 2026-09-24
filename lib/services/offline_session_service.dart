import 'package:hive/hive.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class OfflineSessionService {
  /// Verifica conexiÃ³n real a internet
  static Future<bool> _hasRealInternetConnection() async {
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

  /// Guarda una evaluaciÃ³n offline cuando no hay internet
  static Future<String> saveEvaluationOffline({
    required Map<String, dynamic> evaluationData,
    required String sessionId,
  }) async {
    try {
      if (!Hive.isBoxOpen('offline_evaluaciones')) {
        await Hive.openBox('offline_evaluaciones');
      }

      final box = Hive.box('offline_evaluaciones');
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      
      final offlineId = DateTime.now().millisecondsSinceEpoch.toString();
      final offlineData = {
        'evaluationData': evaluationData,
        'sessionId': sessionId,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'uploaded': false,
        'id': offlineId,
      };

      await box.put(offlineId, offlineData);
      print('âœ… EvaluaciÃ³n guardada offline: $offlineId');
      return offlineId;
    } catch (e) {
      print('âŒ Error al guardar evaluaciÃ³n offline: $e');
      rethrow;
    }
  }

  /// ðŸ” Sube evaluaciones offline guardadas en Hive
  static Future<void> uploadOfflineSessions(String userId) async {
    final hasInternet = await _hasRealInternetConnection();
    if (!hasInternet) return;

    try {
      if (!Hive.isBoxOpen('offline_evaluaciones')) {
        await Hive.openBox('offline_evaluaciones');
      }

      final box = Hive.box('offline_evaluaciones');
      final entries = box.toMap().cast<dynamic, Map>();

      for (final entry in entries.entries) {
        final data = entry.value;

        if (data['uploaded'] == false && data['userId'] == userId) {
          try {
            final evaluationData = Map<String, dynamic>.from(data['evaluationData']);
            final sessionId = data['sessionId'] as String;

            // Asegurar que la sesiÃ³n existe
            await LocalFirestore.instance
                .collection('sesiones')
                .doc(sessionId)
                .set({
                  'userId': userId,
                  'timestamp': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

            // Subir evaluaciÃ³n a la subcolecciÃ³n correcta
            await LocalFirestore.instance
                .collection('sesiones')
                .doc(sessionId)
                .collection('evaluaciones_animales')
                .add(evaluationData);

            // Marcar como subido
            data['uploaded'] = true;
            await box.put(entry.key, data);

            print('âœ… EvaluaciÃ³n sincronizada: ${data['id']}');
          } catch (e) {
            print('âŒ Error al subir evaluaciÃ³n offline: $e');
          }
        }
      }
    } catch (e) {
      print('âŒ Error en sincronizaciÃ³n offline: $e');
    }
  }

  static Future<void> uploadOfflineCreatedSessions(String userId) async {
    final hasInternet = await _hasRealInternetConnection();
    if (!hasInternet) return;

    if (!Hive.isBoxOpen('offline_sesiones')) {
      await Hive.openBox('offline_sesiones');
    }

    final box = Hive.box('offline_sesiones');
    final entries = box.toMap().cast<dynamic, Map>();

    for (final entry in entries.entries) {
      final key = entry.key;
      final data = entry.value;

      if (data['uploaded'] == false && data['userId'] == userId) {
        try {
          final nextSession =
              await LocalFirestore.instance
                  .collection('sesiones')
                  .where('userId', isEqualTo: userId)
                  .get();
          final numeroSesion = nextSession.docs.length + 1;

          final docRef = await LocalFirestore.instance
              .collection('sesiones')
              .add({
                'userId': userId,
                'estado': 'activa',
                'fecha_creacion': DateTime.parse(data['timestamp']),
                'numero_sesion': 'SesiÃ³n $numeroSesion',
                'numero_sesion_int': numeroSesion,
              });

          data['uploaded'] = true;
          await box.put(key, data);

          print('âœ… SesiÃ³n sincronizada con ID Firestore: ${docRef.id}');
        } catch (e) {
          print('âŒ Error al subir sesiÃ³n offline: $e');
        }
      }
    }
  }
}



