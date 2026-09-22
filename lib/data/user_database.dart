import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class UserDatabase {
  // Initialize or open the user's SQLite DB file and apply schema on first create
  static Future<Database> initUserDatabase(String userId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(docs.path, 'storage', 'db'));
    if (!await dbDir.exists()) await dbDir.create(recursive: true);

    final dbPath = p.join(dbDir.path, '$userId.sqlite');
    final exists = await File(dbPath).exists();

    final db = await openDatabase(dbPath, version: 1, onConfigure: (db) async {
      // Enable foreign keys
      await db.execute('PRAGMA foreign_keys = ON');
    });

    if (!exists) {
      // First time: load schema from assets and execute statements
      final sql = await rootBundle.loadString('db/schema.sqlite.sql');

      // Very simple splitter: split by semicolon and execute trimmed statements.
      // Note: for complex SQL containing semicolons in strings this may fail; keep schema simple.
      final statements = sql.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty);

      await db.transaction((txn) async {
        for (final stmt in statements) {
          try {
            await txn.execute(stmt);
          } catch (e) {
            // Ignore errors from comments or unsupported SQL fragments; log in dev.
            // print('DB init statement failed: $e');
          }
        }
      });

      // Insert owner row if table exists
      try {
        final now = DateTime.now().toUtc().toIso8601String();
        await db.insert('owner', {'id': userId, 'email': null, 'display_name': null, 'created_at': now}, conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (_) {
        // ignore
      }
    }

    return db;
  }

  // Helper to ensure DB is closed when not needed
  static Future<void> closeDb(Database db) async {
    try {
      await db.close();
    } catch (_) {}
  }
}
