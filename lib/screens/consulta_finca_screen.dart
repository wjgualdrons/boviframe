import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sesiones_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class ConsultaFincaScreen extends StatefulWidget {
  const ConsultaFincaScreen({Key? key}) : super(key: key);

  @override
  State<ConsultaFincaScreen> createState() => _ConsultaFincaScreenState();
}

class _ConsultaFincaScreenState extends State<ConsultaFincaScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allFincas = [];
  List<Map<String, dynamic>> _filteredFincas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFincas();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFincas() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      List<Map<String, dynamic>> temp = [];

      if (userId != null) {
        final querySnapshot = await LocalFirestore.instance.collection('sesiones').get();

        for (final sessionDoc in querySnapshot.docs) {
          final sessionId = sessionDoc.id;
          final datosSnapshot = await sessionDoc.reference
              .collection('datos_productor')
              .where('userId', isEqualTo: userId)
              .get();

          for (final doc in datosSnapshot.docs) {
            final d = doc.data();
            final numSes = (sessionDoc.data()['numero_sesion'] ?? 'Lote').toString();

            temp.add({
              'unidad_produccion': d['unidad_produccion'] ?? '',
              'ubicacion': d['ubicacion'] ?? '',
              'municipio': d['municipio'] ?? '',
              'session_id': sessionId,
              'numero_sesion': numSes,
            });
          }
        }
      }

      final mapa = <String, Map<String, dynamic>>{};
      for (var item in temp) {
        final finca = item['unidad_produccion'] as String;
        if (finca.isNotEmpty) {
          mapa.putIfAbsent(
            finca,
            () => {
              'unidad_produccion': finca,
              'ubicacion': item['ubicacion'],
              'municipio': item['municipio'],
              'sesiones': <Map<String, dynamic>>[],
            },
          );
          (mapa[finca]!['sesiones'] as List).add({
            'session_id': item['session_id'],
            'numero_sesion': item['numero_sesion'],
          });
        }
      }

      var list = mapa.values.toList();
      if (list.isEmpty) {
        list = _getMockFincas();
      }

      if (!mounted) return;
      setState(() {
        _allFincas = list;
        _filteredFincas = List.from(_allFincas);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allFincas = _getMockFincas();
        _filteredFincas = List.from(_allFincas);
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getMockFincas() {
    return [
      {
        'unidad_produccion': 'Hacienda La Fundación',
        'ubicacion': 'Sector El Carmen • Ospino, Portuguesa',
        'municipio': 'Ospino',
        'sesiones': [
          {'session_id': 's1', 'numero_sesion': 'Manga Lote #01'},
          {'session_id': 's2', 'numero_sesion': 'Manga Lote #02'},
        ],
      },
      {
        'unidad_produccion': 'Finca El Socorro',
        'ubicacion': 'Vía Guanare • Barinas',
        'municipio': 'Barinas',
        'sesiones': [
          {'session_id': 's3', 'numero_sesion': 'Lote Vacas 2025'},
        ],
      },
      {
        'unidad_produccion': 'Agropecuaria San Jerónimo',
        'unidad_produccion_code': 'ASJ-40',
        'ubicacion': 'Sabana Dulce • Portuguesa',
        'municipio': 'Guanare',
        'sesiones': [],
      },
    ];
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFincas = List.from(_allFincas);
      } else {
        _filteredFincas = _allFincas.where((f) {
          final u = (f['unidad_produccion'] ?? '').toString().toLowerCase();
          final ub = (f['ubicacion'] ?? '').toString().toLowerCase();
          final m = (f['municipio'] ?? '').toString().toLowerCase();
          return u.contains(query) || ub.contains(query) || m.contains(query);
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
                      "Consultar Fincas",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF192A20),
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
                          // SEARCH BAR
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
                                    decoration: const InputDecoration(
                                      hintText: "Buscar por nombre de finca, ubicación o municipio...",
                                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // HEADER COUNTER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Predios Registrados (${_filteredFincas.length})",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF192A20),
                                ),
                              ),
                              const Text(
                                "Inventario & Lotes",
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // LIST OF FINCAS
                          if (_filteredFincas.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.agriculture_outlined, size: 40, color: Color(0xFF94A3B8)),
                                  SizedBox(height: 10),
                                  Text(
                                    "No se encontraron predios con ese criterio.",
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._filteredFincas.map((finca) => _buildFincaItem(finca)),
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

  Widget _buildFincaItem(Map<String, dynamic> finca) {
    final nombre = finca['unidad_produccion'] ?? 'Finca';
    final ubi = finca['ubicacion'] ?? 'Venezuela';
    final municipio = finca['municipio'] ?? '';
    final sesiones = finca['sesiones'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C4331),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF192A20),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$ubi ${municipio.isNotEmpty ? '• $municipio' : ''}",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${sesiones.length} Lotes",
                    style: const TextStyle(
                      color: Color(0xFF166534),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (sesiones.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SESIONES Y LOTES ASOCIADOS",
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sesiones.map<Widget>((s) {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SesionesScreen(
                                finca: nombre,
                                sesiones: sesiones.cast<Map<String, dynamic>>(),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.folder_open_rounded, size: 14, color: Color(0xFF166534)),
                              const SizedBox(width: 6),
                              Text(
                                s['numero_sesion'] ?? 'Lote',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
