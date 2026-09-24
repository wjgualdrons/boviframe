import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:boviframe/screens/epmuras/comparacion_epm_chart.dart';

class ReportScreenCertificado extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  final Map<String, dynamic> animalData;

  const ReportScreenCertificado({
    Key? key,
    required this.sessionData,
    required this.animalData,
  }) : super(key: key);

  Future<void> _exportCertificadoPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Container(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "CERTIFICADO DE EVALUACIÃ“N INDIVIDUAL",
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text("Evaluador: ${sessionData['evaluador'] ?? '-'}"),
                  pw.Text(
                    "Fecha de EvaluaciÃ³n: ${sessionData['fechaEvaluacion'] ?? '-'}",
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    "Datos del Animal:",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text("Nombre o ID: ${animalData['nombre'] ?? '-'}"),
                  pw.Text("RGN: ${animalData['rgn'] ?? '-'}"),
                  pw.Text("Sexo: ${animalData['sexo'] ?? '-'}"),
                  pw.Text("Estado: ${animalData['estado'] ?? '-'}"),
                  pw.Text("Peso: ${animalData['peso'] ?? '-'}"),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    "EPMURAS:",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text("E: ${animalData['E'] ?? '-'}"),
                  pw.Text("P: ${animalData['P'] ?? '-'}"),
                  pw.Text("M: ${animalData['M'] ?? '-'}"),
                  pw.Text("U: ${animalData['U'] ?? '-'}"),
                  pw.Text("R: ${animalData['R'] ?? '-'}"),
                  pw.Text("A: ${animalData['A'] ?? '-'}"),
                  pw.Text("S: ${animalData['S'] ?? '-'}"),
                ],
              ),
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text("Certificado del Animal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportCertificadoPDF,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: ListView(
          children: [
            Text(
              "Nombre o ID: ${animalData['nombre'] ?? '-'}",
              style: TextStyle(fontSize: 18),
            ),
            Text("RGN: ${animalData['rgn'] ?? '-'}"),
            Text("Sexo: ${animalData['sexo'] ?? '-'}"),
            Text("Estado: ${animalData['estado'] ?? '-'}"),
            Text("Peso: ${animalData['peso'] ?? '-'}"),
            const SizedBox(height: 16),
            const Text(
              "EPMURAS:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("E: ${animalData['E'] ?? '-'}"),
            Text("P: ${animalData['P'] ?? '-'}"),
            Text("M: ${animalData['M'] ?? '-'}"),
            Text("U: ${animalData['U'] ?? '-'}"),
            Text("R: ${animalData['R'] ?? '-'}"),
            Text("A: ${animalData['A'] ?? '-'}"),
            Text("S: ${animalData['S'] ?? '-'}"),

            const SizedBox(height: 24),
            Text(
              "ComparaciÃ³n visual EPM:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 200,
              child: ComparacionEPMChart(evaluations: [animalData]),
            ),
          ],
        ),
      ),
    );
  }
}



