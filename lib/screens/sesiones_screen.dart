import 'dart:convert';
import 'package:boviframe/services/local_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:boviframe/screens/animal_detail_screen.dart';

class SesionesScreen extends StatelessWidget {
  final String finca;

  /// Cada elemento tiene: 'session_id', 'numero_sesion' y opcionalmente 'image_base64'
  final List<Map<String, dynamic>> sesiones;

  const SesionesScreen({Key? key, required this.finca, required this.sesiones})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),

        title: Text(
          'Sesiones de $finca',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: sesiones.length,
        itemBuilder: (ctx, i) {
          final ses = sesiones[i];
          final numeroSes = ses['numero_sesion'] as String? ?? '';
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),

              // AquÃ­ mostramos la miniatura decodificada o un placeholder:
              leading: () {
                final b64 = ses['image_base64'] as String?;
                if (b64 != null && b64.isNotEmpty) {
                  try {
                    final bytes = base64Decode(b64);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        bytes,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    );
                  } catch (_) {
                    // decode fallÃ³, cae al placeholder
                  }
                }
                return const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                );
              }(),
              title: Text(
                '$numeroSes',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap:
                  () => _mostrarEvaluaciones(
                    context,
                    ses['session_id'] as String,
                    numeroSes,
                  ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _mostrarEvaluaciones(
    BuildContext context,
    String sessionId,
    String numeroSesion,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    final qs =
        await LocalFirestore.instance
            .collection('sesiones')
            .doc(sessionId)
            .collection('evaluaciones_animales')
            .where('usuarioId', isEqualTo: currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .get();

    print("Evaluaciones encontradas: ${qs.docs.length}");

    final evals =
        qs.docs.map((d) {
          final m = d.data();
          return {
            'numero': m['numero'] ?? '',
            'registro': m['registro'] ?? '',
            'sexo': m['sexo'] ?? '',
            'estado': m['estado'] ?? '',
            'fecha_nac': m['fecha_nac'] ?? '',
            'fecha_dest': m['fecha_dest'] ?? '',
            'peso_nac': m['peso_nac'] ?? '',
            'peso_dest': m['peso_dest'] ?? '',
            'peso_ajus': m['peso_ajus'] ?? '',
            'edad_dias': m['edad_dias'] ?? '',
            'epmuras': Map<String, dynamic>.from(m['epmuras'] ?? {}),
            'image_base64': m['image_base64'],
          };
        }).toList();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            title: Center(
              child: Text(
                'Evaluaciones $numeroSesion',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  evals.isEmpty
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No hay evaluaciones en esta sesiÃ³n.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: evals.length,
                        itemBuilder: (_, j) {
                          final e = evals[j];
                          final b64 = e['image_base64'] as String?;
                          Widget miniatura;
                          if (b64 != null && b64.isNotEmpty) {
                            try {
                              final bytes = base64Decode(b64);
                              miniatura = ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  bytes,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              );
                            } catch (_) {
                              miniatura = const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              );
                            }
                          } else {
                            miniatura = Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                              ),
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            );
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              leading: miniatura,
                              title: Text(
                                'Animal NÂ° ${e['numero']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text('RGN: ${e['registro']}'),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.blueAccent,
                              ),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            AnimalDetailScreen(animalData: e),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'CERRAR',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}



