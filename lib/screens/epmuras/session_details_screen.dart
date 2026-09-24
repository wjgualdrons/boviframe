import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_app_scaffold.dart';

class SessionDetailsScreen extends StatefulWidget {
  @override
  _SessionDetailsScreenState createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  List<QueryDocumentSnapshot> sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    final snapshot = await LocalFirestore.instance
        .collection('sesiones')
        .where('uid', isEqualTo: uid)
        .orderBy('fechaEvaluacion', descending: true)
        .get();

    setState(() {
      sessions = snapshot.docs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomAppScaffold(
      title: 'Sesiones Registradas',
      currentIndex: 2,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : sessions.isEmpty
              ? const Center(child: Text('No hay sesiones registradas.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index].data() as Map<String, dynamic>;
                    final id = sessions[index].id;
                    final fecha = DateTime.tryParse(session['fechaEvaluacion'] ?? '');
                    final status = (session['cerrado'] ?? false) ? 'Cerrado' : 'Abierto';
                    final color = status == 'Cerrado' ? Colors.green : Colors.orange;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        onTap: () {
                          if (status == 'Abierto') {
                            Navigator.pushNamed(
                              context,
                              '/new_session',
                              arguments: {
                                ...session,
                                'session_id': id,
                              },
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Esta sesiÃ³n ya estÃ¡ cerrada.'),
                              ),
                            );
                          }
                        },
                        title: Text(
                          'Fecha: ${fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : 'Desconocida'}',
                        ),
                        subtitle: Text('Status: $status'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('NÂ° ${index + 1}'),
                            const SizedBox(width: 8),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 



