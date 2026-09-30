import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class DatosProductorScreen extends StatefulWidget {
  final String sessionId;

  const DatosProductorScreen({Key? key, required this.sessionId})
      : super(key: key);

  @override
  State<DatosProductorScreen> createState() => _DatosProductorScreenState();
}

class _DatosProductorScreenState extends State<DatosProductorScreen> {
  final _unidadController = TextEditingController();
  final _loteController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _municipioController = TextEditingController();
  String? _estadoSeleccionado;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cargarProductor();
  }

  Future<void> _cargarProductor() async {
    try {
      final snapshot = await LocalFirestore.instance
          .collection('sesiones')
          .doc(widget.sessionId)
          .collection('datos_productor')
          .get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          _unidadController.text = data['unidad_produccion']?.toString() ?? '';
          _loteController.text = data['nombre_lote']?.toString() ?? '';
          _ubicacionController.text = data['ubicacion']?.toString() ?? '';
          _municipioController.text = data['municipio']?.toString() ?? '';
          final st = data['estado']?.toString();
          if (st != null && _estadosVenezuela.contains(st)) {
            _estadoSeleccionado = st;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _unidadController.dispose();
    _loteController.dispose();
    _ubicacionController.dispose();
    _municipioController.dispose();
    super.dispose();
  }

  Future<void> _guardarProductorYContinuar() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isSaving = true);

    final produtorMap = {
      'unidad_produccion': _unidadController.text.trim(),
      'nombre_lote': _loteController.text.trim(),
      'ubicacion': _ubicacionController.text.trim(),
      'estado': _estadoSeleccionado ?? '',
      'municipio': _municipioController.text.trim(),
      'fecha_registro': FieldValue.serverTimestamp(),
      'userId': currentUser.uid,
      'sessionId': widget.sessionId,
    };

    Provider.of<SessionProvider>(
      context,
      listen: false,
    ).setDatosProductor(produtorMap);

    try {
      await LocalFirestore.instance
          .collection('sesiones')
          .doc(widget.sessionId)
          .set({
        'userId': currentUser.uid,
        'nombre_lote': _loteController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await LocalFirestore.instance
          .collection('sesiones')
          .doc(widget.sessionId)
          .collection('datos_productor')
          .doc('info del productor')
          .set(produtorMap);

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/animal_evaluation',
        arguments: {'sessionId': widget.sessionId},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar productor: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: SafeArea(
        child: Column(
          children: [
            // TOP APP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF192A20),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Datos del Productor",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF192A20),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2EFE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Paso 1 de 2",
                      style: TextStyle(
                        color: Color(0xFF235C3F),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // MAIN FORM SCROLLABLE
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Información del Predio",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF192A20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Completa estos datos para continuar con la evaluación fenotípica en manga.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildStyledTextField(
                        controller: _unidadController,
                        label: 'Unidad de Producción / Finca',
                        hint: 'Ej: Hacienda La Fundación',
                        icon: Icons.agriculture_rounded,
                      ),
                      const SizedBox(height: 16),

                      _buildStyledTextField(
                        controller: _loteController,
                        label: 'Nombre del Lote a Evaluar',
                        hint: 'Ej: Lote Toros Reproductores 2024',
                        icon: Icons.assignment_outlined,
                      ),
                      const SizedBox(height: 16),

                      _buildStyledTextField(
                        controller: _ubicacionController,
                        label: 'Ubicación Geográfica',
                        hint: 'Ej: Sector El Carmen',
                        icon: Icons.place_outlined,
                      ),
                      const SizedBox(height: 16),

                      _buildStyledDropdown(
                        label: 'Estado',
                        value: _estadoSeleccionado,
                        onChanged: (val) => setState(() => _estadoSeleccionado = val),
                      ),
                      const SizedBox(height: 16),

                      _buildStyledTextField(
                        controller: _municipioController,
                        label: 'Municipio',
                        hint: 'Ej: Ospino',
                        icon: Icons.location_city_outlined,
                      ),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _guardarProductorYContinuar,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          label: Text(
                            _isSaving ? "Guardando..." : "Guardar y Continuar",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C4331),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // BOTTOM NAVIGATION BAR
            const CustomBottomNavBar(currentIndex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF192A20),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14.5, color: Color(0xFF192A20)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF235C3F), size: 20),
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF235C3F), width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledDropdown({
    required String label,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF192A20),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: _estadosVenezuela
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF235C3F)),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF235C3F), size: 20),
            hintText: "Seleccionar estado",
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF235C3F), width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  final List<String> _estadosVenezuela = [
    'Amazonas',
    'Anzoátegui',
    'Apure',
    'Aragua',
    'Barinas',
    'Bolívar',
    'Carabobo',
    'Cojedes',
    'Delta Amacuro',
    'Distrito Capital',
    'Falcón',
    'Guárico',
    'Lara',
    'Mérida',
    'Miranda',
    'Monagas',
    'Nueva Esparta',
    'Portuguesa',
    'Sucre',
    'Táchira',
    'Trujillo',
    'La Guaira',
    'Yaracuy',
    'Zulia',
  ];
}
