import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

Future<void> exportarResumenGrupalPDF({
  required Map<String, dynamic> sessionData,
  required Map<String, dynamic> usuario,
  required List<Map<String, dynamic>> evaluaciones,
  required Map<String, double> promedios,
  required Map<String, dynamic> mejor,
  required Map<String, dynamic> peor,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'REPORTE GRUPAL DE EVALUACIÃ“N EPMURAS',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Datos del Evaluador:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Nombre: ' + (usuario['nombre'] ?? '-')),
            pw.Text('ProfesiÃ³n: ' + (usuario['profesion'] ?? '-')),
            pw.Text('Colegio: ' + (usuario['colegio'] ?? '-')),
            pw.Text('UbicaciÃ³n: ' + (usuario['ubicacion'] ?? '-')),
            pw.SizedBox(height: 12),
            pw.Text(
              'Unidad de ProducciÃ³n:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Nombre: ' + (sessionData['nombreUP'] ?? '-')),
            pw.Text('DirecciÃ³n: ' + (sessionData['direccion'] ?? '-')),
            pw.Text('Estado: ' + (sessionData['estado'] ?? '-')),
            pw.Text('Municipio: ' + (sessionData['municipio'] ?? '-')),
            pw.SizedBox(height: 12),
            pw.Text(
              'Animales Evaluados:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.ListView.builder(
              itemCount: evaluaciones.length,
              itemBuilder: (context, index) {
                final animal = evaluaciones[index];
                return pw.Text(
                  '${index + 1}. RGN: ${animal['rgn'] ?? '-'} | E: ${animal['E'] ?? '-'} | P: ${animal['P'] ?? '-'} | M: ${animal['M'] ?? '-'}',
                );
              },
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Promedios Generales:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            ...promedios.entries.map(
              (e) => pw.Text('${e.key}: ${e.value.toStringAsFixed(2)}'),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Mejor Animal: ${mejor['nombre']} (Ãndice: ${mejor['indice']})',
            ),
            pw.Text(
              'Peor Animal: ${peor['nombre']} (Ãndice: ${peor['indice']})',
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Generado por BOVIFrame',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}



