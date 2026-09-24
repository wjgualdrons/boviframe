import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_firestore.dart';

/// Application persistence facade. All records are stored in the authenticated
/// user's local Hive database through [LocalFirestore].
class DatabaseService {
  final LocalFirestore _database = LocalFirestore.instance;

  Future<String?> saveAnimal(Map<String, dynamic> animalData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Debes iniciar sesión para guardar datos.';
    await _database.collection('animals').add({...animalData, 'userId': user.uid, 'createdAt': Timestamp.now()});
    return null;
  }

  Stream<QuerySnapshot> getAnimals({String? upId, int limit = 10}) {
    Query query = _database.collection('animals').limit(limit);
    if (upId != null) query = query.where('up_id', isEqualTo: upId);
    return query.snapshots();
  }

  Future<void> deleteAnimal(String animalId) => _database.collection('animals').doc(animalId).delete();

  Future<String?> saveEvaluationRTDB(Map<String, dynamic> evaluationData) async {
    try { await _database.collection('evaluaciones').add(evaluationData); return null; }
    catch (error) { debugPrint('Error al guardar evaluación local: $error'); return error.toString(); }
  }

  Stream<QuerySnapshot> getEvaluationsRTDB() => _database.collection('evaluaciones').snapshots();
  Future<void> deleteEvaluationRTDB(String evaluationId) => _database.collection('evaluaciones').doc(evaluationId).delete();

  Future<String?> saveAnimalWithEvaluation({required Map<String, dynamic> animalData, required Map<String, dynamic> evaluationData}) async {
    try {
      final animal = await _database.collection('animals').add(animalData);
      await _database.collection('evaluaciones').doc(animal.id).set({...evaluationData, 'animal_id': animal.id, 'created_at': DateTime.now().toIso8601String()});
      return null;
    } catch (error) { return error.toString(); }
  }

  static Future<void> uploadOfflineEvaluations(String userId) async {}
}

