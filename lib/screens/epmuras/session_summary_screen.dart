import 'package:flutter/material.dart';
import 'report_screen_certificado.dart';
import 'exportar_resumen_grupal_pdf.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boviframe/services/local_firestore.dart';
import '../../widgets/custom_app_scaffold.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SessionSummaryScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> sessionData;

  const SessionSummaryScreen({
    Key? key,
    required this.sessionId,
    required this.sessionData,
  }) : super(key: key);

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  List<Map<String, dynamic>> evaluaciones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvaluations();
  }

  Future<void> _loadEvaluations() async {
    final snapshot = await LocalFirestore.instance
        .collection('evaluaciones')
        .where('session_id', isEqualTo: widget.sessionId)
        .get();

    final docs = snapshot.docs.map((doc) {
      final data = doc.data();
      data['doc_id'] = doc.id;
      return data;
    }).toList();

    setState(() {
      evaluaciones = docs;
      _loading = false;
    });
  }

  Map<String, double> calcularPromedios(List<Map<String, dynamic>> datos) {
    final letras = ['E', 'P', 'M', 'U', 'R', 'A', 'S'];
    final Map<String, double> suma = {for (var l in letras) l: 0};
    int total = datos.length;

    for (var item in datos) {
      for (var l in letras) {
        suma[l] = suma[l]! + (item[l] ?? 0);
      }
    }

    return {for (var l in letras) l: total > 0 ? suma[l]! / total : 0};
  }

  List<Map<String, dynamic>> calcularIndices(List<Map<String, dynamic>> datos) {
    return datos.map((animal) {
      final indice =
          (animal['E'] ?? 0) + (animal['P'] ?? 0) + (animal['M'] ?? 0);
      return {...animal, 'indice': indice};
    }).toList()
      ..sort((a, b) => b['indice'].compareTo(a['indice']));
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.sessionData['cerrado'] ?? false;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final usuario = await obtenerDatosUsuario();
              final evaluacionesConIndice = calcularIndices(evaluaciones);
              final mejor = evaluacionesConIndice.first;
              final peor = evaluacionesConIndice.last;
              final promedios = calcularPromedios(evaluaciones);
              exportarPDF(
                context,
                widget.sessionData,
                promedios,
                mejor,
                peor,
                usuario,
              );
            },
          ),
        ],
        title: const Text('Resumen de la SesiÃ³n'),
        backgroundColor: Colors.blue[800],
      ),
      floatingActionButton: isClosed
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/animal_data',
                  arguments: widget.sessionData,
                );
              },
              backgroundColor: Colors.purple,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : evaluaciones.isEmpty
              ? const Center(child: Text('No hay animales evaluados.'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Builder(
                        builder: (_) {
                          final evaluacionesConIndice =
                              calcularIndices(evaluaciones);
                          final mejor = evaluacionesConIndice.first;
                          final peor = evaluacionesConIndice.last;
                          final promedios = calcularPromedios(evaluaciones);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Promedios:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...promedios.entries.map(
                                (e) => Text(
                                  '${e.key}: ${e.value.toStringAsFixed(2)}',
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Mejor Animal: ${mejor['nombre']} (Ãndice: ${mejor['indice']})',
                              ),
                              Text(
                                'Peor Animal: ${peor['nombre']} (Ãndice: ${peor['indice']})',
                              ),
                              Divider(height: 24),
                              SizedBox(height: 24),
                              Text(
                                'GrÃ¡fica de Promedios:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 200,
                                child: BarChart(
                                  BarChartData(
                                    barGroups: promedios.entries.map((entry) {
                                      return BarChartGroupData(
                                        x: entry.key.codeUnitAt(0),
                                        barRods: [
                                          BarChartRodData(
                                            toY: entry.value,
                                            width: 20,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ],
                                        showingTooltipIndicators: [0],
                                      );
                                    }).toList(),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: true),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final letter = String.fromCharCode(
                                              value.toInt(),
                                            );
                                            return Text(letter);
                                          },
                                        ),
                                      ),
                                    ),
                                    gridData: FlGridData(show: false),
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: evaluaciones.length,
                        itemBuilder: (context, index) {
                          final data = evaluaciones[index];
                          final id = data['doc_id'];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  'assets/icons/logo1.png',
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.error,
                                      color: Colors.red,
                                    );
                                  },
                                ),
                              ),
                              title: Text(data['nombre'] ?? 'Sin nombre'),
                              subtitle: Text('ID: ${data['idAnimal'] ?? '-'}'),
                              trailing: !isClosed
                                  ? IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        final result = await Navigator.pushNamed(
                                          context,
                                          '/edit_evaluation',
                                          arguments: {
                                            ...data,
                                            'session_id': widget.sessionId,
                                            'doc_id': id,
                                          },
                                        );
                                        if (result == true) {
                                          _loadEvaluations();
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

Future<Map<String, dynamic>> obtenerDatosUsuario() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return {};

  final doc = await LocalFirestore.instance
      .collection('usuarios')
      .doc(currentUser.uid)
      .get();

  return doc.exists ? doc.data() ?? {} : {};
}

void exportarPDF(
  BuildContext context,
  Map<String, dynamic> sessionData,
  Map<String, double> promedios,
  Map<String, dynamic> mejor,
  Map<String, dynamic> peor,
  Map<String, dynamic> usuario,
) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'REPORTE GRUPAL DE EVALUACIÃ“N',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Datos del Usuario:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Nombre: ${usuario['nombre'] ?? '-'}'),
            pw.Text('ProfesiÃ³n: ${usuario['profesion'] ?? '-'}'),
            pw.Text('Colegio: ${usuario['colegio'] ?? '-'}'),
            pw.Text('UbicaciÃ³n: ${usuario['ubicacion'] ?? '-'}'),
            pw.SizedBox(height: 12),
            pw.Text('Nombre UP: ${sessionData['nombreUP'] ?? '-'}'),
            pw.Text('Estado: ${sessionData['estado'] ?? '-'}'),
            pw.Text('Municipio: ${sessionData['municipio'] ?? '-'}'),
            pw.Text('DirecciÃ³n: ${sessionData['direccion'] ?? '-'}'),
            pw.SizedBox(height: 12),
            pw.Text('Promedios EPMURAS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...promedios.entries.map((e) => pw.Text('${e.key}: ${e.value.toStringAsFixed(2)}')),
            pw.SizedBox(height: 12),
            pw.Text('Mejor Animal: ${mejor['nombre']} (Ãndice: ${mejor['indice']})'),
            pw.Text('Peor Animal: ${peor['nombre']} (Ãndice: ${peor['indice']})'),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}



