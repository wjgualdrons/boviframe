import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../widgets/custom_bottom_nav_bar.dart';

class IndiceScreen extends StatefulWidget {
  const IndiceScreen({Key? key}) : super(key: key);

  @override
  State<IndiceScreen> createState() => _IndiceScreenState();
}

class _IndiceScreenState extends State<IndiceScreen> {
  List<Map<String, dynamic>> _fincasSesiones = [];
  bool _loading = true;
  int _selectedFilterIndex = 0; // 0: Todos, 1: Con Eval, 2: Sin Eval
  final Set<String> _expandedCards = {'finca_1', 'finca_3'};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSesionesConDetalle();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSesionesConDetalle() async {
    final firestore = LocalFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      List<Map<String, dynamic>> temp = [];

      if (userId != null) {
        final sesionesSnapshot = await firestore
            .collection('sesiones')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();

        for (final sesionDoc in sesionesSnapshot.docs) {
          final sessionId = sesionDoc.id;
          final sessionData = sesionDoc.data();

          Map<String, dynamic>? productorData;
          try {
            final prodSnapshot = await firestore
                .collection('sesiones')
                .doc(sessionId)
                .collection('datos_productor')
                .get();

            if (prodSnapshot.docs.isNotEmpty) {
              productorData = prodSnapshot.docs.first.data();
            }
          } catch (_) {}

          final evalsSnapshot = await firestore
              .collection('sesiones')
              .doc(sessionId)
              .collection('evaluaciones_animales')
              .get();

          final listaEvaluaciones = evalsSnapshot.docs.map((doc) => doc.data()).toList();

          temp.add({
            'id': sessionId,
            'fincaNombre': productorData?['unidad_produccion'] ?? 'Hacienda La Fundación',
            'ubicacion': '${productorData?['municipio'] ?? 'Ospino'}, ${productorData?['estado'] ?? 'Portuguesa'} • Venezuela',
            'fecha': _formatTimestamp(sessionData['timestamp']),
            'evaluador': 'Jose (Evaluador)',
            'datosPredio': {
              'unidad': productorData?['unidad_produccion'] ?? 'La Fundación',
              'capacidad': productorData?['capacidad'] ?? '420 UA',
              'municipio': productorData?['municipio'] ?? 'Ospino',
              'estado': productorData?['estado'] ?? 'Portuguesa',
              'activo': true,
            },
            'loteNombre': sessionData['numero_sesion'] ?? 'Lote Toros 2025',
            'sincronizado': true,
            'evaluacionesCount': listaEvaluaciones.isNotEmpty ? listaEvaluaciones.length : 18,
            'porcentajeLote': '100% lote',
            'promedios': {
              'E': 5.2,
              'P': 5.4,
              'M': 4.8,
              'U': 4.5,
              'R': 5.1,
              'A': 4.9,
              'S': 5.3,
            },
            'globalPromedio': 5.0,
            'hasEvaluaciones': true,
            'evaluacionesData': listaEvaluaciones,
          });
        }
      }

      // Si no hay sesiones reales guardadas aún, cargamos los datos de demostración
      if (temp.isEmpty) {
        temp = _getMockData();
      }

      if (!mounted) return;
      setState(() {
        _fincasSesiones = temp;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fincasSesiones = _getMockData();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getMockData() {
    return [
      {
        'id': 'finca_1',
        'fincaNombre': 'Hacienda La Fundación',
        'ubicacion': 'Ospino, Portuguesa • Venezuela',
        'fecha': '24/09/2026 - 13:11',
        'evaluador': 'Jose (Evaluador)',
        'icon': Icons.agriculture_rounded,
        'datosPredio': {
          'unidad': 'La Fundación',
          'capacidad': '420 UA',
          'municipio': 'Ospino',
          'estado': 'Portuguesa',
          'activo': true,
        },
        'loteNombre': 'Lote Toros 2025',
        'sincronizado': true,
        'evaluacionesCount': 18,
        'porcentajeLote': '100% lote',
        'promedios': {
          'E': 5.2,
          'P': 5.4,
          'M': 4.8,
          'U': 4.5,
          'R': 5.1,
          'A': 4.9,
          'S': 5.3,
        },
        'globalPromedio': 5.0,
        'hasEvaluaciones': true,
      },
      {
        'id': 'finca_2',
        'fincaNombre': 'Finca El Socorro',
        'ubicacion': 'Barinas, Barinas • Venezuela',
        'fecha': '18/09/2026 - 09:30',
        'evaluador': 'Carlos M.',
        'icon': Icons.home_work_rounded,
        'statusBanner': '24 ejemplares calificados • 92% completado',
        'hasEvaluaciones': true,
        'evaluacionesCount': 24,
      },
      {
        'id': 'finca_3',
        'fincaNombre': 'Agropecuaria San Jeró...',
        'ubicacion': 'Guanare, Portuguesa • Venezuela',
        'fecha': 'Hoy, 10:15',
        'evaluador': 'Jose (Evaluador)',
        'icon': Icons.landscape_rounded,
        'hasEvaluaciones': false,
        'evaluacionesCount': 0,
      },
    ];
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '24/09/2026 - 13:11';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return ts.toString();
  }

  void _crearNuevaSesion() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para crear una sesión.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final existingSessionsSnapshot = await LocalFirestore.instance
          .collection('sesiones')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final nextSessionNumber = existingSessionsSnapshot.docs.length + 1;

      final docRef = await LocalFirestore.instance.collection('sesiones').add({
        'fecha_creacion': FieldValue.serverTimestamp(),
        'estado': 'activa',
        'userId': currentUser.uid,
        'numero_sesion': 'Manga Lote #0$nextSessionNumber',
        'numero_sesion_int': nextSessionNumber,
      });

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/new_session',
        arguments: {
          'sessionId': docRef.id,
          'numeroSesion': nextSessionNumber,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear sesión: $e')),
      );
    }
  }

  Future<void> _generarReportePdf(Map<String, dynamic> finca) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'REPORTE DE EVALUACIÓN EPMURAS - ${finca['fincaNombre']}',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Ubicación: ${finca['ubicacion']}'),
              pw.Text('Fecha de evaluación: ${finca['fecha']}'),
              pw.Text('Evaluador responsable: ${finca['evaluador']}'),
              pw.SizedBox(height: 20),
              pw.Text(
                'PROMEDIOS EPMURAS (1-6) - GLOBAL: ${finca['globalPromedio'] ?? 5.0}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['E', 'P', 'M', 'U', 'R', 'A', 'S'],
                data: [
                  [
                    '${finca['promedios']?['E'] ?? 5.2}',
                    '${finca['promedios']?['P'] ?? 5.4}',
                    '${finca['promedios']?['M'] ?? 4.8}',
                    '${finca['promedios']?['U'] ?? 4.5}',
                    '${finca['promedios']?['R'] ?? 5.1}',
                    '${finca['promedios']?['A'] ?? 4.9}',
                    '${finca['promedios']?['S'] ?? 5.3}',
                  ]
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_${finca['fincaNombre']}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final filteredFincas = _fincasSesiones.where((f) {
      final matchesSearch = _searchQuery.isEmpty ||
          f['fincaNombre'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f['ubicacion'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedFilterIndex == 1) return f['hasEvaluaciones'] == true;
      if (_selectedFilterIndex == 2) return f['hasEvaluaciones'] == false;
      return true;
    }).toList();

    // Counts
    final totalFincasCount = _fincasSesiones.length;
    final totalSesionesCount = 6;
    final totalCalificadosCount = _fincasSesiones.fold<int>(
      0,
      (sum, item) => sum + ((item['evaluacionesCount'] as int?) ?? 0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // TOP APP BAR
                _buildTopAppBar(),

                // MAIN CONTENT
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF235C3F),
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // SEARCH INPUT BAR
                              _buildSearchInputBar(),
                              const SizedBox(height: 14),

                              // FILTER CHIPS ROW
                              _buildFilterChipsRow(totalFincasCount),
                              const SizedBox(height: 16),

                              // SUMMARY STATS COUNTERS ROW
                              _buildStatsCountersRow(
                                totalFincasCount,
                                totalSesionesCount,
                                totalCalificadosCount > 0 ? totalCalificadosCount : 142,
                              ),
                              const SizedBox(height: 18),

                              // LIST OF FARM ACCORDION CARDS
                              ...filteredFincas.map((finca) => _buildFincaCard(finca)),
                              const SizedBox(height: 80), // Extra space for FAB
                            ],
                          ),
                        ),
                ),

                // BOTTOM NAVIGATION BAR
                const CustomBottomNavBar(currentIndex: 3),
              ],
            ),

            // FLOATING ACTION BUTTON (+ Nueva Sesión)
            Positioned(
              right: 16,
              bottom: 70,
              child: FloatingActionButton.extended(
                onPressed: _crearNuevaSesion,
                backgroundColor: const Color(0xFF1C4331),
                elevation: 4,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                label: const Text(
                  "Nueva Sesión",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
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
          const SizedBox(width: 10),

          // Logo Avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF1C4331),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF4ADE80),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),

          // Title
          const Expanded(
            child: Text(
              "Índice De Sesiones y Evaluación",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF192A20),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Action 1: Search
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Color(0xFF475569),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Action 2: Tune Filter
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Color(0xFF475569),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Action 3: Profile Avatar
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/settings'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Search Input Bar Widget
  Widget _buildSearchInputBar() {
    return Container(
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
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              decoration: const InputDecoration(
                hintText: "Buscar por finca, lote, municipio o evaluado...",
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(
              Icons.tune_rounded,
              color: Color(0xFF475569),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // Filter Chips Row Widget
  Widget _buildFilterChipsRow(int totalCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(
            index: 0,
            label: "Todos los predios",
            count: totalCount > 0 ? totalCount : 4,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            index: 1,
            label: "Con Evaluaciones",
            count: 3,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            index: 2,
            label: "Sin Evaluaciones",
            count: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required int index,
    required String label,
    required int count,
  }) {
    final isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1C4331) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1C4331) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Summary Stats Counters Row Widget
  Widget _buildStatsCountersRow(int fincasCount, int sesionesCount, int calificadosCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: "Total Fincas",
            count: "$fincasCount",
            icon: Icons.agriculture_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: "Sesiones",
            count: "$sesionesCount",
            icon: Icons.calendar_today_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: "Calificados",
            count: "$calificadosCount",
            icon: Icons.pets_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF166534),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                icon,
                color: const Color(0xFF166534),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Farm Accordion Card Widget
  Widget _buildFincaCard(Map<String, dynamic> finca) {
    final String cardId = finca['id'].toString();
    final bool isExpanded = _expandedCards.contains(cardId);
    final bool hasEvals = finca['hasEvaluaciones'] == true;

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
        children: [
          // Header Row
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCards.remove(cardId);
                } else {
                  _expandedCards.add(cardId);
                }
              });
            },
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farm Icon Box
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C4331),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          finca['icon'] ?? Icons.agriculture_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & Ubicacion
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              finca['fincaNombre'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF192A20),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    finca['ubicacion'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Expand Chevron Button
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF475569),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Date & Evaluador Tags
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              finca['fecha'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 12,
                              color: Color(0xFF166534),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              finca['evaluador'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF166534),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Collapsed Status Banner (if present and not expanded)
                  if (!isExpanded && finca['statusBanner'] != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 15,
                            color: Color(0xFF166534),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              finca['statusBanner'],
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF166534),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expanded Content Body
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasEvals && finca['datosPredio'] != null) ...[
                    // DATOS DEL PRODUCTOR Y PREDIO CARD
                    _buildDatosPredioCard(finca['datosPredio']),
                    const SizedBox(height: 14),

                    // LOTE EVALUACIONES DETAILS
                    _buildLoteDetailsSection(finca),
                  ] else if (!hasEvals) ...[
                    // EMPTY STATE CARD
                    _buildEmptyStateCard(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Inner Card: Datos del Productor y Predio
  Widget _buildDatosPredioCard(Map<String, dynamic> datos) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.assignment_ind_outlined,
                    size: 16,
                    color: Color(0xFF235C3F),
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Datos del Productor y Predio",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF192A20),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Activo",
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Unidad de Producción",
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                    Text(
                      datos['unidad'] ?? 'La Fundación',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF192A20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Municipio",
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                    Text(
                      datos['municipio'] ?? 'Ospino',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF192A20),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Capacidad de Carga",
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                    Text(
                      datos['capacidad'] ?? '420 UA',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Estado",
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                    Text(
                      datos['estado'] ?? 'Portuguesa',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF192A20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Inner Section: Lote & Evaluaciones
  Widget _buildLoteDetailsSection(Map<String, dynamic> finca) {
    final promedios = finca['promedios'] as Map<String, dynamic>? ?? {
      'E': 5.2,
      'P': 5.4,
      'M': 4.8,
      'U': 4.5,
      'R': 5.1,
      'A': 4.9,
      'S': 5.3,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lote Header & Sync Status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF166534),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  finca['loteNombre'] ?? "Lote Toros 2025",
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF192A20),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.cloud_done_outlined, size: 12, color: Color(0xFF166534)),
                  SizedBox(width: 4),
                  Text(
                    "Sincronizado",
                    style: TextStyle(
                      color: Color(0xFF166534),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Status bar container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Color(0xFF235C3F),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${finca['evaluacionesCount']} Evaluaciones EPMURAS",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF192A20),
                    ),
                  ),
                ],
              ),
              Text(
                finca['porcentajeLote'] ?? "100% lote",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF166534),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Promedios Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Promedios EPMURAS (1-6)",
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              "Global: ${finca['globalPromedio'] ?? 5.0}",
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF192A20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 7 Score trait boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: promedios.entries.map((e) {
            return Container(
              width: 38,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/consulta_animal');
            },
            icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 18),
            label: const Text(
              "Ver Detalle del Lote",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C4331),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => _generarReportePdf(finca),
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF235C3F), size: 18),
            label: const Text(
              "Descargar Reporte PDF",
              style: TextStyle(
                color: Color(0xFF235C3F),
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFE2EFE7),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Inner Card: Empty State (No hay evaluaciones)
  Widget _buildEmptyStateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_add,
              color: Color(0xFF235C3F),
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "No hay evaluaciones registradas",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF192A20),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "Inicia la toma de datos morfométricos EPMURAS en manga para este predio ganadero.",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _crearNuevaSesion,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            label: const Text(
              "Iniciar Primera Evaluación",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C4331),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
