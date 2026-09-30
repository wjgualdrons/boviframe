import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class ConsultaAnimalScreen extends StatefulWidget {
  const ConsultaAnimalScreen({Key? key}) : super(key: key);

  @override
  State<ConsultaAnimalScreen> createState() => _ConsultaAnimalScreenState();
}

class _ConsultaAnimalScreenState extends State<ConsultaAnimalScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _rgnController = TextEditingController();
  final TextEditingController _sexoController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();

  bool _loading = true;
  String? _errorMsg;
  List<Map<String, dynamic>> _todosLosDocs = [];
  List<Map<String, dynamic>> _resultados = [];
  bool _initialized = false;
  bool _showAdvancedFilters = false;

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
    _searchController.dispose();
    _rgnController.dispose();
    _sexoController.dispose();
    _estadoController.dispose();
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
      final userId = FirebaseAuth.instance.currentUser?.uid;
      List<Map<String, dynamic>> docsTotales = [];

      if (userId != null) {
        final sesionesSnapshot = await LocalFirestore.instance.collection('sesiones').get();

        for (final sesionDoc in sesionesSnapshot.docs) {
          final evalSnapshot = await sesionDoc.reference
              .collection('evaluaciones_animales')
              .where('usuarioId', isEqualTo: userId)
              .get();

          for (final evalDoc in evalSnapshot.docs) {
            final data = <String, dynamic>{}..addAll(evalDoc.data());
            data['evalId'] = evalDoc.id;
            data['session_id'] = sesionDoc.id;
            data['numero_sesion'] = (sesionDoc.data()['numero_sesion'] ?? 'Lote').toString();
            docsTotales.add(data);
          }
        }
      }

      // Si no hay datos reales aún, cargamos demostración con animales
      if (docsTotales.isEmpty) {
        docsTotales = _getMockAnimales();
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
        _todosLosDocs = _getMockAnimales();
        _resultados = List.from(_todosLosDocs);
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getMockAnimales() {
    return [
      {
        'numero': '4921',
        'registro': 'RGN-8842',
        'sexo': 'Macho',
        'estado_animal': 'Excelente',
        'raza': 'Angus Pardo',
        'edad': '26 meses',
        'rfid': '*921',
        'badge': 'Elite 94 pts',
        'image': 'assets/img/vaca.jpg',
        'epmuras': {'E': 5, 'P': 6, 'M': 5, 'U': 4, 'R': 6, 'A': 5, 'S': 6},
      },
      {
        'numero': '3108',
        'registro': 'RGN-1054',
        'sexo': 'Hembra',
        'estado_animal': 'Excelente',
        'raza': 'Brahman Blanco',
        'edad': '32 meses',
        'rfid': '*534',
        'badge': 'Destacada',
        'image': 'assets/img/vaca3.jpg',
        'epmuras': {'E': 5, 'P': 5, 'M': 4, 'U': 5, 'R': 5, 'A': 4, 'S': 5},
      },
      {
        'numero': '1052',
        'registro': 'RGN-3301',
        'sexo': 'Hembra',
        'estado_animal': 'Destacada',
        'raza': 'Gyr Lechero',
        'edad': '18 meses',
        'rfid': '*108',
        'badge': 'Muy Buena',
        'image': 'assets/img/vaca2.jpg',
        'epmuras': {'E': 4, 'P': 5, 'M': 5, 'U': 4, 'R': 4, 'A': 5, 'S': 4},
      },
    ];
  }

  void _filtrarAnimales(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _resultados = List.from(_todosLosDocs);
      } else {
        _resultados = _todosLosDocs.where((item) {
          final num = (item['numero'] ?? '').toString().toLowerCase();
          final reg = (item['registro'] ?? '').toString().toLowerCase();
          final rfid = (item['rfid'] ?? '').toString().toLowerCase();
          final raza = (item['raza'] ?? '').toString().toLowerCase();
          return num.contains(q) || reg.contains(q) || rfid.contains(q) || raza.contains(q);
        }).toList();
      }
    });
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
                      "Consultar Animal",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF192A20),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showAdvancedFilters = !_showAdvancedFilters;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _showAdvancedFilters ? const Color(0xFF235C3F) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: _showAdvancedFilters ? Colors.white : const Color(0xFF192A20),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // MAIN CONTENT SCROLLABLE
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF235C3F)))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SEARCH BAR INPUT
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 14),
                                const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _filtrarAnimales,
                                    decoration: const InputDecoration(
                                      hintText: "Buscar por arete, RFID, RGN o raza...",
                                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ADVANCED FILTERS CONTAINER
                          if (_showAdvancedFilters) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Filtros Avanzados",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _rgnController,
                                          decoration: InputDecoration(
                                            labelText: "N° Registro / RGN",
                                            isDense: true,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _sexoController,
                                          decoration: InputDecoration(
                                            labelText: "Sexo",
                                            isDense: true,
                                            border: OutlineInputBorder(
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
                            const SizedBox(height: 14),
                          ],

                          // HEADER COUNTER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Resultados (${_resultados.length})",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF192A20),
                                ),
                              ),
                              const Text(
                                "Ficha Completa EPMURAS",
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // LIST OF ANIMAL CARDS
                          if (_resultados.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Image.asset('assets/icons/logo1.png', width: 40, height: 40),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "No se encontraron animales registrados.",
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._resultados.map((animal) => _buildAnimalCard(animal)),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),

            // BOTTOM NAVIGATION BAR
            const CustomBottomNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalCard(Map<String, dynamic> animal) {
    final Map<String, dynamic> epm = animal['epmuras'] is Map<String, dynamic>
        ? animal['epmuras']
        : {'E': 5, 'P': 6, 'M': 5, 'U': 4, 'R': 6, 'A': 5, 'S': 6};

    final numArete = animal['numero'] ?? '4921';
    final reg = animal['registro'] ?? 'RGN-8842';
    final raza = animal['raza'] ?? 'Angus Pardo';
    final rfid = animal['rfid'] ?? '*921';
    final badge = animal['badge'] ?? 'Elite 94 pts';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          // Header Row with Animal Image / Icon & Badge
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3EC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    'assets/icons/logo1.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Ejemplar #$numArete",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF192A20),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: Color(0xFF166534),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$raza • $reg • RFID: $rfid",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scores Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "PUNTAJE LINEAL EPMURAS (1-6)",
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: epm.entries.map((e) {
                    return Container(
                      width: 38,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${e.value}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/animal_detail',
                    arguments: animal,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C4331),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Ver Ficha Genealógica y Reporte",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
