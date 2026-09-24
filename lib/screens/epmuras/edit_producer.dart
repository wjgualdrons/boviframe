// lib/screens/epmuras/edit_producer.dart

import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';

class EditProducerScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic>? initialData;

  const EditProducerScreen({
    Key? key,
    required this.sessionId,
    this.initialData,
  }) : super(key: key);

  @override
  State<EditProducerScreen> createState() => _EditProducerScreenState();
}

class _EditProducerScreenState extends State<EditProducerScreen> {
  final _unidadCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _municipioCtrl = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  void _loadInitial() {
    final data = widget.initialData;
    if (data != null) {
      _unidadCtrl.text = data['unidad_produccion']?.toString() ?? '';
      _ubicacionCtrl.text = data['ubicacion']?.toString() ?? '';
      _estadoCtrl.text = data['estado']?.toString() ?? '';
      _municipioCtrl.text = data['municipio']?.toString() ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _saveProducer() async {
    final map = <String, dynamic>{
      'unidad_produccion': _unidadCtrl.text.trim(),
      'ubicacion': _ubicacionCtrl.text.trim(),
      'estado': _estadoCtrl.text.trim(),
      'municipio': _municipioCtrl.text.trim(),
    };

    final col = LocalFirestore.instance
        .collection('sesiones')
        .doc(widget.sessionId)
        .collection('datos_productor');

    if (widget.initialData == null) {
      // crear nuevo doc
      await col.add(map);
    } else {
      // sobreescribir el primero
      final snapshot = await col.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.set(map);
      } else {
        await col.add(map);
      }
    }

    // Devolver datos actualizados al llamador
    Navigator.of(context).pop(map);
  }

  @override
  void dispose() {
    _unidadCtrl.dispose();
    _ubicacionCtrl.dispose();
    _estadoCtrl.dispose();
    _municipioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true, // Centra el tÃ­tulo
        title: const Text(
          'Editar Productor',
          style: TextStyle(color: Colors.white), // Color del texto blanco
        ),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _unidadCtrl,
              decoration: const InputDecoration(
                labelText: 'Unidad de ProducciÃ³n',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ubicacionCtrl,
              decoration: const InputDecoration(
                labelText: 'UbicaciÃ³n',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _estadoCtrl,
              decoration: const InputDecoration(
                labelText: 'Estado (Prod.)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _municipioCtrl,
              decoration: const InputDecoration(
                labelText: 'Municipio',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveProducer,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.green[500],
              ),
              child: const Text('Guardar', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}



