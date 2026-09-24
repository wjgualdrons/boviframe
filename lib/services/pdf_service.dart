// lib/services/pdf_service.dart

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:boviframe/services/local_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  static Future<Uint8List> generateAnimalPdfBytes({
    required Map<String, dynamic> data,
    Uint8List? animalImage,
    Uint8List? radarImage,
    Uint8List? barImage,
  }) async {
    // AutenticaciÃ³n anÃ³nima
    final comentarios = (data['comentario']?.toString() ?? '').trim();

    // 1) Datos bÃ¡sicos
    final numero = data['numero']?.toString() ?? '';
    final registro = data['registro']?.toString() ?? '';

    // 2) Logos
    final headerLogo =
        (await rootBundle.load('assets/icons/logo1.png')).buffer.asUint8List();
    final footerLogo =
        (await rootBundle.load(
          'assets/icons/logoapp2.png',
        )).buffer.asUint8List();
    final pageWidth = PdfPageFormat.a4.availableWidth;

    // 3) Productor
    final sid =
        (data['sessionId'] as String?) ?? (data['session_id'] as String?) ?? '';
    String producText = '';
    if (sid.isNotEmpty) {
      final prodSnap =
          await LocalFirestore.instance
              .collection('sesiones')
              .doc(sid)
              .collection('datos_productor')
              .get();
      if (prodSnap.docs.isNotEmpty) {
        final p = prodSnap.docs.first.data();
        producText =
            'Productor: ${p['unidad_produccion'] ?? '-'},  ${p['estado'] ?? '-'}';
      }
    }

    // 4) Evaluador
    String userName = '-';
    String userEmail = '-';
    String userLoc = '-';
    if (sid.isNotEmpty) {
      final sessSnap =
          await LocalFirestore.instance
              .collection('sesiones')
              .doc(sid)
              .get();
      if (sessSnap.exists) {
        final usuarioId = sessSnap.data()?['userId'] as String? ?? '';
        if (usuarioId.isNotEmpty) {
          final usrSnap =
              await LocalFirestore.instance
                  .collection('usuarios')
                  .doc(usuarioId)
                  .get();
          if (usrSnap.exists) {
            final u = usrSnap.data()!;
            userName = u['nombre'] as String? ?? userName;
            userEmail = u['email'] as String? ?? userEmail;
            userLoc = u['ubicacion'] as String? ?? userLoc;
          }
        }
      }
    }

    // 5) EPMURAS + promedios
    final epmKeys = ['E', 'P', 'M', 'U', 'R', 'A', 'S'];
    final epmLabels = [
      'Estructura (E)',
      'Precocidad (P)',
      'Musculatura (M)',
      'Ombligo (U)',
      'Caract. Racial (R)',
      'Aplomos (A)',
      'Caract. Sexual (S)',
    ];
    final rawEpm = {
      for (var i = 0; i < epmKeys.length; i++)
        epmLabels[i]:
            double.tryParse(data['epmuras']?[epmKeys[i]]?.toString() ?? '') ??
            0.0,
    };
    final avgEpm = {for (var lbl in epmLabels) lbl: 0.0};
    if (sid.isNotEmpty) {
      final evalSnap =
          await LocalFirestore.instance
              .collection('sesiones')
              .doc(sid)
              .collection('evaluaciones_animales')
              .get();
      if (evalSnap.docs.isNotEmpty) {
        for (var d in evalSnap.docs) {
          final m = d.data()['epmuras'] as Map<String, dynamic>? ?? {};
          for (var i = 0; i < epmKeys.length; i++) {
            avgEpm[epmLabels[i]] =
                avgEpm[epmLabels[i]]! +
                (double.tryParse(m[epmKeys[i]]?.toString() ?? '') ?? 0.0);
          }
        }
        avgEpm.updateAll((k, v) => v / evalSnap.docs.length);
      }
    }

    // 6) Pesos + promedios
    final pesLabels = ['Peso Nacer', 'Peso Destete', 'Peso Ajustado'];
    final pesKeys = ['peso_nac', 'peso_dest', 'peso_ajus'];
    final rawPes = {
      for (var i = 0; i < pesKeys.length; i++)
        pesLabels[i]:
            double.tryParse(data[pesKeys[i]]?.toString() ?? '') ?? 0.0,
    };
    final avgPes = {for (var lbl in pesLabels) lbl: 0.0};
    if (sid.isNotEmpty) {
      final evalSnap =
          await LocalFirestore.instance
              .collection('sesiones')
              .doc(sid)
              .collection('evaluaciones_animales')
              .get();
      if (evalSnap.docs.isNotEmpty) {
        for (var d in evalSnap.docs) {
          final m = d.data();
          for (var i = 0; i < pesKeys.length; i++) {
            avgPes[pesLabels[i]] =
                avgPes[pesLabels[i]]! +
                (double.tryParse(m[pesKeys[i]]?.toString() ?? '') ?? 0.0);
          }
        }
        avgPes.updateAll((k, v) => v / evalSnap.docs.length);
      }
    }

    // 7) ConstrucciÃ³n del PDF
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        build:
            (_) => [
              // Header
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Numero $numero',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                        pw.Text(
                          'Reg $registro',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Image(pw.MemoryImage(headerLogo), width: 60, height: 60),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.blue, thickness: 2),
              pw.SizedBox(height: 12),

              // Foto + datos del animal
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: pageWidth * .6,
                    height: 180,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      image:
                          animalImage != null
                              ? pw.DecorationImage(
                                image: pw.MemoryImage(animalImage),
                                fit: pw.BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        animalImage == null
                            ? pw.Center(child: pw.Text('Sin foto'))
                            : null,
                  ),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Sexo: ${data['sexo']?.toString() ?? '-'}'),
                      pw.Text('Estado: ${data['estado']?.toString() ?? '-'}'),
                      pw.Text(
                        'Fecha Nac: ${data['fecha_nac']?.toString() ?? '-'}',
                      ),
                      pw.Text(
                        'Fecha Dest: ${data['fecha_dest']?.toString() ?? '-'}',
                      ),
                      pw.Text(
                        'Peso Nac: ${data['peso_nac']?.toString() ?? '-'}',
                      ),
                      pw.Text(
                        'Peso Dest: ${data['peso_dest']?.toString() ?? '-'}',
                      ),
                      pw.Text(
                        'Peso Ajustado: ${data['peso_ajus']?.toString() ?? '-'}',
                      ),
                      pw.Text(
                        'Edad DÃ­as: ${data['edad_dias']?.toString() ?? '-'}',
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // Productor
              if (producText.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4, bottom: 12),
                  child: pw.Text(
                    producText,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

              // Tabla + grÃ¡ficos
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: (pageWidth - 12) / 2,
                    child: pw.Table.fromTextArray(
                      headers: ['EvaluaciÃ³n', 'Valor', 'Promedio'],
                      data: [
                        for (var i = 0; i < epmLabels.length; i++)
                          [
                            epmLabels[i],
                            rawEpm[epmLabels[i]]!.toStringAsFixed(0),
                            avgEpm[epmLabels[i]]!.toStringAsFixed(1),
                          ],
                        [
                          'Peso Nacer',
                          rawPes['Peso Nacer']!.toStringAsFixed(0),
                          avgPes['Peso Nacer']!.toStringAsFixed(0),
                        ],
                        [
                          'Peso Destete',
                          rawPes['Peso Destete']!.toStringAsFixed(0),
                          avgPes['Peso Destete']!.toStringAsFixed(0),
                        ],
                        [
                          'Peso Ajustado',
                          rawPes['Peso Ajustado']!.toStringAsFixed(0),
                          avgPes['Peso Ajustado']!.toStringAsFixed(0),
                        ],
                      ],
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        color: PdfColors.white,
                      ),
                      headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
                      cellStyle: pw.TextStyle(fontSize: 9),
                      cellAlignment: pw.Alignment.centerLeft,
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      columnWidths: {
                        0: pw.FlexColumnWidth(4),
                        1: pw.FlexColumnWidth(1.5),
                        2: pw.FlexColumnWidth(1.5),
                      },
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Container(
                    width: (pageWidth - 12) / 2,
                    child: pw.Column(
                      children: [
                        if (radarImage != null)
                          pw.Image(
                            pw.MemoryImage(radarImage),
                            width: (pageWidth - 12) / 2,
                            height: 140,
                          ),
                        pw.SizedBox(height: 8),
                        if (barImage != null)
                          pw.Image(
                            pw.MemoryImage(barImage),
                            width: (pageWidth - 12) / 2,
                            height: 140,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Comentarios
              pw.Text(
                'Comentarios:',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              comentarios.isNotEmpty
                  ? pw.Text(
                    comentarios,
                    style: pw.TextStyle(fontSize: 13, lineSpacing: 4),
                  )
                  : pw.Text(
                    'Sin comentarios.',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),

              // Evaluador + firma
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  pw.Text('Evaluador: $userName'),
                  pw.Spacer(),
                  pw.Text(
                    'Firma:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Container(width: 120, height: 0.5, color: PdfColors.grey),
                ],
              ),

              pw.Text('UbicaciÃ³n: $userLoc'),
              pw.Text('Correo: $userEmail'),

              // Footer
              pw.Spacer(),
              pw.Divider(color: PdfColors.blue, thickness: 2),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Spacer(),
                  pw.Image(pw.MemoryImage(footerLogo), width: 100, height: 100),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generado: ${DateTime.now().toString().split(' ').first}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ),
            ],
      ),
    );

    return pdf.save();
  }
}



