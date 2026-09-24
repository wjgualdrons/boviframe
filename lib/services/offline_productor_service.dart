import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OfflineProductorService {
  static final _box = Hive.box('offline_productores');

  static Future<void> guardarLocal(Map<String, dynamic> data) async {
    await _box.add(jsonEncode(data));
  }

  static Future<void> sincronizarPendientes() async {
    final items = _box.values.toList();
    for (var item in items) {
      final parsed = jsonDecode(item);
      try {
        await LocalFirestore.instance
            .collection('sesiones')
            .doc(parsed['sessionId'])
            .collection('datos_productor')
            .doc('info')
            .set(parsed);
        await _box.deleteAt(_box.values.toList().indexOf(item));
      } catch (_) {}
    }
  }
}



