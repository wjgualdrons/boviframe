import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';

class ConsultaAnimalScreen extends StatefulWidget {
  const ConsultaAnimalScreen({Key? key}) : super(key: key);

  @override
  State<ConsultaAnimalScreen> createState() => _ConsultaAnimalScreenState();
}

class _ConsultaAnimalScreenState extends State<ConsultaAnimalScreen> {
  final TextEditingController _rgnController = TextEditingController();
  final TextEditingController _sexoController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _sesionController = TextEditingController();

  bool _loading = true;
  String? _errorMsg;
  List<Map<String, dynamic>> _todosLosDocs = [];
  List<Map<String, dynamic>> _resultados = [];

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _cargarTodasLasEvaluaciones();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _rgnController.dispose();
    _sexoController.dispose();
    _estadoController.dispose();
    _sesionController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodasLasEvaluaciones() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
      _todosLosDocs.clear();
      _resultados.clear();
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      final sesionesSnapshot =
          await LocalFirestore.instance.collection('sesiones').get();

      final docsTotales = <Map<String, dynamic>>[];

      for (final sesionDoc in sesionesSnapshot.docs) {
        final evalSnapshot =
            await sesionDoc.reference
                .collection('evaluaciones_animales')
                .where('usuarioId', isEqualTo: userId)
                .get();

        for (final evalDoc in evalSnapshot.docs) {
          final data = <String, dynamic>{}..addAll(evalDoc.data());
          data['evalId'] = evalDoc.id;
          data['session_id'] = sesionDoc.id;
          data['numero_sesion'] =
              (sesionDoc.data()['numero_sesion'] ?? 'â€”').toString();
          docsTotales.add(data);
        }
      }

      if (!mounted) return;
      setState(() {
        _todosLosDocs = docsTotales;
        _resultados = List.from(_todosLosDocs);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Error cargando evaluaciones: $e';
        _loading = false;
      });
    }
  }

  Future<void> _buscarAnimales() async {
    final rgnFilter = _rgnController.text.trim();
    final sexoFilter = _sexoController.text.trim();
    final estadoFilter = _estadoController.text.trim();
    final sesionFilter = _sesionController.text.trim();

    if (rgnFilter.isEmpty &&
        sexoFilter.isEmpty &&
        estadoFilter.isEmpty &&
        sesionFilter.isEmpty) {
      setState(() {
        _resultados = List.from(_todosLosDocs);
      });
      return;
    }
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
      _resultados.clear();
    });

    try {
      final filtrados = <Map<String, dynamic>>[];

      for (final doc in _todosLosDocs) {
        final registro = (doc['registro'] ?? '').toString().trim();
        final sexo = (doc['sexo'] ?? '').toString().trim();
        final estado = (doc['estado'] ?? '').toString().trim();
        final sessionId = (doc['session_id'] ?? '').toString().trim();

        bool cumpleRgn = rgnFilter.isEmpty || registro == rgnFilter;
        bool cumpleSexo =
            sexoFilter.isEmpty ||
            sexo.toLowerCase() == sexoFilter.toLowerCase();
        bool cumpleEstado =
            estadoFilter.isEmpty ||
            estado.toLowerCase() == estadoFilter.toLowerCase();
        bool cumpleSes = sesionFilter.isEmpty || sessionId == sesionFilter;

        if (cumpleRgn && cumpleSexo && cumpleEstado && cumpleSes) {
          filtrados.add(doc);
        }
      }

      setState(() {
        _resultados = filtrados;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Error inesperado al filtrar: $e';
        _loading = false;
      });
    }
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Filtros adicionales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sexoController,
                  decoration: const InputDecoration(
                    labelText: 'Sexo (ej. Macho, Hembra)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _estadoController,
                  decoration: const InputDecoration(
                    labelText: 'Estado (ej. Toretes, Novillas, etc)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sesionController,
                  decoration: const InputDecoration(
                    labelText: 'SesiÃ³n (ID de la sesiÃ³n padre)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _buscarAnimales();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('APLICAR FILTROS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('CERRAR FILTROS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 224, 73, 62),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text(
          'Consultar Animal',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Busca por RGN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _rgnController,
                  decoration: const InputDecoration(
                    labelText: 'RGN (Registro Animal)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _mostrarFiltros,
                        icon: const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'FILTROS',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[500],
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _buscarAnimales,
                        icon: const Icon(Icons.search, color: Colors.white),
                        label: const Text(
                          'BUSCAR',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[500],
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_errorMsg != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_resultados.isEmpty
                        ? const Center(
                          child: Text('No se encontraron animales'),
                        )
                        : ListView.builder(
                          itemCount: _resultados.length,
                          itemBuilder: (context, index) {
                            final data = _resultados[index];
                            Uint8List? imageBytes;
                            final imageBase64 = data['image_base64'] as String?;
                            if (imageBase64 != null && imageBase64.isNotEmpty) {
                              try {
                                imageBytes = base64Decode(imageBase64);
                              } catch (_) {
                                imageBytes = null;
                              }
                            }
                            double puntuacion = 0;
                            {
                              final epm =
                                  data['epmuras'] as Map<String, dynamic>? ??
                                  {};
                              double suma = 0;
                              int conteo = 0;
                              epm.forEach((k, v) {
                                final val =
                                    double.tryParse(v?.toString() ?? '') ?? 0.0;
                                suma += val;
                                conteo++;
                              });
                              if (conteo > 0) puntuacion = suma / conteo;
                            }
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child:
                                        imageBytes != null
                                            ? Image.memory(
                                              imageBytes,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            )
                                            : Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Animal NÂº ${data['numero'] ?? '-'}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('RGN: ${data['registro'] ?? '-'}'),
                                        Text(
                                          'Sexo: ${data['sexo'] ?? '-'} Â· Estado: ${data['estado'] ?? '-'}',
                                        ),
                                        Text(
                                          'SesiÃ³n: ${data['numero_sesion'] ?? '-'}',
                                        ),
                                        Text(
                                          'PuntuaciÃ³n: ${puntuacion.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/animal_detail',
                                        arguments: data,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        )),
          ),
        ],
      ),
    );
  }
}



