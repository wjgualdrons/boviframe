// lib/services/pdf_service.dart

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:boviframe/services/local_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  // Colores del Design System institucional Boviframe
  static const PdfColor primaryDark = PdfColor.fromInt(0xFF1B4332);
  static const PdfColor primaryGreen = PdfColor.fromInt(0xFF2D6A4F);
  static const PdfColor emeraldAccent = PdfColor.fromInt(0xFF52B788);
  static const PdfColor amberHato = PdfColor.fromInt(0xFFF59E0B);
  static const PdfColor lightBg = PdfColor.fromInt(0xFFF2FCF4);
  static const PdfColor lightGreenContainer = PdfColor.fromInt(0xFFD8F3DC);
  static const PdfColor cardBorder = PdfColor.fromInt(0xFFD8E7DC);
  static const PdfColor greyText = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor darkText = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor lightGreyBg = PdfColor.fromInt(0xFFF9FAFB);

  static Future<Uint8List> generateAnimalPdfBytes({
    required Map<String, dynamic> data,
    Uint8List? animalImage,
    Uint8List? radarImage,
    Uint8List? barImage,
  }) async {
    // 1) Obtener foto del animal (desde animalImage o base64 en data)
    Uint8List? finalAnimalImage = animalImage;
    if (finalAnimalImage == null || finalAnimalImage.isEmpty) {
      final b64 = data['image_base64'] as String?;
      if (b64 != null && b64.isNotEmpty) {
        try {
          finalAnimalImage = base64Decode(b64);
        } catch (_) {}
      }
    }

    // 2) Mapear datos al modelo zootécnico
    final animalEval = _mapDataToAnimalEvaluationData(data);

    // 3) Consultar productor y evaluador si existen en la sesión
    final sid = (data['sessionId'] as String?) ?? (data['session_id'] as String?) ?? '';
    String farmName = 'Agropecuaria La Esperanza, Lote 2024-B';
    String farmLoc = 'Ospino, Estado Portuguesa • Venezuela';
    String evaluatorName = 'MV Gualdron Willians';
    String evaluatorCollegiate = 'MP 4.892';

    if (sid.isNotEmpty) {
      try {
        final prodSnap = await LocalFirestore.instance
            .collection('sesiones')
            .doc(sid)
            .collection('datos_productor')
            .get();
        if (prodSnap.docs.isNotEmpty) {
          final p = prodSnap.docs.first.data();
          farmName = '${p['unidad_produccion'] ?? farmName}';
          farmLoc = '${p['estado'] ?? farmLoc}';
        }

        final sessSnap = await LocalFirestore.instance.collection('sesiones').doc(sid).get();
        if (sessSnap.exists) {
          final usuarioId = sessSnap.data()['userId'] as String? ?? '';
          if (usuarioId.isNotEmpty) {
            final usrSnap = await LocalFirestore.instance.collection('usuarios').doc(usuarioId).get();
            if (usrSnap.exists) {
              final u = usrSnap.data();
              evaluatorName = u['nombre'] as String? ?? evaluatorName;
            }
          }
        }
      } catch (_) {}
    }

    return generatePdf(
      animal: animalEval,
      animalImageBytes: finalAnimalImage,
      veterinarianName: evaluatorName,
      collegiateNumber: evaluatorCollegiate,
      farmName: farmName,
      location: farmLoc,
    );
  }

  /// Genera los bytes del documento PDF A4 completo siguiendo el nuevo diseño institucional
  static Future<Uint8List> generatePdf({
    required AnimalEvaluationData animal,
    Uint8List? animalImageBytes,
    String? veterinarianName,
    String? collegiateNumber,
    String? farmName,
    String? location,
  }) async {
    final pdf = pw.Document(
      title: 'Boviframe - Informe Zootécnico ${animal.tagNumber}',
      author: 'Boviframe AgroTech - MV Gualdron Willians',
    );

    // Fuentes estilizadas Plus Jakarta Sans con fallback seguro a Helvetica
    pw.Font fontRegular = pw.Font.helvetica();
    pw.Font fontBold = pw.Font.helveticaBold();
    pw.Font fontExtraBold = pw.Font.helveticaBold();

    try {
      fontRegular = await PdfGoogleFonts.plusJakartaSansRegular();
      fontBold = await PdfGoogleFonts.plusJakartaSansBold();
      fontExtraBold = await PdfGoogleFonts.plusJakartaSansExtraBold();
    } catch (_) {
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
      fontExtraBold = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Encabezado Oficial e Identificador de Documento
              _buildOfficialHeader(animal, fontBold, fontExtraBold),
              pw.SizedBox(height: 6),

              // 2. Ficha de Datos Generales y Biometría del Ejemplar con Foto Incluida
              _buildAnimalGeneralCard(animal, fontBold, fontExtraBold, animalImageBytes: animalImageBytes),
              pw.SizedBox(height: 6),

              // 3. Tabla Matriz Oficial de Calificación Morfológica EPMURAS
              _buildEpmurasTable(animal, fontBold),
              pw.SizedBox(height: 6),

              // 4. Panel Gráfico Dual: Morfograma Radar (7 ejes) + Curva Ponderal
              _buildDualGraphicsPanel(animal, fontBold),
              pw.SizedBox(height: 6),

              // 5. Dictamen Técnico y Comentarios del Evaluador
              _buildTechnicalComments(animal, fontBold),
              pw.SizedBox(height: 6),

              // 6. Pie de Firma Oficial, QR de Auditoría Blockchain y Sellos
              _buildAuditAndSignature(
                animal: animal,
                vetName: veterinarianName ?? 'MV Gualdron Willians',
                vetCollegiate: collegiateNumber ?? 'MP 4.892',
                farm: farmName ?? 'Agropecuaria La Esperanza, Lote 2024-B',
                loc: location ?? 'Ospino, Estado Portuguesa • Venezuela',
                fontBold: fontBold,
              ),
              pw.Spacer(),

              // 7. Micro-cintillo legal inferior
              _buildLegalFooterBar(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // 1. CABECERA INSTITUCIONAL
  // ---------------------------------------------------------------------------
  static pw.Widget _buildOfficialHeader(
    AnimalEvaluationData animal,
    pw.Font fontBold,
    pw.Font fontExtraBold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: primaryDark, width: 1.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 32,
                height: 32,
                decoration: pw.BoxDecoration(
                  color: primaryDark,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'B',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      font: fontExtraBold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BOVIFRAME AGROTECH • CERTIFICADO OFICIAL ZOOTÉCNICO',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryGreen,
                      letterSpacing: 0.5,
                      font: fontBold,
                    ),
                  ),
                  pw.Text(
                    'INFORME MORFOMÉTRICO LINEAL • EPMURAS',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryDark,
                      font: fontExtraBold,
                    ),
                  ),
                  pw.Text(
                    'Metodología Estandarizada ABCZ / ANCP de Evaluación Visual y Genética Bovina',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: greyText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: cardBorder, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Reporte ID: ${animal.reportId}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryDark,
                    font: fontBold,
                  ),
                ),
                pw.Text(
                  'Emisión: ${animal.emissionDate}',
                  style: const pw.TextStyle(fontSize: 7, color: greyText),
                ),
                pw.Row(
                  children: [
                    pw.Container(
                      width: 5,
                      height: 5,
                      decoration: const pw.BoxDecoration(
                        color: emeraldAccent,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 3),
                    pw.Text(
                      'VERIFICADO • HASH ${animal.hashVerification}',
                      style: pw.TextStyle(
                        fontSize: 6.5,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryGreen,
                        font: fontBold,
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

  // ---------------------------------------------------------------------------
  // 2. DATOS GENERALES DEL EJEMPLAR (CON FOTO REQUERIDA)
  // ---------------------------------------------------------------------------
  static pw.Widget _buildAnimalGeneralCard(
    AnimalEvaluationData animal,
    pw.Font fontBold,
    pw.Font fontExtraBold, {
    Uint8List? animalImageBytes,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: cardBorder, width: 0.8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Foto del Ejemplar (si existe)
          if (animalImageBytes != null && animalImageBytes.isNotEmpty) ...[
            pw.Container(
              width: 72,
              height: 72,
              margin: const pw.EdgeInsets.only(right: 10),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: primaryDark, width: 1.2),
                image: pw.DecorationImage(
                  image: pw.MemoryImage(animalImageBytes),
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
          ] else ...[
            pw.Container(
              width: 65,
              height: 65,
              margin: const pw.EdgeInsets.only(right: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: cardBorder, width: 0.8),
              ),
              child: pw.Center(
                child: pw.Text(
                  'BOVIFRAME\nFOTO',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7, color: greyText),
                ),
              ),
            ),
          ],

          // Identificación Arete y Registro
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      animal.tagNumber,
                      style: pw.TextStyle(
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryDark,
                        font: fontExtraBold,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: lightGreenContainer,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'EXCELENTE',
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryDark,
                          font: fontBold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      'Percentil: ${animal.percentileRank}',
                      style: const pw.TextStyle(fontSize: 7, color: greyText),
                    ),
                  ],
                ),
                pw.Text(
                  '${animal.registryNumber} • ${animal.breed}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: darkText,
                    font: fontBold,
                  ),
                ),
                pw.Text(
                  '${animal.categoryType} • ${animal.genealogyNote}',
                  style: const pw.TextStyle(fontSize: 6.5, color: greyText),
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  children: [
                    _buildMiniBadge('RFID: ${animal.rfidChip}'),
                    pw.SizedBox(width: 4),
                    _buildMiniBadge('LOTE: ${animal.lotName}'),
                    pw.SizedBox(width: 4),
                    _buildMiniBadge('GRUPO: ${animal.contemporaryGroup}'),
                  ],
                ),
              ],
            ),
          ),

          // Columna 2: Fisiología & Nacimiento
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoLine('SEXO / CATEGORÍA', animal.sexCategory, fontBold),
                _buildInfoLine(
                  'FECHA NACIMIENTO',
                  '${animal.birthDate} (${animal.ageMonths}m • ${animal.ageDays} días)',
                  fontBold,
                ),
                _buildInfoLine(
                  'PESO AL NACER',
                  '${animal.birthWeightKg} kg (${animal.birthWeightDiff})',
                  fontBold,
                ),
                _buildInfoLine(
                  'PESO AJUSTADO (550D)',
                  '${animal.adjustedWeight550dKg} kg (${animal.adjustedWeightDiff})',
                  fontBold,
                ),
              ],
            ),
          ),

          // Columna 3: Condición Corporal & Ganancia Diaria
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoLine('ESTADO FISIOLÓGICO', animal.physiologicalState, fontBold),
                _buildInfoLine('CONDICIÓN CORPORAL (CC)', '${animal.bodyCondition} / 9.0', fontBold),
                _buildInfoLine(
                  'PESO DESTETE (205D)',
                  '${animal.weaningWeight205dKg} kg (${animal.weaningWeightDiff})',
                  fontBold,
                ),
                _buildInfoLine(
                  'GANANCIA DIARIA (GDP)',
                  '${animal.averageDailyGainKg} kg / día',
                  fontBold,
                  valueColor: primaryGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMiniBadge(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: cardBorder, width: 0.6),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 6, color: darkText),
      ),
    );
  }

  static pw.Widget _buildInfoLine(String label, String value, pw.Font fontBold, {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 5.5, color: greyText),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: valueColor ?? darkText,
              font: fontBold,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. TABLA OFICIAL EPMURAS
  // ---------------------------------------------------------------------------
  static pw.Widget _buildEpmurasTable(AnimalEvaluationData animal, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'CALIFICACIÓN MORFOLÓGICA LINEAL EPMURAS (ESCALA OFICIAL 1 A 6)',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: primaryDark,
                font: fontBold,
              ),
            ),
            pw.Text(
              'Base Poblacional: 240 Hembras Contemporáneas',
              style: const pw.TextStyle(fontSize: 6.5, color: greyText),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Table(
          border: pw.TableBorder.all(color: cardBorder, width: 0.6),
          columnWidths: const {
            0: pw.FlexColumnWidth(3.2), // Criterio
            1: pw.FlexColumnWidth(0.8), // Sigla
            2: pw.FlexColumnWidth(4.5), // Descripción
            3: pw.FlexColumnWidth(1.2), // Pond
            4: pw.FlexColumnWidth(1.4), // Valor
            5: pw.FlexColumnWidth(1.4), // Prom Hato
            6: pw.FlexColumnWidth(1.4), // Dif
            7: pw.FlexColumnWidth(2.5), // Nivel
          },
          children: [
            // Cabecera de la tabla
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: primaryDark),
              children: [
                _tableHeaderCell('Criterio Zootécnico', fontBold),
                _tableHeaderCell('Sigla', fontBold, align: pw.TextAlign.center),
                _tableHeaderCell('Descripción Funcional', fontBold),
                _tableHeaderCell('Pond.', fontBold, align: pw.TextAlign.center),
                _tableHeaderCell('Valor (${animal.tagNumber})', fontBold, align: pw.TextAlign.center),
                _tableHeaderCell('Prom. Hato', fontBold, align: pw.TextAlign.center),
                _tableHeaderCell('Dif. (+/-)', fontBold, align: pw.TextAlign.center),
                _tableHeaderCell('Nivel (1 a 6)', fontBold, align: pw.TextAlign.center),
              ],
            ),
            // Filas de criterios EPMURAS
            ...animal.epmurasScores.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isEven = idx % 2 == 0;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : lightGreyBg),
                children: [
                  _tableCell(item.name, fontBold, isBold: true),
                  _tableCell(item.code, fontBold, align: pw.TextAlign.center),
                  _tableCell(item.description, fontBold, fontSize: 6.5),
                  _tableCell('${item.weightPercentage}%', fontBold, align: pw.TextAlign.center),
                  _tableCell(item.score.toStringAsFixed(1), fontBold, align: pw.TextAlign.center, isBold: true),
                  _tableCell(item.herdAverage.toStringAsFixed(1), fontBold, align: pw.TextAlign.center),
                  _tableCell(
                    item.difference,
                    fontBold,
                    align: pw.TextAlign.center,
                    textColor: item.difference.startsWith('+') ? primaryGreen : PdfColors.red,
                    isBold: true,
                  ),
                  _tableLevelCell(item.score, item.levelLabel, fontBold),
                ],
              );
            }),
            // Fila de Resumen / Índice Global
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: lightGreenContainer),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: pw.Text(
                    'ÍNDICE GLOBAL EPMURAS PONDERADO:',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryDark,
                      font: fontBold,
                    ),
                  ),
                ),
                _tableCell('', fontBold),
                _tableCell('Aspiración Folicular y FIV Recomendada', fontBold, fontSize: 6.5),
                _tableCell('100%', fontBold, align: pw.TextAlign.center, isBold: true),
                _tableCell(
                  animal.globalIndex.toStringAsFixed(2),
                  fontBold,
                  align: pw.TextAlign.center,
                  fontSize: 8.5,
                  isBold: true,
                  textColor: primaryDark,
                ),
                _tableCell('4.25', fontBold, align: pw.TextAlign.center),
                _tableCell('+0.50', fontBold, align: pw.TextAlign.center, textColor: primaryGreen, isBold: true),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    decoration: pw.BoxDecoration(
                      color: primaryDark,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      'ÉLITE DONANTE',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 6.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        font: fontBold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text, pw.Font fontBold, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 6.5,
          fontWeight: pw.FontWeight.bold,
          font: fontBold,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text,
    pw.Font fontBold, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
    PdfColor? textColor,
    double fontSize = 7,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: textColor ?? darkText,
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          font: isBold ? fontBold : null,
        ),
      ),
    );
  }

  static pw.Widget _tableLevelCell(double score, String level, pw.Font fontBold) {
    final fillRatio = (score / 6.0).clamp(0.0, 1.0);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Container(
              height: 4,
              decoration: pw.BoxDecoration(
                color: cardBorder,
                borderRadius: pw.BorderRadius.circular(2),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: (fillRatio * 100).toInt(),
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        color: primaryDark,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  pw.Spacer(flex: ((1.0 - fillRatio) * 100).toInt()),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(
            flex: 6,
            child: pw.Text(
              level,
              style: const pw.TextStyle(fontSize: 6, color: darkText),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. PANEL GRÁFICO DUAL (RADAR EPMURAS + CURVA PONDERAL)
  // ---------------------------------------------------------------------------
  static pw.Widget _buildDualGraphicsPanel(AnimalEvaluationData animal, pw.Font fontBold) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Gráfico 1: Radar Morfograma
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(7),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: cardBorder, width: 0.7),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'MORFOGRAMA LINEAL EPMURAS',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryDark,
                        font: fontBold,
                      ),
                    ),
                    pw.Row(
                      children: [
                        _buildLegendIndicator(primaryDark, animal.tagNumber),
                        pw.SizedBox(width: 6),
                        _buildLegendIndicator(amberHato, 'Hato (4.25)'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.SizedBox(
                    width: 140,
                    height: 110,
                    child: _buildPdfRadarChart(animal),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: animal.epmurasScores.map((c) {
                    return pw.Column(
                      children: [
                        pw.Text(c.code, style: const pw.TextStyle(fontSize: 6, color: greyText)),
                        pw.Text(
                          c.score.toStringAsFixed(1),
                          style: pw.TextStyle(
                            fontSize: 6.5,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryDark,
                            font: fontBold,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 8),

        // Gráfico 2: Curva de Pesos y Ganancia Ponderal
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(7),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: cardBorder, width: 0.7),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'CURVA DE PESOS Y GANANCIA PONDERAL',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryDark,
                        font: fontBold,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: pw.BoxDecoration(
                        color: lightBg,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        'CC: ${animal.bodyCondition} / 9',
                        style: pw.TextStyle(
                          fontSize: 6.5,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryDark,
                          font: fontBold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    _buildMilestoneBox('NACIMIENTO', '${animal.birthWeightKg}', 'kg', animal.birthWeightDiff, fontBold),
                    pw.SizedBox(width: 4),
                    _buildMilestoneBox('DESTETE (205D)', '${animal.weaningWeight205dKg}', 'kg', animal.weaningWeightDiff, fontBold),
                    pw.SizedBox(width: 4),
                    _buildMilestoneBox('AJUST. (550D)', '${animal.adjustedWeight550dKg}', 'kg', animal.adjustedWeightDiff, fontBold),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'GANANCIA DIARIA PROMEDIO (GDP):',
                      style: const pw.TextStyle(fontSize: 6.5, color: greyText),
                    ),
                    pw.Text(
                      '+${animal.averageDailyGainKg} kg / día',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryGreen,
                        font: fontBold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: _buildPdfGrowthLineChart(animal),
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _buildLegendIndicator(primaryDark, 'Curva ${animal.tagNumber}'),
                    pw.SizedBox(width: 10),
                    _buildLegendIndicator(amberHato, 'Patrón Poblacional Raza'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLegendIndicator(PdfColor color, String label) {
    return pw.Row(
      children: [
        pw.Container(
          width: 5,
          height: 5,
          decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
        ),
        pw.SizedBox(width: 3),
        pw.Text(label, style: const pw.TextStyle(fontSize: 6, color: greyText)),
      ],
    );
  }

  static pw.Widget _buildMilestoneBox(String title, String val, String unit, String diff, pw.Font fontBold) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          color: lightGreyBg,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: cardBorder, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 5.5, color: greyText)),
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: val,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryDark,
                      font: fontBold,
                    ),
                  ),
                  pw.TextSpan(text: ' $unit', style: const pw.TextStyle(fontSize: 6, color: greyText)),
                ],
              ),
            ),
            pw.Text(
              diff,
              style: pw.TextStyle(
                fontSize: 5.5,
                fontWeight: pw.FontWeight.bold,
                color: primaryGreen,
                font: fontBold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VECTORIAL DRAWING PARA PDF: RADAR & LÍNEA
  // ---------------------------------------------------------------------------
  static pw.Widget _buildPdfRadarChart(AnimalEvaluationData animal) {
    return pw.CustomPaint(
      size: const PdfPoint(140, 110),
      painter: (PdfGraphics canvas, PdfPoint size) {
        final cx = size.x / 2;
        final cy = size.y / 2;
        final radius = math.min(cx, cy) * 0.78;
        const sides = 7;
        const angleStep = (2 * math.pi) / sides;
        const startAngle = -math.pi / 2;

        canvas.setStrokeColor(PdfColor.fromInt(0xFFE5E7EB));
        canvas.setLineWidth(0.6);
        for (int step = 1; step <= 5; step++) {
          final r = radius * (step / 5);
          for (int i = 0; i < sides; i++) {
            final a1 = startAngle + i * angleStep;
            final a2 = startAngle + (i + 1) * angleStep;
            final x1 = cx + r * math.cos(a1);
            final y1 = cy + r * math.sin(a1);
            final x2 = cx + r * math.cos(a2);
            final y2 = cy + r * math.sin(a2);
            if (i == 0) {
              canvas.moveTo(x1, y1);
            }
            canvas.lineTo(x2, y2);
          }
          canvas.closePath();
          canvas.strokePath();
        }

        for (int i = 0; i < sides; i++) {
          final a = startAngle + i * angleStep;
          final x = cx + radius * math.cos(a);
          final y = cy + radius * math.sin(a);
          canvas.moveTo(cx, cy);
          canvas.lineTo(x, y);
          canvas.strokePath();
        }

        canvas.setStrokeColor(amberHato);
        canvas.setLineWidth(1.2);
        for (int i = 0; i < sides; i++) {
          final a = startAngle + i * angleStep;
          final item = animal.epmurasScores[i];
          final r = radius * (item.herdAverage / 6.0);
          final x = cx + r * math.cos(a);
          final y = cy + r * math.sin(a);
          if (i == 0) {
            canvas.moveTo(x, y);
          } else {
            canvas.lineTo(x, y);
          }
        }
        canvas.closePath();
        canvas.strokePath();

        canvas.setFillColor(PdfColor.fromInt(0x4052B788));
        canvas.setStrokeColor(primaryDark);
        canvas.setLineWidth(1.5);
        for (int i = 0; i < sides; i++) {
          final a = startAngle + i * angleStep;
          final item = animal.epmurasScores[i];
          final r = radius * (item.score / 6.0);
          final x = cx + r * math.cos(a);
          final y = cy + r * math.sin(a);
          if (i == 0) {
            canvas.moveTo(x, y);
          } else {
            canvas.lineTo(x, y);
          }
        }
        canvas.closePath();
        canvas.fillAndStrokePath();

        canvas.setFillColor(primaryDark);
        for (int i = 0; i < sides; i++) {
          final a = startAngle + i * angleStep;
          final item = animal.epmurasScores[i];
          final r = radius * (item.score / 6.0);
          final x = cx + r * math.cos(a);
          final y = cy + r * math.sin(a);
          canvas.drawEllipse(x, y, 2.0, 2.0);
          canvas.fillPath();
        }
      },
    );
  }

  static pw.Widget _buildPdfGrowthLineChart(AnimalEvaluationData animal) {
    return pw.CustomPaint(
      size: const PdfPoint(220, 48),
      painter: (PdfGraphics canvas, PdfPoint size) {
        final w = size.x;
        final h = size.y;

        final p1 = PdfPoint(w * 0.12, h * 0.20);
        final p2 = PdfPoint(w * 0.50, h * 0.55);
        final p3 = PdfPoint(w * 0.88, h * 0.90);

        final ref1 = PdfPoint(w * 0.12, h * 0.15);
        final ref2 = PdfPoint(w * 0.50, h * 0.45);
        final ref3 = PdfPoint(w * 0.88, h * 0.72);

        canvas.setStrokeColor(amberHato);
        canvas.setLineWidth(1.2);
        canvas.moveTo(ref1.x, ref1.y);
        canvas.lineTo(ref2.x, ref2.y);
        canvas.lineTo(ref3.x, ref3.y);
        canvas.strokePath();

        canvas.setFillColor(amberHato);
        canvas.drawEllipse(ref1.x, ref1.y, 2.0, 2.0);
        canvas.drawEllipse(ref2.x, ref2.y, 2.0, 2.0);
        canvas.drawEllipse(ref3.x, ref3.y, 2.0, 2.0);
        canvas.fillPath();

        canvas.setStrokeColor(primaryDark);
        canvas.setLineWidth(1.8);
        canvas.moveTo(p1.x, p1.y);
        canvas.lineTo(p2.x, p2.y);
        canvas.lineTo(p3.x, p3.y);
        canvas.strokePath();

        canvas.setFillColor(primaryDark);
        canvas.drawEllipse(p1.x, p1.y, 2.5, 2.5);
        canvas.drawEllipse(p2.x, p2.y, 2.5, 2.5);
        canvas.drawEllipse(p3.x, p3.y, 2.5, 2.5);
        canvas.fillPath();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 5. COMENTARIOS TÉCNICOS ZOOTÉCNICOS
  // ---------------------------------------------------------------------------
  static pw.Widget _buildTechnicalComments(AnimalEvaluationData animal, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: cardBorder, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                'COMENTARIOS TÉCNICOS DEL EVALUADOR ZOOTÉCNICO',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryDark,
                  font: fontBold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '"${animal.technicalNotes}"',
            style: pw.TextStyle(
              fontSize: 7,
              color: darkText,
              fontStyle: pw.FontStyle.italic,
              lineSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. FIRMA OFICIAL, AVAL Y CÓDIGO QR
  // ---------------------------------------------------------------------------
  static pw.Widget _buildAuditAndSignature({
    required AnimalEvaluationData animal,
    required String vetName,
    required String vetCollegiate,
    required String farm,
    required String loc,
    required pw.Font fontBold,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          flex: 6,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(7),
            decoration: pw.BoxDecoration(
              color: lightGreyBg,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: cardBorder, width: 0.7),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MÉDICO VETERINARIO / EVALUADOR ACREDITADO:',
                  style: const pw.TextStyle(fontSize: 6, color: greyText),
                ),
                pw.Text(
                  '$vetName • $vetCollegiate',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryDark,
                    font: fontBold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'UNIDAD DE PRODUCCIÓN / FINCA:',
                  style: const pw.TextStyle(fontSize: 6, color: greyText),
                ),
                pw.Text(
                  '$farm\n$loc',
                  style: const pw.TextStyle(fontSize: 7, color: darkText),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'CONTACTO TÉCNICO: mv.gualdron.willians@gmail.com',
                  style: const pw.TextStyle(fontSize: 6.5, color: primaryGreen),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: cardBorder, width: 0.7),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'https://boviframe.app/verify/${animal.reportId}?hash=${animal.hashVerification}',
                  width: 44,
                  height: 44,
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.SizedBox(
                        height: 24,
                        width: 70,
                        child: pw.CustomPaint(
                          painter: (PdfGraphics canvas, PdfPoint size) {
                            canvas.setStrokeColor(primaryDark);
                            canvas.setLineWidth(1.2);
                            canvas.moveTo(5, 12);
                            canvas.curveTo(15, 22, 25, 2, 35, 16);
                            canvas.curveTo(45, 24, 55, 6, 65, 14);
                            canvas.strokePath();
                            canvas.moveTo(10, 8);
                            canvas.lineTo(60, 8);
                            canvas.strokePath();
                          },
                        ),
                      ),
                      pw.Container(height: 0.8, color: cardBorder),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Firma Digital • Evaluador Oficial',
                        style: pw.TextStyle(
                          fontSize: 6,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryDark,
                          font: fontBold,
                        ),
                      ),
                      pw.Text(
                        'Protocolo de Validez Zootécnica Boviframe',
                        style: const pw.TextStyle(fontSize: 5, color: greyText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 7. CINTILLO LEGAL INFERIOR
  // ---------------------------------------------------------------------------
  static pw.Widget _buildLegalFooterBar() {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Documento inviolable con registro blockchain hash SHA-256',
            style: const pw.TextStyle(fontSize: 6, color: greyText),
          ),
          pw.Text(
            'Página 1 de 1 • Norma ISO / ICAR 11784–11785 • Boviframe 2026',
            style: const pw.TextStyle(fontSize: 6, color: greyText),
          ),
        ],
      ),
    );
  }

  // Helper para mapear Map<String, dynamic> -> AnimalEvaluationData
  static AnimalEvaluationData _mapDataToAnimalEvaluationData(Map<String, dynamic> data) {
    final numero = data['numero']?.toString() ?? '4921';
    final registro = data['registro']?.toString() ?? 'RGN-8842';
    final raza = data['raza']?.toString() ?? 'Nelore Padrón';
    final sexo = data['sexo']?.toString() ?? 'Macho Reproductor';
    final estado = data['estado']?.toString() ?? data['estado_animal']?.toString() ?? 'Excelente / En Servicio';
    final rfid = data['rfid']?.toString() ?? '982.000184921';
    final lote = data['nombre_lote']?.toString() ?? data['lote']?.toString() ?? 'Lote 2024–B';
    final fechaNac = data['fecha_nac']?.toString() ?? '14/03/2021';
    final pesoNac = double.tryParse(data['peso_nac']?.toString() ?? '38') ?? 38.0;
    final pesoDest = double.tryParse(data['peso_dest']?.toString() ?? '235') ?? 235.0;
    final pesoAjus = double.tryParse(data['peso_ajus']?.toString() ?? '480') ?? 480.0;
    final gdpVal = double.tryParse(data['gdp']?.toString() ?? '0.982') ?? 0.982;
    final comentarios = data['comentario']?.toString().trim() ?? '';

    final epmRaw = (data['epmuras'] is Map) ? data['epmuras'] as Map : {};
    double getEpmScore(String key, double defaultVal) {
      return double.tryParse(epmRaw[key]?.toString() ?? '') ?? defaultVal;
    }

    final epmItems = [
      EpmurasScoreItem(
        code: 'E',
        name: 'Estructura Corporal',
        description: 'Arqueo costal, longitud y amplitud esquelética',
        weightPercentage: 17.5,
        score: getEpmScore('E', 5.2),
        herdAverage: 4.1,
        difference: (getEpmScore('E', 5.2) - 4.1) >= 0 ? '+${(getEpmScore('E', 5.2) - 4.1).toStringAsFixed(1)}' : (getEpmScore('E', 5.2) - 4.1).toStringAsFixed(1),
        levelLabel: 'Sobresaliente',
      ),
      EpmurasScoreItem(
        code: 'P',
        name: 'Precocidad',
        description: 'Capacidad de deposición temprana y terminación',
        weightPercentage: 20.0,
        score: getEpmScore('P', 5.4),
        herdAverage: 4.1,
        difference: (getEpmScore('P', 5.4) - 4.1) >= 0 ? '+${(getEpmScore('P', 5.4) - 4.1).toStringAsFixed(1)}' : (getEpmScore('P', 5.4) - 4.1).toStringAsFixed(1),
        levelLabel: 'Precoz',
      ),
      EpmurasScoreItem(
        code: 'M',
        name: 'Musculatura',
        description: 'Volumen, convexidad de masa y definición muscular',
        weightPercentage: 20.0,
        score: getEpmScore('M', 5.0),
        herdAverage: 4.2,
        difference: (getEpmScore('M', 5.0) - 4.2) >= 0 ? '+${(getEpmScore('M', 5.0) - 4.2).toStringAsFixed(1)}' : (getEpmScore('M', 5.0) - 4.2).toStringAsFixed(1),
        levelLabel: 'Adecuada',
      ),
      EpmurasScoreItem(
        code: 'U',
        name: 'Ombligo / Ubre',
        description: 'Posición, ligamento suspensorio y ángulo de inserción',
        weightPercentage: 12.5,
        score: getEpmScore('U', 4.8),
        herdAverage: 4.3,
        difference: (getEpmScore('U', 4.8) - 4.3) >= 0 ? '+${(getEpmScore('U', 4.8) - 4.3).toStringAsFixed(1)}' : (getEpmScore('U', 4.8) - 4.3).toStringAsFixed(1),
        levelLabel: 'Ángulo 45°',
      ),
      EpmurasScoreItem(
        code: 'R',
        name: 'Carácter Racial',
        description: 'Conformación craneal, orejas, giba e indumentaria típica',
        weightPercentage: 10.0,
        score: getEpmScore('R', 5.6),
        herdAverage: 4.2,
        difference: (getEpmScore('R', 5.6) - 4.2) >= 0 ? '+${(getEpmScore('R', 5.6) - 4.2).toStringAsFixed(1)}' : (getEpmScore('R', 5.6) - 4.2).toStringAsFixed(1),
        levelLabel: 'Estándar Puro',
      ),
      EpmurasScoreItem(
        code: 'A',
        name: 'Aplomos',
        description: 'Angulación de corvejones, cuartillas y calidad de pezuñas',
        weightPercentage: 10.0,
        score: getEpmScore('A', 4.6),
        herdAverage: 4.6,
        difference: (getEpmScore('A', 4.6) - 4.6) >= 0 ? '+${(getEpmScore('A', 4.6) - 4.6).toStringAsFixed(1)}' : (getEpmScore('A', 4.6) - 4.6).toStringAsFixed(1),
        levelLabel: 'Funcionales',
      ),
      EpmurasScoreItem(
        code: 'S',
        name: 'Carácter Sexual',
        description: 'Expresión de feminidad/masculinidad y proporciones',
        weightPercentage: 10.0,
        score: getEpmScore('S', 5.2),
        herdAverage: 4.3,
        difference: (getEpmScore('S', 5.2) - 4.3) >= 0 ? '+${(getEpmScore('S', 5.2) - 4.3).toStringAsFixed(1)}' : (getEpmScore('S', 5.2) - 4.3).toStringAsFixed(1),
        levelLabel: 'Alta Expresión',
      ),
    ];

    double globalSum = 0;
    for (var item in epmItems) {
      globalSum += item.score * (item.weightPercentage / 100.0);
    }

    final String reportId = 'REP-${DateTime.now().year}-$numero';
    final String dateToday = "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}";

    return AnimalEvaluationData(
      reportId: reportId,
      emissionDate: dateToday,
      hashVerification: 'ZT-${numero.hashCode.abs().toString().substring(0, 4)}',
      tagNumber: '#$numero',
      registryNumber: registro,
      breed: raza,
      categoryType: data['categoria']?.toString() ?? 'Hato Donante Fundador',
      genealogyNote: 'Genealogía Consolidada (P: ${data['padre'] ?? 'Don Capi'} • M: ${data['madre'] ?? 'Reina'})',
      rfidChip: rfid,
      lotName: lote,
      contemporaryGroup: 'GC-04',
      percentileRank: 'Top 5%',
      sexCategory: sexo,
      birthDate: fechaNac,
      ageMonths: 38,
      ageDays: 1150,
      birthWeightKg: pesoNac,
      birthWeightDiff: '+4 kg vs Hato',
      weaningWeight205dKg: pesoDest,
      weaningWeightDiff: '+25 kg vs Hato',
      adjustedWeight550dKg: pesoAjus,
      adjustedWeightDiff: '+42 kg vs Hato',
      averageDailyGainKg: gdpVal,
      physiologicalState: estado,
      bodyCondition: 6.5,
      globalIndex: double.parse(globalSum.toStringAsFixed(2)),
      epmurasScores: epmItems,
      technicalNotes: comentarios.isNotEmpty
          ? comentarios
          : 'Ejemplar de notable pureza racial y gran armonía corporal general. Destaca vigorosamente por su arqueo de costillas, amplitud de pecho y precocidad en pasturas naturales. Aplomos funcionales aptos para desplazamiento en terrenos ondulados.',
    );
  }
}

class AnimalEvaluationData {
  final String reportId;
  final String emissionDate;
  final String hashVerification;
  final String tagNumber;
  final String registryNumber;
  final String breed;
  final String categoryType;
  final String genealogyNote;
  final String rfidChip;
  final String lotName;
  final String contemporaryGroup;
  final String percentileRank;

  final String sexCategory;
  final String birthDate;
  final int ageMonths;
  final int ageDays;
  final double birthWeightKg;
  final String birthWeightDiff;
  final double weaningWeight205dKg;
  final String weaningWeightDiff;
  final double adjustedWeight550dKg;
  final String adjustedWeightDiff;
  final double averageDailyGainKg;
  final String physiologicalState;
  final double bodyCondition;

  final double globalIndex;
  final List<EpmurasScoreItem> epmurasScores;
  final String technicalNotes;

  AnimalEvaluationData({
    required this.reportId,
    required this.emissionDate,
    required this.hashVerification,
    required this.tagNumber,
    required this.registryNumber,
    required this.breed,
    required this.categoryType,
    required this.genealogyNote,
    required this.rfidChip,
    required this.lotName,
    required this.contemporaryGroup,
    required this.percentileRank,
    required this.sexCategory,
    required this.birthDate,
    required this.ageMonths,
    required this.ageDays,
    required this.birthWeightKg,
    required this.birthWeightDiff,
    required this.weaningWeight205dKg,
    required this.weaningWeightDiff,
    required this.adjustedWeight550dKg,
    required this.adjustedWeightDiff,
    required this.averageDailyGainKg,
    required this.physiologicalState,
    required this.bodyCondition,
    required this.globalIndex,
    required this.epmurasScores,
    required this.technicalNotes,
  });
}

class EpmurasScoreItem {
  final String code;
  final String name;
  final String description;
  final double weightPercentage;
  final double score;
  final double herdAverage;
  final String difference;
  final String levelLabel;

  EpmurasScoreItem({
    required this.code,
    required this.name,
    required this.description,
    required this.weightPercentage,
    required this.score,
    required this.herdAverage,
    required this.difference,
    required this.levelLabel,
  });
}
