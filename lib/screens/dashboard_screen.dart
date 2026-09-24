import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boviframe/widgets/custom_bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> evaluaciones = [];
  int totalAnimales = 0;
  int totalSesiones = 0;
  Map<String, double> promedios = {};
  List<Map<String, dynamic>> topAnimales = [];
  List<Map<String, dynamic>> bottomAnimales = [];

  @override
  void initState() {
    super.initState();
    _cargarEvaluaciones();
  }

  Future<void> _cargarEvaluaciones() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final sesionesSnapshot =
        await LocalFirestore.instance
            .collection('sesiones')
            .where('userId', isEqualTo: uid) // Solo sesiones del usuario
            .orderBy('timestamp', descending: true)
            .get();

    final todosDatos = <Map<String, dynamic>>[];
    for (final ses in sesionesSnapshot.docs) {
      final evals =
          await ses.reference
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

    // 2) Calcular â€œÃ­ndiceâ€ y ordenar
    final listaIndice =
        todosDatos.map((animal) {
            final e = double.tryParse('${animal['epmuras']?['E']}') ?? 0;
            final p = double.tryParse('${animal['epmuras']?['P']}') ?? 0;
            final m = double.tryParse('${animal['epmuras']?['M']}') ?? 0;
            return {
              ...animal,
              'indice': e + p + m,
              'numero': animal['numero'] ?? '-',
              'nombre': animal['nombre'] ?? '', // <-- AÃ‘ADIDO
              'image_base64': animal['image_base64'],
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildMetricCard(
                    title: 'Animales Evaluados',
                    value: '$totalAnimales',
                    color: const Color(0xFF2EC4B6),
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    title: 'Total Sesiones',
                    value: '$totalSesiones',
                    color: const Color(0xFF4A90E2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Promedios EPMURAS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(height: 200, child: _buildBarChart()),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Top 3 Mejores Animales',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            ...topAnimales.asMap().entries.map((entry) {
              final index = entry.key;
              final animal = entry.value;
              return _buildAnimalCard(animal, isTop: true, index: index);
            }),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Top 3 Peores Animales',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            ...bottomAnimales.asMap().entries.map((entry) {
              final index = entry.key;
              final animal = entry.value;
              return _buildAnimalCard(animal, isTop: false, index: index);
            }),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentIndex: 4,
      ), // usa el index correspondiente
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
    color: Colors.blue[800],
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Dashboard General',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: SizedBox(
        height: 100,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalCard(
    Map<String, dynamic> a, {
    required bool isTop,
    required int index,
  }) {
    Uint8List? foto;
    final base = a['image_base64'] as String?;
    if (base != null && base.isNotEmpty) {
      foto = base64Decode(base);
    }

    final indice = (a['indice'] as double).toStringAsFixed(1);
    final color = isTop ? Colors.green[600] : Colors.red[600];

    final medalIconsTop = ['ðŸ¥‡', 'ðŸ¥ˆ', 'ðŸ¥‰'];
    final iconsBottom = ['âŒ', 'âš ï¸', 'ðŸ’€'];
    final leadingEmoji =
        isTop
            ? (index < medalIconsTop.length ? medalIconsTop[index] : 'â­ï¸')
            : (index < iconsBottom.length ? iconsBottom[index] : 'â—ï¸');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              if (foto != null)
                CircleAvatar(backgroundImage: MemoryImage(foto), radius: 28)
              else
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Text(
                      leadingEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),

        title: Text(
          a['nombre']?.toString()?.isNotEmpty == true
              ? a['nombre']
              : 'Animal #${a['numero'] ?? '-'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Icon(Icons.bar_chart, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                'Ãndice: $indice',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap:
            () => Navigator.pushNamed(context, '/animal_detail', arguments: a),
      ),
    );
  }

  BarChart _buildBarChart() {
    const letras = ['E', 'P', 'M', 'U', 'R', 'A', 'S'];
    final valores = letras.map((l) => promedios[l] ?? 0.0).toList();
    final maxY = ((valores.isEmpty ? 0.0 : valores.reduce(max)) + 1).clamp(
      6.0,
      10.0,
    );
    final interval = 1.0;

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceEvenly,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueAccent,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 3,
            ),
            tooltipMargin: 5,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)} pts',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 28,
              getTitlesWidget:
                  (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= letras.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    letras[idx],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine:
              (value) => FlLine(
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(valores.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: valores[i],
                width: 14,
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF3AC8F0), Color(0xFF0CA7E1)],
                ),
              ),
            ],
            showingTooltipIndicators: [0],
          );
        }),
      ),
    );
  }
}



