import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/user_database.dart';

class DbInitExample extends StatefulWidget {
  const DbInitExample({Key? key}) : super(key: key);

  @override
  State<DbInitExample> createState() => _DbInitExampleState();
}

class _DbInitExampleState extends State<DbInitExample> {
  String _status = 'idle';

  Future<void> _createForTestUser() async {
    setState(() => _status = 'initializing');

    // Simula registro: crear userId (puedes usar el real desde auth)
    final userId = const Uuid().v4();

    try {
      final db = await UserDatabase.initUserDatabase(userId);
      await db.close();
      setState(() => _status = 'created: $userId');
    } catch (e) {
      setState(() => _status = 'error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DB init example')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Status: $_status'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _createForTestUser,
            child: const Text('Create DB for test user'),
          ),
        ]),
      ),
    );
  }
}
