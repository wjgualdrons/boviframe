import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:boviframe/widgets/confirm_dialog.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:boviframe/screens/epmuras/edit_producer.dart';

class EditSessionScreen extends StatefulWidget {
  final String sessionId;
  const EditSessionScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  Map<String, dynamic>? _sessionData;
  Map<String, dynamic>? _producerData;
  List<QueryDocumentSnapshot>? _evaluaciones;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final sessSnap = await LocalFirestore.instance.collection('sesiones').doc(widget.sessionId).get();
    final prodQ = await LocalFirestore.instance.collection('sesiones').doc(widget.sessionId).collection('datos_productor').limit(1).get();
    final evalsQ = await LocalFirestore.instance.collection('sesiones').doc(widget.sessionId).collection('evaluaciones_animales').orderBy('timestamp', descending: true).get();

    if (!mounted) return;
    setState(() {
      _sessionData = sessSnap.data();
      _producerData = prodQ.docs.isEmpty ? null : prodQ.docs.first.data();
      _evaluaciones = evalsQ.docs;
      _loading = false;
    });
  }

  Future<void> _deleteEvaluation(String docId) async {
    final ok = await confirmDialog(
      context,
      title: 'Â¿Borrar evaluaciÃ³n?',
      content: 'Esto eliminarÃ¡ esta evaluaciÃ³n de forma permanente.',
    );
    if (!ok) return;

    await LocalFirestore.instance.collection('sesiones').doc(widget.sessionId).collection('evaluaciones_animales').doc(docId).delete();
    await _loadAll();
  }

  Future<void> _editProducer() async {
    if (_producerData == null) return;
    final updated = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProducerScreen(
          sessionId: widget.sessionId,
          initialData: _producerData!,
        ),
      ),
    );
    if (updated != null) {
      setState(() => _producerData = updated);
    }
  }

  Future<void> _toggleSessionState() async {
    final nuevo = _sessionData!['estado'] == 'cerrada' ? 'activa' : 'cerrada';
    await LocalFirestore.instance.collection('sesiones').doc(widget.sessionId).update({'estado': nuevo});
    setState(() => _sessionData!['estado'] = nuevo);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(nuevo == 'cerrada' ? 'SesiÃ³n cerrada.' : 'SesiÃ³n reabierta.')),
    );
  }

  Future<void> _deleteSession() async {
    final ok = await confirmDialog(
      context,
      title: 'Â¿Eliminar sesiÃ³n?',
      content: 'Esto eliminarÃ¡ la sesiÃ³n y todas sus evaluaciones.',
    );
    if (!ok) return;

    for (final doc in _evaluaciones!) {
      await doc.reference.delete();
    }
    await LocalFirestore.instance.collection('sesiones').doc(widget.sessionId).delete();

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SesiÃ³n eliminada.')));
  }

  @override
  Widget build(BuildContext ctx) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text('Editar SesiÃ³n', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.blue.shade50,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: const Text(
                  'Datos del Productor',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                ),
                subtitle: _producerData == null
                    ? const Text('No hay datos')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text('Unidad: ${_producerData!['unidad_produccion'] ?? '-'}'),
                          Text('UbicaciÃ³n: ${_producerData!['ubicacion'] ?? '-'}'),
                          Text('Estado: ${_producerData!['estado'] ?? '-'}'),
                          Text('Municipio: ${_producerData!['municipio'] ?? '-'}'),
                        ],
                      ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: _editProducer,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Evaluaciones (${_evaluaciones?.length ?? 0}):',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _evaluaciones == null || _evaluaciones!.isEmpty
                  ? const Center(child: Text('Sin evaluaciones'))
                  : ListView.builder(
                      itemCount: _evaluaciones!.length,
                      itemBuilder: (_, idx) {
                        final doc = _evaluaciones![idx];
                        final data = doc.data() as Map<String, dynamic>;
                        Uint8List? img;
                        final b64 = data['image_base64'] as String?;
                        if (b64?.isNotEmpty ?? false) img = base64Decode(b64!);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 4,
                          child: ListTile(
                            leading: img != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.memory(
                                      img,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset('assets/icons/logo1.png', width: 40, height: 40),
                            title: Text('NÂ° ${data['numero'] ?? '-'}'),
                            subtitle: Text('RGN ${data['registro'] ?? '-'}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/edit_evaluation',
                                      arguments: {
                                        'sessionId': widget.sessionId,
                                        'docId': doc.id,
                                        'initialData': data,
                                      },
                                    ).then((_) => _loadAll());
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _deleteEvaluation(doc.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            Column(
              children: [
                ElevatedButton(
                  onPressed: _toggleSessionState,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: Text(
                    _sessionData?['estado'] == 'cerrada' ? 'Reabrir sesiÃ³n' : 'Cerrar sesiÃ³n',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _deleteSession,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Eliminar sesiÃ³n',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



