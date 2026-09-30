import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:printing/printing.dart';
import '../services/pdf_service.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? animalData;
  const AnimalDetailScreen({Key? key, this.animalData}) : super(key: key);

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  int _currentBottomNavIndex = 2;
  bool _isFavorite = false;

  final GlobalKey _animalImageKey = GlobalKey();
  final GlobalKey _radarKey = GlobalKey();
  final GlobalKey _barKey = GlobalKey();

  Map<String, double> epmProm = {};
  Map<String, double> pesProm = {};
  Map<String, dynamic>? producer;
  List<Map<String, dynamic>> historialEvaluaciones = [];

  @override
  void initState() {
    super.initState();
    _loadPromedios();
    _loadProducer();
    _loadHistorial();
  }

  Map<String, dynamic> get _data {
    final d = widget.animalData ?? {};
    return {
      'numero': d['numero']?.toString() ?? '4921',
      'registro': d['registro']?.toString() ?? 'RGN-8842',
      'sexo': d['sexo']?.toString() ?? 'Macho Reproductor',
      'estado': d['estado']?.toString() ?? d['estado_animal']?.toString() ?? 'En Servicio Activo',
      'raza': d['raza']?.toString() ?? 'Nelore Padrón',
      'rfid': d['rfid']?.toString() ?? '982.000184921',
      'lote': d['nombre_lote']?.toString() ?? d['lote']?.toString() ?? 'Lote 2024–B',
      'fecha_nac': d['fecha_nac']?.toString() ?? '14/03/2021 (38 meses • 1.150 días)',
      'padre': d['padre']?.toString() ?? d['rgn_padre']?.toString() ?? 'Don Capi RGN-5100',
      'madre': d['madre']?.toString() ?? d['rgn_madre']?.toString() ?? 'Reina RGN-4210',
      'peso_nac': d['peso_nac']?.toString() ?? '38',
      'peso_dest': d['peso_dest']?.toString() ?? '235',
      'peso_ajus': d['peso_ajus']?.toString() ?? '480',
      'gdp': d['gdp']?.toString() ?? '+0.982',
      'clasificacion': d['badge']?.toString() ?? 'Élite Superior',
      'rank': d['rank']?.toString() ?? 'Top 5% de la sesión zootécnica',
      'image_base64': d['image_base64'],
      'image': d['image'] ?? 'assets/img/vaca.jpg',
      'epmuras': d['epmuras'] is Map ? d['epmuras'] as Map<String, dynamic> : {
        'E': 5.2, 'P': 5.4, 'M': 5.0, 'U': 4.8, 'R': 5.6, 'A': 4.6, 'S': 5.2
      },
      'sessionId': d['sessionId'] ?? d['session_id'],
    };
  }

  List<Map<String, dynamic>> _buildCriteriaList() {
    final epmRaw = (_data['epmuras'] is Map) ? _data['epmuras'] as Map : {};

    double parseVal(dynamic v, double fallback) {
      if (v == null) return fallback;
      return double.tryParse(v.toString()) ?? fallback;
    }

    final names = {
      'E': 'Estructura',
      'P': 'Precocidad',
      'M': 'Musculatura',
      'U': 'Ombligo',
      'R': 'Raza',
      'A': 'Aplomos',
      'S': 'Sexualidad',
    };

    final defaultScores = {
      'E': 5.2, 'P': 5.4, 'M': 5.0, 'U': 4.8, 'R': 5.6, 'A': 4.6, 'S': 5.2
    };

    final defaultAvgs = {
      'E': 4.1, 'P': 4.1, 'M': 4.2, 'U': 4.3, 'R': 4.2, 'A': 4.6, 'S': 4.3
    };

    return ['E', 'P', 'M', 'U', 'R', 'A', 'S'].map((code) {
      final score = parseVal(epmRaw[code], defaultScores[code]!);
      final avg = epmProm[code] ?? defaultAvgs[code]!;
      final diffVal = score - avg;
      final diffStr = diffVal >= 0 ? '+${diffVal.toStringAsFixed(1)}' : diffVal.toStringAsFixed(1);
      return {
        'code': code,
        'name': names[code]!,
        'score': double.parse(score.toStringAsFixed(1)),
        'diff': diffStr,
        'avg': double.parse(avg.toStringAsFixed(1)),
      };
    }).toList();
  }

  Future<void> _loadHistorial() async {
    final registro = _data['registro'];
    final sessionId = _data['sessionId'];

    if (sessionId == null || registro == null) return;

    try {
      final snapshot = await LocalFirestore.instance
          .collection('sesiones')
          .doc(sessionId)
          .collection('evaluaciones_animales')
          .where('registro', isEqualTo: registro)
          .get();

      if (mounted) {
        setState(() {
          historialEvaluaciones = snapshot.docs.map((e) => e.data()).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPromedios() async {
    final sid = _data['sessionId'] as String?;
    if (sid == null) return;

    try {
      final docs = await LocalFirestore.instance
          .collection('sesiones')
          .doc(sid)
          .collection('evaluaciones_animales')
          .get();

      if (docs.docs.isNotEmpty) {
        final sumsE = {'E': 0.0, 'P': 0.0, 'M': 0.0, 'U': 0.0, 'R': 0.0, 'A': 0.0, 'S': 0.0};
        for (var d in docs.docs) {
          final m = d.data();
          final raw = (m['epmuras'] as Map<String, dynamic>?) ?? {};
          sumsE.forEach((k, _) {
            sumsE[k] = sumsE[k]! + (double.tryParse(raw[k]?.toString() ?? '0') ?? 0.0);
          });
        }
        if (mounted) {
          setState(() {
            epmProm = {for (var k in sumsE.keys) k: sumsE[k]! / docs.docs.length};
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadProducer() async {
    final sid = _data['sessionId'] as String?;
    if (sid == null) return;

    try {
      final snap = await LocalFirestore.instance
          .collection('sesiones')
          .doc(sid)
          .collection('datos_productor')
          .doc('info')
          .get();
      if (snap.exists && mounted) {
        setState(() => producer = snap.data());
      }
    } catch (_) {}
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

    final fullData = {
      ..._data,
      'comentario': widget.animalData?['comentario']?.toString().trim() ?? '',
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
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Generando PDF, por favor espera...')),
          ],
        ),
      ),
    );
    try {
      final bytes = await _generatePdfBytes();
      await Printing.sharePdf(bytes: bytes, filename: 'ficha_zootecnica_${_data['numero']}.pdf');
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _onPreviewPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Vista previa PDF', style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF1B4332),
            leading: const BackButton(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                tooltip: 'Compartir PDF',
                onPressed: () async {
                  final bytes = await _generatePdfBytes();
                  await Printing.sharePdf(
                    bytes: bytes,
                    filename: 'evaluacion_${_data['numero']}.pdf',
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
    final criteria = _buildCriteriaList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2FCF4),
      appBar: _buildTopAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOfficialSyncRow(),
              const SizedBox(height: 12),
              RepaintBoundary(
                key: _animalImageKey,
                child: _buildHeroAnimalCard(),
              ),
              const SizedBox(height: 14),
              _buildEliteRankBanner(),
              const SizedBox(height: 16),
              _buildGeneralDataCard(),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: _radarKey,
                child: _buildEpmurasRadarCard(criteria),
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: _barKey,
                child: _buildWeightGrowthCard(),
              ),
              const SizedBox(height: 18),
              _buildActionButtons(),
              const SizedBox(height: 14),
              _buildAuditFooter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF2FCF4),
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1B4332)),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/main');
          }
        },
      ),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF00B4D8).withOpacity(0.18),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(
              child: Icon(Icons.pets, color: Color(0xFF0096C7), size: 16),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Ficha Del Ejemplar',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B4332),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Color(0xFF1B4332), size: 20),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enlace a ficha zootécnica copiado')),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFF1B4332),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 18),
        ),
      ],
    );
  }

  Widget _buildOfficialSyncRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD8F3DC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.verified_outlined, size: 14, color: Color(0xFF1B4332)),
              SizedBox(width: 5),
              Text(
                'FICHA ZOOTÉCNICA OFICIAL',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Color(0xFF1B4332),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: const [
            CircleAvatar(radius: 4, backgroundColor: Color(0xFF2D6A4F)),
            SizedBox(width: 5),
            Text(
              'Sincronizado',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D6A4F),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroAnimalCard() {
    final numStr = _data['numero'];
    final razaStr = _data['raza'];
    final rgnStr = _data['registro'];
    final rfidStr = _data['rfid'];
    final loteStr = _data['lote'];
    final estadoStr = _data['estado'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EFE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildHeroAnimalImage(),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    razaStr.toString().split(' ').first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '#$numStr',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B4332),
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD8F3DC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              estadoStr,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B4332),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                      },
                      child: Icon(
                        _isFavorite ? Icons.star : Icons.star_border,
                        color: _isFavorite ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$rgnStr • $razaStr',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFB7E4C7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sensors, size: 12, color: Color(0xFF2D6A4F)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'RFID: $rfidStr',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4332),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    loteStr,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAnimalImage() {
    final b64 = _data['image_base64'] as String?;
    if (b64 != null && b64.isNotEmpty) {
      try {
        final bytes = base64Decode(b64);
        return Image.memory(
          bytes,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }
    final imgAsset = _data['image'] as String?;
    if (imgAsset != null && imgAsset.isNotEmpty) {
      return Image.asset(
        imgAsset,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(),
      );
    }
    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Container(
      width: 96,
      height: 96,
      color: const Color(0xFFE2F3E7),
      child: const Icon(Icons.pets, color: Color(0xFF2D6A4F), size: 36),
    );
  }

  Widget _buildEliteRankBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EFE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.military_tech_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clasificación: ${_data['clasificacion']}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _data['rank'],
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: '5.4',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B4332),
                  ),
                ),
                TextSpan(
                  text: ' / 6.0 pts',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralDataCard() {
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
                  Icon(Icons.badge_outlined, color: Color(0xFF1B4332), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Datos Generales',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Ficha Zootécnica',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDataCell('Número Arete', _data['numero']),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDataCell('Registro Oficial', _data['registro']),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDataCell('Sexo • Categoría', _data['sexo']),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDataCell(
                  'Estado Fisiológico',
                  _data['estado'],
                  valueColor: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          _buildGenealogyRow(Icons.calendar_today_outlined, 'Nacimiento', _data['fecha_nac']),
          const SizedBox(height: 8),
          _buildGenealogyRow(Icons.account_tree_outlined, 'Genealogía P (Padre)', _data['padre']),
          const SizedBox(height: 8),
          _buildGenealogyRow(Icons.female_outlined, 'Genealogía M (Madre)', _data['madre']),
        ],
      ),
    );
  }

  Widget _buildDataCell(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGenealogyRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(
          '$title: ',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B4332),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEpmurasRadarCard(List<Map<String, dynamic>> criteria) {
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
                  Icon(Icons.radar_rounded, color: Color(0xFF1B4332), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Evaluación EPMURAS',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F3DC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Escala 1 a 6',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1B4332)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Morfología lineal zootécnica comparada',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 260,
              height: 240,
              child: CustomPaint(
                painter: _EpmurasSpiderChartPainter(criteria: criteria),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1B4332),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Animal #${_data['numero']} (5.4)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Promedio Hato (4.2)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: criteria.map((item) {
              return Container(
                width: 38,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2FCF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD8E7DC)),
                ),
                child: Column(
                  children: [
                    Text(
                      item['code'],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['score']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item['diff'],
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'E: Estructura • P: Precocidad • M: Musculatura • U: Ombligo\nR: Raza • A: Aplomos • S: Sexualidad',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                color: Color(0xFF6B7280),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightGrowthCard() {
    final pesoNac = _data['peso_nac'];
    final pesoDest = _data['peso_dest'];
    final pesoAjus = _data['peso_ajus'];
    final gdpStr = _data['gdp'];

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
                  Icon(Icons.scale_outlined, color: Color(0xFF1B4332), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pesos y Ganancia Ponderal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F3E7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CC: 6.5 / 9',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Curva de crecimiento en 3 hitos fisiológicos',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildWeightMilestone('Nacimiento', pesoNac, 'kg', '+4 kg vs hato'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildWeightMilestone('Destete (205d)', pesoDest, 'kg', '+25 kg vs hato'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildWeightMilestone('Ajust. (550d)', pesoAjus, 'kg', '+42 kg vs hato'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFDFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ganancia Diaria Promedio (GDP)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    Text(
                      '$gdpStr kg / día',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _GrowthLineChartPainter(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1B4332), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('Curva Animal #${_data['numero']}', style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('Patrón Poblacional Raza', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                      ],
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

  Widget _buildWeightMilestone(String milestone, String weight, String unit, String diff) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            milestone,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: weight,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B4332),
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            diff,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _onDownloadPressed,
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 20),
            label: const Text(
              'Descargar Certificado Zootécnico (PDF)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: _onPreviewPressed,
                  icon: const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF1B4332)),
                  label: const Text(
                    'Vista Previa PDF',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFD8E7DC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final docId = widget.animalData?['evalId'] ?? widget.animalData?['docId'];
                    if (docId != null) {
                      Navigator.pushNamed(
                        context,
                        '/edit_evaluation',
                        arguments: {
                          'docId': docId,
                          'initialData': widget.animalData,
                        },
                      );
                    } else {
                      Navigator.pushNamed(context, '/epmuras');
                    }
                  },
                  icon: const Icon(Icons.edit_note, size: 18, color: Color(0xFF1B4332)),
                  label: const Text(
                    'Editar en Manga',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFD8E7DC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAuditFooter() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.history, size: 13, color: Color(0xFF9CA3AF)),
          SizedBox(width: 5),
          Text(
            'Última evaluación zootécnica en manga • Sincronizado en la Nube',
            style: TextStyle(
              fontSize: 10.5,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() {
            _currentBottomNavIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/main');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/consulta_finca');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/epmuras');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/index');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/settings');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF1B4332),
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Lotes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'EPMURAS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Índices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            activeIcon: Icon(Icons.more_horiz),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}

class _EpmurasSpiderChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> criteria;

  _EpmurasSpiderChartPainter({required this.criteria});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.42;
    const sides = 7;
    const angleStep = (2 * math.pi) / sides;
    const startAngle = -math.pi / 2;

    final webPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int step = 1; step <= 5; step++) {
      final r = maxRadius * (step / 5);
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final a = startAngle + i * angleStep;
        final x = center.dx + r * math.cos(a);
        final y = center.dy + r * math.sin(a);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, webPaint);
    }

    final axisPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < sides; i++) {
      final a = startAngle + i * angleStep;
      final x = center.dx + maxRadius * math.cos(a);
      final y = center.dy + maxRadius * math.sin(a);
      canvas.drawLine(center, Offset(x, y), axisPaint);

      final labelRadius = maxRadius + 18;
      final lx = center.dx + labelRadius * math.cos(a);
      final ly = center.dy + labelRadius * math.sin(a);

      final textSpan = TextSpan(
        text: '${criteria[i]['code']} (${criteria[i]['score']})',
        style: const TextStyle(
          color: Color(0xFF1B4332),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }

    final hatoPath = Path();
    for (int i = 0; i < sides; i++) {
      final a = startAngle + i * angleStep;
      final normScore = (criteria[i]['avg'] as double) / 6.0;
      final r = maxRadius * normScore;
      final x = center.dx + r * math.cos(a);
      final y = center.dy + r * math.sin(a);
      if (i == 0) {
        hatoPath.moveTo(x, y);
      } else {
        hatoPath.lineTo(x, y);
      }
    }
    hatoPath.close();

    final hatoPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(hatoPath, hatoPaint);

    final animalPath = Path();
    final points = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final a = startAngle + i * angleStep;
      final normScore = (criteria[i]['score'] as double) / 6.0;
      final r = maxRadius * normScore;
      final x = center.dx + r * math.cos(a);
      final y = center.dy + r * math.sin(a);
      points.add(Offset(x, y));
      if (i == 0) {
        animalPath.moveTo(x, y);
      } else {
        animalPath.lineTo(x, y);
      }
    }
    animalPath.close();

    final animalFillPaint = Paint()
      ..color = const Color(0xFF52B788).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(animalPath, animalFillPaint);

    final animalStrokePaint = Paint()
      ..color = const Color(0xFF1B4332)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(animalPath, animalStrokePaint);

    final dotPaint = Paint()..color = const Color(0xFF1B4332);
    for (final pt in points) {
      canvas.drawCircle(pt, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GrowthLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final p1 = Offset(w * 0.15, h * 0.85);
    final p2 = Offset(w * 0.50, h * 0.50);
    final p3 = Offset(w * 0.85, h * 0.15);

    final ref1 = Offset(w * 0.15, h * 0.90);
    final ref2 = Offset(w * 0.50, h * 0.60);
    final ref3 = Offset(w * 0.85, h * 0.30);

    final refPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(ref1, ref2, refPaint);
    canvas.drawLine(ref2, ref3, refPaint);

    final refDot = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(ref1, 3.0, refDot);
    canvas.drawCircle(ref2, 3.0, refDot);
    canvas.drawCircle(ref3, 3.0, refDot);

    final linePaint = Paint()
      ..color = const Color(0xFF1B4332)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(p1, p2, linePaint);
    canvas.drawLine(p2, p3, linePaint);

    final dot = Paint()..color = const Color(0xFF1B4332);
    canvas.drawCircle(p1, 4.0, dot);
    canvas.drawCircle(p2, 4.0, dot);
    canvas.drawCircle(p3, 4.0, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
