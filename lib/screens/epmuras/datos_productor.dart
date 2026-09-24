import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../widgets/custom_app_scaffold.dart';
import '../providers/session_provider.dart';

class DatosProductorScreen extends StatefulWidget {
  final String sessionId;

  const DatosProductorScreen({Key? key, required this.sessionId})
    : super(key: key);

  @override
  State<DatosProductorScreen> createState() => _DatosProductorScreenState();
}

class _DatosProductorScreenState extends State<DatosProductorScreen> {
  final _unidadController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _municipioController = TextEditingController();
  String? _estadoSeleccionado;

  Future<void> _guardarProductorYContinuar() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // 1) Armar el mapa con todos los campos del productor:
    final produtorMap = {
      'unidad_produccion': _unidadController.text.trim(),
      'ubicacion': _ubicacionController.text.trim(),
      'estado': _estadoSeleccionado ?? '',
      'municipio': _municipioController.text.trim(),
      'fecha_registro': FieldValue.serverTimestamp(), // opcional
      'userId': currentUser.uid,
      'sessionId': widget.sessionId,
    };

    // 2) Guardar localmente en el provider:
    Provider.of<SessionProvider>(
      context,
      listen: false,
    ).setDatosProductor(produtorMap);

    // 3) Escribir en Firestore en /sesiones/{sessionId}/datos_productor/info
    try {
      // 3a) Asegurarse de que la sesiÃ³n exista con userId + timestamp
      await LocalFirestore.instance
          .collection('sesiones')
          .doc(widget.sessionId)
          .set({
            'userId': currentUser.uid,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // 3b) Ahora guardo el documento â€œinfoâ€ con todos los datos del productor
      await LocalFirestore.instance
          .collection('sesiones')
          .doc(widget.sessionId)
          .collection('datos_productor')
          .doc('info del productor')
          .set(produtorMap);

      // 4) Navegar a la pantalla de EvaluaciÃ³n Animal
      Navigator.pushNamed(
        context,
        '/animal_evaluation',
        arguments: {'sessionId': widget.sessionId},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('âŒ Error al guardar productor: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomAppScaffold(
      currentIndex: 2,
      title: 'Datos del Productor',
      showBackButton: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            key: const ValueKey('formulario_productor'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'InformaciÃ³n del Productor',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Completa estos datos para continuar con la evaluaciÃ³n',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildCardField(
                'Unidad de ProducciÃ³n',
                _unidadController,
                Icons.home_work,
              ),
              const SizedBox(height: 16),

              _buildCardField('UbicaciÃ³n', _ubicacionController, Icons.place),
              const SizedBox(height: 16),

              _buildCardDropdown('Estado', _estadoSeleccionado, (val) {
                setState(() => _estadoSeleccionado = val);
              }),
              const SizedBox(height: 16),

              _buildCardField(
                'Municipio',
                _municipioController,
                Icons.location_city,
              ),
              const SizedBox(height: 30),

              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Guardar y continuar'),
                  onPressed: _guardarProductorYContinuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCardDropdown(
    String label,
    String? value,
    void Function(String?) onChanged,
  ) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: DropdownButtonFormField<String>(
        value: value,
        items:
            _estadosVenezuela
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.map),
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  final List<String> _estadosVenezuela = [
    'Amazonas',
    'AnzoÃ¡tegui',
    'Apure',
    'Aragua',
    'Barinas',
    'BolÃ­var',
    'Carabobo',
    'Cojedes',
    'Delta Amacuro',
    'Distrito Capital',
    'FalcÃ³n',
    'GuÃ¡rico',
    'Lara',
    'MÃ©rida',
    'Miranda',
    'Monagas',
    'Nueva Esparta',
    'Portuguesa',
    'Sucre',
    'TÃ¡chira',
    'Trujillo',
    'La Guaira',
    'Yaracuy',
    'Zulia',
  ];
}



