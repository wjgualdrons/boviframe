import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'dart:convert';
import '../widgets/custom_bottom_nav_bar.dart';

class IndiceScreen extends StatefulWidget {
  @override
  _IndiceScreenState createState() => _IndiceScreenState();
}

class _IndiceScreenState extends State<IndiceScreen> {
  List<Map<String, dynamic>> sesionesConDetalle = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSesionesConDetalle();
  }

  Future<void> _loadSesionesConDetalle() async {
    final firestore = LocalFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final sesionesSnapshot =
        await firestore
            .collection('sesiones')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();

    try {
      final List<Map<String, dynamic>> temp = [];

      for (final sesionDoc in sesionesSnapshot.docs) {
        final sessionId = sesionDoc.id;
        final sessionData = sesionDoc.data();
        final creadorId = sessionData['userId'] as String?;
        Map<String, dynamic>? creadorData;

        if (creadorId != null && creadorId.isNotEmpty) {
          final creadorSnap =
              await firestore.collection('usuarios').doc(creadorId).get();
          if (creadorSnap.exists) {
            creadorData = creadorSnap.data();
          }
        }

        Map<String, dynamic>? productorData;
        try {
          final prodSnapshot =
              await firestore
                  .collection('sesiones')
                  .doc(sessionId)
                  .collection('datos_productor')
                  .where('userId', isEqualTo: userId)
                  .get();

          if (prodSnapshot.docs.isNotEmpty) {
            productorData = prodSnapshot.docs.first.data();
          }
        } catch (_) {
          productorData = null;
        }

        final evalsSnapshot =
            await firestore
                .collection('sesiones')
                .doc(sessionId)
                .collection('evaluaciones_animales')
                .where('usuarioId', isEqualTo: userId)
                .orderBy('timestamp', descending: true)
                .get();

        final listaEvaluaciones =
            evalsSnapshot.docs.map((doc) {
              final data = doc.data();
              data['evalId'] = doc.id;
              return data;
            }).toList();

        temp.add({
          'sessionId': sessionId,
          'sessionData': sessionData,
          'productorData': productorData,
          'evaluaciones': listaEvaluaciones,
          'creadorNombre': creadorData?['nombre'] ?? '-',
          'creadorData': creadorData,
        });
      }

      if (!mounted) return;
      setState(() {
        sesionesConDetalle = temp;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar las sesiones: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error al cargar las sesiones: $e');
    }
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '-';
    final dt = ts.toDate();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ãndice de Sesiones y Evaluaciones',
          style: TextStyle(color: Colors.white, fontSize: 20),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : sesionesConDetalle.isEmpty
              ? const Center(child: Text('No hay sesiones registradas.'))
              : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sesionesConDetalle.length,
                itemBuilder: (context, index) {
                  final sesion = sesionesConDetalle[index];
                  final sessionData =
                      sesion['sessionData'] as Map<String, dynamic>;
                  final productorData =
                      sesion['productorData'] as Map<String, dynamic>?;
                  final evaluaciones =
                      sesion['evaluaciones'] as List<Map<String, dynamic>>;
                  final creadorNombre =
                      sesion['creadorNombre'] as String? ?? '-';
                  final fechaSesion =
                      sessionData['timestamp'] is Timestamp
                          ? _formatTimestamp(sessionData['timestamp'])
                          : '-';
                  final creadorData =
                      sesion['creadorData'] as Map<String, dynamic>?;
                  final creadorUbicacion = creadorData?['ubicacion'] ?? '-';

                  final fincaNombre =
                      productorData?['unidad_produccion']
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                          ? productorData!['unidad_produccion']
                          : '-';
                  final fincaUbicacion =
                      productorData?['ubicacion']
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                          ? productorData!['ubicacion']
                          : '-';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: ExpansionTile(
                      leading: const Icon(
                        Icons.folder_shared_rounded,
                        color: Colors.blue,
                      ),
                      title: Text(
                        fincaNombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Fecha: $fechaSesion\nUbicaciÃ³n: $creadorUbicacion\nCreado por: $creadorNombre',
                      ),
                      childrenPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      children: [
                        if (productorData != null) ...[
                          const Text(
                            'â”€â”€â”€ Datos del Productor â”€â”€â”€',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildDatoFila(
                            'Unidad producciÃ³n',
                            productorData['unidad_produccion'] ?? '-',
                          ),
                          _buildDatoFila(
                            'UbicaciÃ³n',
                            productorData['ubicacion'] ?? '-',
                          ),
                          _buildDatoFila(
                            'Estado',
                            productorData['estado'] ?? '-',
                          ),
                          _buildDatoFila(
                            'Municipio',
                            productorData['municipio'] ?? '-',
                          ),
                          const SizedBox(height: 12),
                        ] else ...[
                          const Text(
                            'â”€ No se encontraron datos del productor â”€',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          'â”€â”€â”€ Evaluaciones (${evaluaciones.length}) â”€â”€â”€',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (evaluaciones.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No hay evaluaciones para esta sesiÃ³n.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: evaluaciones.length,
                            separatorBuilder:
                                (context, i) => const Divider(height: 20),
                            itemBuilder: (context, i) {
                              final ev = evaluaciones[i];
                              final numero = ev['numero'] ?? '-';
                              final registro = ev['registro'] ?? '-';
                              final pesoNac = ev['peso_nac'] ?? '-';
                              final fechaEval =
                                  ev['timestamp'] is Timestamp
                                      ? _formatTimestamp(ev['timestamp'])
                                      : '-';

                              Widget iconFoto = const SizedBox(width: 48);
                              if (ev['image_base64'] != null) {
                                try {
                                  final bytes = base64Decode(
                                    ev['image_base64'],
                                  );
                                  iconFoto = ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.memory(
                                      bytes,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                } catch (_) {}
                              }

                              String epmSumario = '';
                              if (ev['epmuras'] is Map<String, dynamic>) {
                                final epm =
                                    ev['epmuras'] as Map<String, dynamic>;
                                epmSumario = epm.entries
                                    .map((e) => '${e.key}:${e.value}')
                                    .join('  ');
                              }

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: iconFoto,
                                title: Text(
                                  'NÂ° $numero  Â·  RGN $registro',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Peso Nac.: $pesoNac    Fecha: $fechaEval',
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'EPMURAS: $epmSumario',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                onTap:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/animal_detail',
                                      arguments: ev,
                                    ),
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildDatoFila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$etiqueta: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}



