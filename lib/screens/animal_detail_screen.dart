import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import '../services/pdf_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> animalData;
  const AnimalDetailScreen({Key? key, required this.animalData})
    : super(key: key);

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  late Map<String, double> epmuras, pesos;
  Map<String, double> epmProm = {}, pesProm = {};
  Map<String, dynamic>? producer;

  final GlobalKey _animalImageKey = GlobalKey();
  final GlobalKey _radarKey = GlobalKey();
  final GlobalKey _barKey = GlobalKey();

  List<Map<String, dynamic>> historialEvaluaciones = [];

  Future<void> loadHistorial() async {
    final registro = widget.animalData['registro'];
    final sessionId = widget.animalData['sessionId'];

    if (sessionId == null || registro == null) return;

    final snapshot =
        await LocalFirestore.instance
            .collection('sesiones')
            .doc(sessionId)
            .collection('evaluaciones_animales')
            .where('registro', isEqualTo: registro)
            .orderBy('timestamp', descending: true) // Usa el campo correcto
            .get();

    if (mounted) {
      setState(() {
        historialEvaluaciones = snapshot.docs.map((e) => e.data()).toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _prepareData();
    _loadPromedios();
    _loadProducer();
    loadHistorial();
    print("Historial cargado: ${historialEvaluaciones.length}");
  }

  void _prepareData() {
    final raw = (widget.animalData['epmuras'] as Map<String, dynamic>?) ?? {};
    epmuras = {
      for (var k in ['E', 'P', 'M', 'U', 'R', 'A', 'S'])
        k: double.tryParse(raw[k]?.toString() ?? '0') ?? 0.0,
    };
    pesos = {
      'Nac.':
          double.tryParse(widget.animalData['peso_nac']?.toString() ?? '0') ??
          0.0,
      'Dest.':
          double.tryParse(widget.animalData['peso_dest']?.toString() ?? '0') ??
          0.0,
      'Ajus.':
          double.tryParse(widget.animalData['peso_ajus']?.toString() ?? '0') ??
          0.0,
    };
  }

  Future<void> _loadPromedios() async {
    final sid = widget.animalData['sessionId'] as String?;
    if (sid == null) return;

    final docs =
        await LocalFirestore.instance
            .collection('sesiones')
            .doc(sid)
            .collection('evaluaciones_animales')
            .get();

    // Mapea etiqueta â†’ nombre de campo real
    final fieldNames = {
      'Nac.': 'peso_nac',
      'Dest.': 'peso_dest',
      'Ajus.': 'peso_ajus',
    };

    // Inicializa sumas
    final sumsE = {for (var k in epmuras.keys) k: 0.0};
    final sumsP = {for (var k in fieldNames.keys) k: 0.0};

    for (var d in docs.docs) {
      final m = d.data();
      // Sumo EPMURAS igual que antesâ€¦
      final raw = (m['epmuras'] as Map<String, dynamic>?) ?? {};
      sumsE.forEach((k, _) {
        sumsE[k] =
            sumsE[k]! + (double.tryParse(raw[k]?.toString() ?? '0') ?? 0.0);
      });

      // Sumo pesos usando el mapeo correcto
      sumsP.forEach((label, _) {
        final field = fieldNames[label]!;
        sumsP[label] =
            sumsP[label]! +
            (double.tryParse(m[field]?.toString() ?? '0') ?? 0.0);
      });
    }

    if (docs.docs.isNotEmpty) {
      setState(() {
        epmProm = {for (var k in sumsE.keys) k: sumsE[k]! / docs.docs.length};
        pesProm = {for (var k in sumsP.keys) k: sumsP[k]! / docs.docs.length};
      });
    }
  }

  Future<void> _loadProducer() async {
    final sid = widget.animalData['sessionId'] as String?;
    if (sid == null) return;

    final snap =
        await LocalFirestore.instance
            .collection('sesiones')
            .doc(sid)
            .collection('datos_productor')
            .doc('info')
            .get();
    if (snap.exists) {
      setState(() => producer = snap.data());
    }
  }

  Future<Uint8List> _capture(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return Uint8List(0);
    final renderObj = ctx.findRenderObject();
    if (renderObj is! RenderRepaintBoundary) return Uint8List(0);
    final image = await renderObj.toImage(pixelRatio: 3);
    final bd = await image.toByteData(format: ui.ImageByteFormat.png);
    return bd?.buffer.asUint8List() ?? Uint8List(0);
  }

  Future<Uint8List> _generatePdfBytes() async {
    await WidgetsBinding.instance.endOfFrame;
    final animalImg = await _capture(_animalImageKey);
    final radarImg = await _capture(_radarKey);
    final barImg = await _capture(_barKey);

    // Fusiona el comentario del campo en el mapa que envÃ­as al PDF
    final fullData = {
      ...widget.animalData,
      'comentario': widget.animalData['comentario']?.toString().trim() ?? '',
    };

    return PdfService.generateAnimalPdfBytes(
      data: fullData,
      animalImage: animalImg.isNotEmpty ? animalImg : null,
      radarImage: radarImg.isNotEmpty ? radarImg : null,
      barImage: barImg.isNotEmpty ? barImg : null,
    );
  }

  void _onDownloadPressed() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(child: Text('Generando PDF, esperaâ€¦')),
              ],
            ),
          ),
    );
    try {
      final bytes = await _generatePdfBytes();
      await Printing.sharePdf(bytes: bytes, filename: 'reporte.pdf');
    } finally {
      Navigator.of(context).pop();
    }
  }

  void _onPreviewPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              appBar: AppBar(
                title: const Text('Vista previa PDF'),
                iconTheme: const IconThemeData(color: Colors.white),
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: Colors.blue[800],
                leading: const BackButton(),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: 'Descargar PDF',
                    onPressed: () async {
                      // Genera y comparte/descarga
                      final bytes = await _generatePdfBytes();
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename:
                            'evaluacion_${widget.animalData['numero']}.pdf',
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_in),
                    tooltip: 'Zoom grÃ¡ficos',
                    onPressed: () async {
                      // Captura las imÃ¡genes de los grÃ¡ficos
                      final radarImg = await _capture(_radarKey);
                      final barImg = await _capture(_barKey);
                      // Muestra diÃ¡logo zoomable
                      showDialog(
                        context: context,
                        builder:
                            (_) => Dialog(
                              child: InteractiveViewer(
                                panEnabled: true,
                                minScale: 1,
                                maxScale: 4,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (radarImg.isNotEmpty)
                                      Image.memory(radarImg),
                                    const SizedBox(height: 12),
                                    if (barImg.isNotEmpty) Image.memory(barImg),
                                  ],
                                ),
                              ),
                            ),
                      );
                    },
                  ),
                ],
              ),
              body: PdfPreview(
                allowPrinting: true,
                allowSharing: true,
                build: (format) => _generatePdfBytes(),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? photo;
    final b64 = widget.animalData['image_base64'] as String?;
    if ((b64?.isNotEmpty ?? false)) photo = base64Decode(b64!);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text(
          'Detalles del Animal',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (photo != null)
              RepaintBoundary(
                key: _animalImageKey,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    photo,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Datos generales
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos Generales',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const Divider(height: 24),
                    _infoRow('NÃºmero', widget.animalData['numero']),
                    _infoRow('Registro', widget.animalData['registro']),
                    _infoRow('Sexo', widget.animalData['sexo']),
                    _infoRow('Estado', widget.animalData['estado']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Radar EPMURAS
            RepaintBoundary(
              key: _radarKey,
              child: _buildRadarCard('EPMURAS', epmuras, epmProm),
            ),
            const SizedBox(height: 20),

            // Radar Pesos
            RepaintBoundary(
              key: _barKey,
              child: _buildRadarCard('Pesos (kg)', pesos, pesProm),
            ),

            const SizedBox(height: 24),

            // BotÃ³n Vista Previa
            ElevatedButton.icon(
              onPressed: _onPreviewPressed,
              icon: const Icon(Icons.visibility),
              label: const Text('Vista previa PDF'),

              style: ElevatedButton.styleFrom(
                backgroundColor: const ui.Color.fromARGB(255, 125, 208, 233),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // BotÃ³n Descargar
            ElevatedButton.icon(
              onPressed: _onDownloadPressed,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Descargar PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const ui.Color.fromARGB(255, 51, 206, 190),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
            if (historialEvaluaciones.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Historial de Evaluaciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...historialEvaluaciones.map(
                (eval) => Card(
                  child: ListTile(
                    title: Text("Fecha: ${eval['fecha'] ?? 'â€”'}"),
                    subtitle: Text(
                      "EPMURAS: ${eval['epmuras']?.toString() ?? 'â€”'}",
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(flex: 6, child: Text(val?.toString() ?? 'â€”')),
      ],
    ),
  );

  Widget _buildRadarCard(
    String title,
    Map<String, double> data,
    Map<String, double> avg,
  ) {
    final isPeso = title.startsWith('Pesos');
    final labels =
        isPeso
            ? ['Nac.', 'Dest.', 'Ajus.']
            : ['E', 'P', 'M', 'U', 'R', 'A', 'S'];

    final maxVal =
        isPeso
            ? ([
                  ...labels.map((k) => data[k] ?? 0.0),
                  ...labels.map((k) => avg[k] ?? 0.0),
                ].reduce((a, b) => a > b ? a : b) *
                1.3)
            : 6.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                letterSpacing: 1.2,
              ),
            ),
            const Divider(height: 24, thickness: 1),
            SizedBox(
              height: 250,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  tickCount: 5,
                  dataSets: [
                    RadarDataSet(
                      dataEntries:
                          labels
                              .map((k) => RadarEntry(value: data[k]!))
                              .toList(),
                      borderColor: Colors.blue,
                      borderWidth: 2,
                      fillColor: Colors.blue.withOpacity(0.3),
                      entryRadius: 3,
                    ),
                    RadarDataSet(
                      dataEntries:
                          labels
                              .map((k) => RadarEntry(value: avg[k] ?? 0.0))
                              .toList(),
                      borderColor: Colors.orange,
                      borderWidth: 2,
                      fillColor: Colors.orange.withOpacity(0.3),
                      entryRadius: 3,
                    ),
                  ],
                  getTitle:
                      (index, angle) =>
                          RadarChartTitle(text: labels[index], angle: angle),
                  ticksTextStyle: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                  radarBorderData: const BorderSide(
                    color: Colors.grey,
                    width: 1,
                  ),
                  gridBorderData: const BorderSide(
                    color: Colors.grey,
                    width: 1,
                  ),
                  tickBorderData: BorderSide(
                    color: Colors.grey.withOpacity(0.4),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                LegendDot(color: Colors.blue, label: 'Animal Evaluado'),
                SizedBox(width: 16),
                LegendDot(color: Colors.orange, label: 'Promedio SesiÃ³n'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const LegendDot({Key? key, required this.color, required this.label})
    : super(key: key);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label),
    ],
  );
}



