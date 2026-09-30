import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:boviframe/widgets/custom_bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _activeSegmentIndex = 0; // 0: Por Evaluación, 1: Por Categoría, 2: Por Índices

  List<Map<String, dynamic>> evaluaciones = [];
  int totalAnimales = 0;
  int totalSesiones = 0;
  Map<String, double> promedios = {};
  List<Map<String, dynamic>> topAnimales = [];
  List<Map<String, dynamic>> bottomAnimales = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarEvaluaciones();
  }

  Future<void> _cargarEvaluaciones() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      final sesionesSnapshot = await LocalFirestore.instance
          .collection('sesiones')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();

      final todosDatos = <Map<String, dynamic>>[];
      for (final ses in sesionesSnapshot.docs) {
        final evals = await ses.reference
            .collection('evaluaciones_animales')
            .where('usuarioId', isEqualTo: uid)
            .get();

        for (final e in evals.docs) {
          todosDatos.add({...e.data(), 'sessionId': ses.id});
        }
      }

      // 1) Calcular promedios de EPMURAS
      const letras = ['E', 'P', 'M', 'U', 'R', 'A', 'S'];
      final nuevosProm = {for (var l in letras) l: 0.0};
      for (var l in letras) {
        final suma = todosDatos.fold<double>(0.0, (sum, animal) {
          final v = animal['epmuras']?[l];
          return sum +
              (v is num
                  ? v.toDouble()
                  : double.tryParse(v?.toString() ?? '') ?? 0.0);
        });
        nuevosProm[l] = todosDatos.isEmpty ? 0.0 : suma / todosDatos.length;
      }

      // 2) Calcular índice y ordenar
      final listaIndice = todosDatos.map((animal) {
        final e = double.tryParse('${animal['epmuras']?['E']}') ?? 0;
        final p = double.tryParse('${animal['epmuras']?['P']}') ?? 0;
        final m = double.tryParse('${animal['epmuras']?['M']}') ?? 0;
        final u = double.tryParse('${animal['epmuras']?['U']}') ?? 0;
        final r = double.tryParse('${animal['epmuras']?['R']}') ?? 0;
        final a = double.tryParse('${animal['epmuras']?['A']}') ?? 0;
        final s = double.tryParse('${animal['epmuras']?['S']}') ?? 0;
        final totalEpm = (e + p + m + u + r + a + s) / 7.0;
        return {
          ...animal,
          'indice': totalEpm,
          'numero': animal['numero'] ?? '4921',
          'nombre': animal['nombre'] ?? '',
          'raza': animal['raza'] ?? 'Brahman',
          'categoria': animal['categoria'] ?? 'Toro',
          'epm_str': 'E:${e.toInt()} • P:${p.toInt()} • M:${m.toInt()} • R:${r.toInt()} • S:${s.toInt()}',
        };
      }).toList()
        ..sort(
          (a, b) => (b['indice'] as double).compareTo(a['indice'] as double),
        );

      if (!mounted) return;
      setState(() {
        evaluaciones = listaIndice;
        totalAnimales = todosDatos.length;
        totalSesiones = sesionesSnapshot.docs.length;
        promedios = nuevosProm;
        topAnimales = listaIndice.take(3).toList();
        bottomAnimales = listaIndice.reversed.take(3).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getEpmurasScores() {
    final defaultScores = [
      {
        'code': 'E',
        'label': 'Estructura Corporal',
        'defaultScore': 4.9,
        'color': const Color(0xFF1B4332),
      },
      {
        'code': 'P',
        'label': 'Precocidad (Acabado)',
        'defaultScore': 5.2,
        'color': const Color(0xFF10B981),
      },
      {
        'code': 'M',
        'label': 'Musculatura (Volumen)',
        'defaultScore': 4.7,
        'color': const Color(0xFF2D6A4F),
      },
      {
        'code': 'U',
        'label': 'Ombligo & Prepucio',
        'defaultScore': 4.6,
        'color': const Color(0xFF2D6A4F),
      },
      {
        'code': 'R',
        'label': 'Pureza Racial & Carácter',
        'defaultScore': 5.4,
        'color': const Color(0xFF10B981),
      },
      {
        'code': 'A',
        'label': 'Aplomos & Pezuñas',
        'defaultScore': 4.3,
        'color': const Color(0xFFF59E0B),
      },
      {
        'code': 'S',
        'label': 'Sexualidad & Dimorfismo',
        'defaultScore': 5.1,
        'color': const Color(0xFF10B981),
      },
    ];

    return defaultScores.map((item) {
      final code = item['code'] as String;
      final realVal = promedios[code];
      final score = (realVal != null && realVal > 0)
          ? double.parse(realVal.toStringAsFixed(1))
          : item['defaultScore'] as double;

      Color color = item['color'] as Color;
      if (score < 4.5) {
        color = const Color(0xFFF59E0B);
      } else if (score >= 5.0) {
        color = const Color(0xFF10B981);
      }

      return {
        'code': code,
        'label': item['label'],
        'score': score,
        'color': color,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FCF4),
      appBar: _buildTopAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarEvaluaciones,
          color: const Color(0xFF1B4332),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderTitle(),
                const SizedBox(height: 14),
                _buildFiltersRow(),
                const SizedBox(height: 16),
                _buildSegmentControl(),
                const SizedBox(height: 18),
                _buildSummaryKpiGrid(),
                const SizedBox(height: 18),
                _buildEpmurasChartCard(),
                const SizedBox(height: 16),
                _buildGeneticGainBanner(),
                const SizedBox(height: 18),
                _buildTopAnimalsSection(),
                const SizedBox(height: 18),
                _buildAlertAnimalsSection(),
                const SizedBox(height: 18),
                _buildHistoricalScoresCard(),
                const SizedBox(height: 20),
                _buildActionButtons(),
                const SizedBox(height: 14),
                _buildFooterVersion(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1B4332),
      elevation: 0,
      centerTitle: false,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/icons/logo1.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Boviframe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Índices / Dashboard',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFB7E4C7),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.layers_outlined, color: Color(0xFFD8F3DC), size: 14),
              SizedBox(width: 4),
              Text(
                'Lote 2024-B',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.only(right: 12),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.person_outline, color: Colors.white, size: 18),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.tune, color: Color(0xFF2D6A4F), size: 14),
                SizedBox(width: 5),
                Text(
                  'HATO BOVINO • ZOOTECNIA 4.0',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircleAvatar(radius: 3, backgroundColor: Color(0xFF2E7D32)),
                  SizedBox(width: 5),
                  Text(
                    'En línea',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Dashboard General &\nÍndices',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B4332),
            height: 1.15,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Análisis poblacional zootécnico y fenotípico integral',
          style: TextStyle(
            fontSize: 12.5,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersRow() {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Row(
                  children: [
                    Icon(Icons.groups_outlined, color: Color(0xFFD8F3DC), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Lote Toros 2024 (Todos)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD8E7DC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Icon(Icons.calendar_today_outlined, color: Color(0xFF1B4332), size: 14),
                SizedBox(width: 4),
                Text(
                  'Últimos 30 días',
                  style: TextStyle(
                    color: Color(0xFF1B4332),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Color(0xFF1B4332), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentControl() {
    final segments = ['Por Evaluación', 'Por Categoría', 'Por Índices'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5EFE7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(segments.length, (index) {
          final isSelected = _activeSegmentIndex == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () {
                setState(() {
                  _activeSegmentIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  segments[index],
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? const Color(0xFF1B4332) : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryKpiGrid() {
    final animalCount = totalAnimales > 0 ? '$totalAnimales' : '148';
    final sessionCount = totalSesiones > 0 ? '$totalSesiones' : '16';

    double avgIndex = 4.8;
    if (promedios.isNotEmpty) {
      final sum = promedios.values.fold(0.0, (a, b) => a + b);
      if (sum > 0) {
        avgIndex = double.parse((sum / promedios.length).toStringAsFixed(1));
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Animales Evaluados',
                icon: Icons.pets,
                iconColor: const Color(0xFF10B981),
                value: animalCount,
                unit: 'cab.',
                badgeText: '📈 +12% vs ciclo ant.',
                badgeBg: const Color(0xFFECFDF5),
                badgeTextColor: const Color(0xFF047857),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                title: 'Sesiones Manga',
                icon: Icons.sensors,
                iconColor: const Color(0xFF1B4332),
                value: sessionCount,
                unit: 'cerradas',
                badgeText: '✓ 100% RFID Sinc',
                badgeBg: const Color(0xFFF0FDF4),
                badgeTextColor: const Color(0xFF15803D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Índice EPMURAS',
                icon: Icons.verified_outlined,
                iconColor: const Color(0xFF1B4332),
                value: '$avgIndex',
                unit: '/ 6.0',
                badgeText: avgIndex >= 4.5 ? '★ Élite Superior' : '⚠ Promedio General',
                badgeBg: const Color(0xFFECFDF5),
                badgeTextColor: const Color(0xFF047857),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                title: 'Tasa Descarte',
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFDC2626),
                value: '2.1%',
                unit: 'hato',
                badgeText: '3 descalificados',
                badgeBg: const Color(0xFFFEF2F2),
                badgeTextColor: const Color(0xFFB91C1C),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EFE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              Icon(icon, color: iconColor, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B4332),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpmurasChartCard() {
    final scores = _getEpmurasScores();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EFE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Promedios EPMURAS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Puntaje lineal medio (Escala zootécnica 1 - 6)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F3E7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Meta:\n4.5',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B4332),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Stack(
            children: [
              // Línea de meta de 4.5 pts (4.5 / 6.0 = 75%)
              Positioned(
                top: 0,
                bottom: 0,
                left: 175,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Meta 4.5',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 1.5,
                        color: const Color(0xFFF59E0B).withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de barras por criterio
              Column(
                children: scores.map((item) {
                  final score = item['score'] as double;
                  final code = item['code'] as String;
                  final label = item['label'] as String;
                  final color = item['color'] as Color;
                  final percentage = (score / 6.0).clamp(0.0, 1.0);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // Avatar código
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: code == 'A'
                                ? const Color(0xFFB45309)
                                : const Color(0xFF1B4332),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Barra y etiqueta
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$score',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: color,
                                            fontFamily: 'Plus Jakarta Sans',
                                          ),
                                        ),
                                        const TextSpan(
                                          text: ' / 6.0',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: Color(0xFF9CA3AF),
                                            fontFamily: 'Plus Jakarta Sans',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  height: 7,
                                  width: double.infinity,
                                  color: const Color(0xFFE5E7EB),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: percentage,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const Divider(height: 18, color: Color(0xFFF3F4F6)),

          // Leyenda de rangos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendDot(const Color(0xFF10B981), '>5.0 Sobresaliente'),
              _buildLegendDot(const Color(0xFF1B4332), '>4.5 Óptimo'),
              _buildLegendDot(const Color(0xFFF59E0B), '<4.5 Ajustar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneticGainBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.trending_up, color: Color(0xFF74C69D), size: 16),
              SizedBox(width: 6),
              Text(
                'EVOLUCIÓN HISTÓRICA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFFB7E4C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Ganancia Zootécnica +0.4 pts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'El hato muestra mayor homogeneidad en aplomos y longitud corporal comparado con la zafra 2023.',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFFD8F3DC),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAnimalsSection() {
    final dynamicTop = topAnimales.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EFE7)),
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
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.military_tech_outlined, color: Color(0xFF059669), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Top 3 Ejemplares Élite',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                      Text(
                        'Mejores calificados para donantes y reproductores',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Top 1%',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (dynamicTop)
            ...topAnimales.asMap().entries.map((entry) {
              final idx = entry.key;
              final a = entry.value;
              final numArete = a['numero'] ?? '4921';
              final raza = a['raza'] ?? 'Brahman';
              final cat = a['categoria'] ?? 'Toro';
              final scoreVal = (a['indice'] as double).toStringAsFixed(1);
              final epmStr = a['epm_str'] ?? 'E:5 • P:6 • M:5 • R:6 • S:5';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildEliteItem(
                  rank: '${idx + 1}',
                  tag: '#$numArete $raza',
                  type: cat,
                  scores: epmStr,
                  finalScore: scoreVal,
                  highlight: idx == 0,
                ),
              );
            })
          else ...[
            _buildEliteItem(
              rank: '1',
              tag: '#4921 Nelore Master',
              type: 'Toro',
              scores: 'E:6 • P:6 • M:6 • R:6 • S:6',
              finalScore: '5.8',
              highlight: true,
            ),
            const SizedBox(height: 8),
            _buildEliteItem(
              rank: '2',
              tag: '#3108 Brahman Supreme',
              type: 'Vaca',
              scores: 'E:6 • P:5 • M:6 • R:6 • S:5',
              finalScore: '5.6',
              highlight: false,
            ),
            const SizedBox(height: 8),
            _buildEliteItem(
              rank: '3',
              tag: '#4950 Torete Brahman',
              type: 'Torete',
              scores: 'E:5 • P:6 • M:5 • R:6 • S:5',
              finalScore: '5.5',
              highlight: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEliteItem({
    required String rank,
    required String tag,
    required String type,
    required String scores,
    required String finalScore,
    required bool highlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFF2FCF4) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? const Color(0xFFB7E4C7) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: highlight ? const Color(0xFF1B4332) : const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              rank,
              style: TextStyle(
                color: highlight ? Colors.white : const Color(0xFF4B5563),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  scores,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                finalScore,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669),
                ),
              ),
              const Text(
                'pts EPM',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertAnimalsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EFE7)),
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
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications_active_outlined, color: Color(0xFFDC2626), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Ejemplares en Observación',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                      Text(
                        'Defectos descalificatorios o bajo índice',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '3 alertas',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Animal Crítico 1
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.priority_high, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '#2104 Toro Descarte Parcial',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B4332),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Alerta Crítica: Aplomo A=2 • Prepucio U=2',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          '2.8',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        Text(
                          'pts EPM',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/consulta_animal');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('Ver Ficha', style: TextStyle(fontSize: 10, color: Color(0xFF374151))),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/animal_evaluation');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEE2E2),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text(
                        'Reevaluar Manga',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Animal Alerta 2
          _buildAlertItem(
            index: '2',
            tag: '#1982 Novillo Tardío',
            cause: 'Baja precocidad (P=2.5) y musculatura deficiente',
            score: '3.1',
          ),
          const SizedBox(height: 8),

          // Animal Alerta 3
          _buildAlertItem(
            index: '3',
            tag: '#2055 Brahman Desbalanceado',
            cause: 'Prepucio péndulo excesivo (U=2.0)',
            score: '3.2',
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required String index,
    required String tag,
    required String cause,
    required String score,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              index,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cause,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const Text(
                'pts EPM',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalScoresCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EFE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.history, color: Color(0xFF1B4332), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Histórico de Calificaciones',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/theory'),
                child: Row(
                  children: const [
                    Text(
                      'Ver anterior',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D6A4F),
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.open_in_new, color: Color(0xFF2D6A4F), size: 13),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Compara los criterios zootécnicos actuales con los registros capturados durante la primera fase de pesaje y manga.',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF6B7280),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generando reporte PDF zootécnico...')),
                );
              },
              icon: const Icon(Icons.file_download_outlined, color: Color(0xFF1B4332), size: 18),
              label: const Text(
                'Exportar (PDF)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4332),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFD8E7DC), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/epmuras');
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
              label: const Text(
                'Nueva Sesión',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterVersion() {
    return const Center(
      child: Text(
        'Boviframe Pro • Zootecnia de Precisión • Versión 3.2.4',
        style: TextStyle(
          fontSize: 10.5,
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
