import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boviframe/services/local_firestore.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class NewSessionScreen extends StatefulWidget {
  final String? sessionId;
  final dynamic numeroSesion;

  const NewSessionScreen({super.key, this.sessionId, this.numeroSesion});

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  late Future<int> _futureNumeroSesion;
  int _evaluadosCount = 6;
  int _porCalificarCount = 18;
  bool _mostrarCriterios = false;

  // Farm Data Form Controllers
  final _unidadController = TextEditingController();
  final _loteController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _municipioController = TextEditingController();
  String? _estadoSeleccionado;

  final List<String> _estadosVenezuela = const [
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

  @override
  void initState() {
    super.initState();
    _futureNumeroSesion = _generarNumeroSesion();
    _cargarDatosProductor();

    _unidadController.addListener(_guardarDatosProductor);
    _loteController.addListener(_guardarDatosProductor);
    _ubicacionController.addListener(_guardarDatosProductor);
    _municipioController.addListener(_guardarDatosProductor);
  }

  @override
  void dispose() {
    _unidadController.dispose();
    _loteController.dispose();
    _ubicacionController.dispose();
    _municipioController.dispose();
    super.dispose();
  }

  Future<int> _generarNumeroSesion() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 1;
    final snapshot = await LocalFirestore.instance
        .collection('sesiones')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.length : 1;
  }

  Future<void> _cargarDatosProductor() async {
    final sid = widget.sessionId;
    if (sid == null || sid.isEmpty) return;

    try {
      final snapshot = await LocalFirestore.instance
          .collection('sesiones')
          .doc(sid)
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

      final evalsSnap = await LocalFirestore.instance
          .collection('sesiones')
          .doc(sid)
          .collection('evaluaciones_animales')
          .get();

      setState(() {
        _evaluadosCount = evalsSnap.docs.length;
        _porCalificarCount = 24 - _evaluadosCount > 0 ? 24 - _evaluadosCount : 0;
      });
    } catch (_) {}
  }

  Future<void> _guardarDatosProductor() async {
    final sid = widget.sessionId;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (sid == null || sid.isEmpty || currentUser == null) return;

    final producerMap = {
      'unidad_produccion': _unidadController.text.trim(),
      'nombre_lote': _loteController.text.trim(),
      'ubicacion': _ubicacionController.text.trim(),
      'estado': _estadoSeleccionado ?? '',
      'municipio': _municipioController.text.trim(),
      'userId': currentUser.uid,
      'sessionId': sid,
    };

    try {
      await LocalFirestore.instance
          .collection('sesiones')
          .doc(sid)
          .set({
        'userId': currentUser.uid,
        'nombre_lote': _loteController.text.trim(),
      }, SetOptions(merge: true));

      await LocalFirestore.instance
          .collection('sesiones')
          .doc(sid)
          .collection('datos_productor')
          .doc('info del productor')
          .set(producerMap, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _futureNumeroSesion,
      builder: (context, snapshot) {
        final numeroSesion = snapshot.data ?? (widget.numeroSesion as int? ?? 1);
        final sessionCode = "2026-${numeroSesion.toString().padLeft(2, '0')}";

        return Scaffold(
          backgroundColor: const Color(0xFFF3F7F4),
          body: SafeArea(
            child: Column(
              children: [
                // TOP APP BAR
                _buildTopAppBar(),

                // MAIN CONTENT SCROLLABLE
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TOP STATUS BADGES
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF166534),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "SESIÓN ACTIVA #$sessionCode",
                                    style: const TextStyle(
                                      color: Color(0xFF166534),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2EFE7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.wifi_off_rounded,
                                    size: 13,
                                    color: Color(0xFF235C3F),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Offline",
                                    style: TextStyle(
                                      color: Color(0xFF235C3F),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // HEADLINE & SUBTITLE
                        const Text(
                          "Nueva Sesión",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF192A20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Verifica el predio registrado e inicia la evaluación fenotípica lineal EPMURAS en brete.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // STEP TRACKER ROW
                        _buildStepTracker(),
                        const SizedBox(height: 20),

                        // CARD 1: DATOS DEL PRODUCTOR (WITH FARM DATA FORM FIELDS INSIDE THE GREEN BOX)
                        _buildDatosProductorCard(),
                        const SizedBox(height: 16),

                        // CARD 2: EVALUACIÓN DEL ANIMAL (DARK GREEN HERO CARD)
                        _buildEvaluacionAnimalCard(numeroSesion),
                        const SizedBox(height: 18),

                        // BOTTOM CARD 1: MODO OFFLINE
                        _buildModoOfflineCard(),
                        const SizedBox(height: 12),

                        // BOTTOM CARD 2: TABLA RÁPIDA DE CRITERIOS (EXPANDABLE)
                        _buildTablaCriteriosCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // BOTTOM NAVIGATION BAR
                const CustomBottomNavBar(currentIndex: 2),
              ],
            ),
          ),
        );
      },
    );
  }

  // Top App Bar Widget
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF192A20),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Epmuras",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF192A20),
              ),
            ),
          ),
          // Help Button
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/theory'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFF475569),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Profile User Avatar
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/settings'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step Tracker Widget
  Widget _buildStepTracker() {
    return Row(
      children: [
        // Step 1 Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF166534), size: 16),
              SizedBox(width: 6),
              Text(
                "1. Predio y Productor",
                style: TextStyle(
                  color: Color(0xFF166534),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 20,
          height: 2,
          color: const Color(0xFFCBD5E1),
        ),
        const SizedBox(width: 8),
        // Step 2 Badge
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF192A20),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  "2",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              "Evaluación Morfométrica",
              style: TextStyle(
                color: Color(0xFF192A20),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Card 1: Datos del Productor / Finca
  Widget _buildDatosProductorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: Color(0xFF235C3F),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Datos del Productor",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF192A20),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check, size: 13, color: Color(0xFF166534)),
                    SizedBox(width: 4),
                    Text(
                      "Listo",
                      style: TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Ingrese la unidad de producción, ubicación geográfica y municipio de la finca.",
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Green Box containing Input Fields for Farm Data
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5EE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC3EAD5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.home_work_outlined, size: 16, color: Color(0xFF235C3F)),
                    SizedBox(width: 6),
                    Text(
                      "Datos de la Finca",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF192A20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Field 1: Unidad de Producción / Finca
                _buildCompactField(
                  controller: _unidadController,
                  hint: "Unidad de Producción / Finca (Ej: Hda. La Fundación)",
                  icon: Icons.agriculture_rounded,
                ),
                const SizedBox(height: 10),

                // Field 1.5: Nombre del Lote a Evaluar
                _buildCompactField(
                  controller: _loteController,
                  hint: "Nombre del Lote a Evaluar (Ej: Lote Toros Reproductores 2024)",
                  icon: Icons.assignment_outlined,
                ),
                const SizedBox(height: 10),

                // Field 2: Ubicación / Sector
                _buildCompactField(
                  controller: _ubicacionController,
                  hint: "Ubicación Geográfica / Sector",
                  icon: Icons.place_outlined,
                ),
                const SizedBox(height: 10),

                // Row: Estado & Municipio
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _estadoSeleccionado,
                            hint: const Text(
                              "Estado",
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF235C3F)),
                            items: _estadosVenezuela
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e, style: const TextStyle(fontSize: 12)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() => _estadoSeleccionado = val);
                              _guardarDatosProductor();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactField(
                        controller: _municipioController,
                        hint: "Municipio",
                        icon: Icons.location_city_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF192A20)),
        onChanged: (_) => _guardarDatosProductor(),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
          prefixIcon: Icon(icon, color: const Color(0xFF235C3F), size: 18),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // Card 2: Evaluación del Animal (Dark Green Hero Card)
  Widget _buildEvaluacionAnimalCard(int numSesion) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C4331),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C4331).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.military_tech_outlined, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      "PROTOCOLO EPMURAS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sensors_rounded, color: Color(0xFF4ADE80), size: 14),
                    SizedBox(width: 6),
                    Text(
                      "RFID Activo",
                      style: TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Title
          const Text(
            "Evaluación del Animal",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            "Calificación lineal zootécnica de 1 a 6: Estructura, Precocidad, Musculatura, Ombligo, Raza, Aplomos y Sexualidad.",
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),

          // 3 Stat Counter Boxes Row
          Row(
            children: [
              Expanded(
                child: _buildCounterBox(
                  count: "$_porCalificarCount",
                  label: "Por calificar",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCounterBox(
                  count: _evaluadosCount.toString().padLeft(2, '0'),
                  label: "Completados",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCounterBox(
                  count: "24",
                  label: "Lote Total",
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Action Button (Ingresar a Calificación en Brete ➔)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                await _guardarDatosProductor();
                if (!mounted) return;
                Navigator.pushNamed(
                  context,
                  '/animal_evaluation',
                  arguments: {
                    'sessionId': widget.sessionId,
                    'numeroSesion': numSesion,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Ingresar a Calificación en Brete",
                    style: TextStyle(
                      color: Color(0xFF1C4331),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF1C4331),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBox({
    required String count,
    required String label,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: highlight ? const Color(0xFF4ADE80) : Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Card 1: Modo Offline
  Widget _buildModoOfflineCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFF235C3F),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Modo Offline Local Autónomo",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF192A20),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Sin cobertura requerida. Sincronización automática...",
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Card 2: Tabla Rápida de Criterios (Expandable)
  Widget _buildTablaCriteriosCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: _mostrarCriterios,
        onExpansionChanged: (val) {
          setState(() => _mostrarCriterios = val);
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F3EC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Color(0xFF235C3F),
            size: 20,
          ),
        ),
        title: const Text(
          "Tabla Rápida de Criterios (Escala 1 a 6)",
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF192A20),
          ),
        ),
        subtitle: const Text(
          "Consultar definiciones morfológicas oficiales",
          style: TextStyle(
            fontSize: 11.5,
            color: Color(0xFF64748B),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "E - Estructura Corporal (1 al 6): Tamaño de osamenta y desarrollo del tórax.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                SizedBox(height: 6),
                Text(
                  "P - Precocidad Sexual (1 al 6): Capacidad de engrasamiento a menor edad.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                SizedBox(height: 6),
                Text(
                  "M - Musculatura (1 al 6): Grado de cobertura muscular en lomo y masa posterior.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                SizedBox(height: 6),
                Text(
                  "U - Ombligo / Prepucio (1 al 6): Tamaño y dirección del pliegue umbilical.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                SizedBox(height: 6),
                Text(
                  "R - Caracterización Racial (1 al 6): Pureza fenotípica del estándar de raza.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                SizedBox(height: 6),
                Text(
                  "A - Aplomos y Extremidades (1 al 6): Angulación de pesuños y patas.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                SizedBox(height: 6),
                Text(
                  "S - Sexualidad y Expresión (1 al 6): Dimorfismo sexual del ejemplar.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
