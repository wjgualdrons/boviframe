import 'package:flutter/material.dart';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: const EpmurasInfographic(),
      debugShowCheckedModeBanner: false,
    );
  }

class EpmurasInfographic extends StatelessWidget {
  const EpmurasInfographic({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Bases TeÃ³ricas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.8, // la lÃ­nea ocuparÃ¡ el 80% de la altura
                    child: Container(
                      width: 4, // grosor de la lÃ­nea
                      color: Colors.blue.shade600,
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  _buildAlternatingItem(
                    imagePath: 'assets/img/estructura.png',
                    title: 'Estructura',
                    description:
                        'EvalÃºa el tamaÃ±o, capacidad y robustez del animal, correlacionando con longevidad y producciÃ³n.',
                    isLeft: true,
                  ),
                  _buildAlternatingItem(
                    imagePath: 'assets/img/precocidad.png',
                    title: 'Precocidad',
                    description:
                        'Ritmo de desarrollo en relaciÃ³n a la edad, crucial para reducir costos y acelerar producciÃ³n.',
                    isLeft: false,
                  ),
                  _buildAlternatingItem(
                    imagePath: 'assets/img/musculatura.png',
                    title: 'Musculatura',
                    description:
                        'Indica la cantidad y calidad de carne, evaluando el volumen y forma de los mÃºsculos.',
                    isLeft: true,
                  ),
                  _buildAlternatingItem(
                    imagePath: 'assets/img/ombligo.png',
                    title: 'Ombligo',
                    description:
                        'EvalÃºa tamaÃ±o y forma del ombligo, preferible pequeÃ±o y bien adherido para evitar problemas.',
                    isLeft: false,
                  ),
                  _buildAlternatingItem(
                    imagePath: 'assets/img/vaca6.png',
                    isLeft: true,
                  ),
                  _buildAlternatingItem(
                    imagePath: 'assets/img/raza.png',
                    title: 'Raza',
                    description:
                        'Verifica rasgos tÃ­picos de la raza, confirmando pureza y caracterÃ­sticas deseables.',
                    isLeft: true,
                  ),
                  _buildAlternatingItem(
                    imagePath: 'assets/img/aplomos.png',
                    title: 'Aplomos',
                    description:
                        'ConformaciÃ³n de extremidades, esenciales para movilidad y longevidad en pastoreo.',
                    isLeft: false,
                  ),
                  _buildAlternatingItem(
                    imagePath: 'assets/img/vaca9.png',
                    isLeft: false,
                  ),
                  _buildAlternatingItem(
                    imagePath: 'assets/img/sexualidad.png',
                    title: 'Sexualidad',
                    description:
                        'EvalÃºa Ã³rganos reproductivos y comportamiento, fundamental para la crÃ­a.',
                    isLeft: true,
                  ),
                  // SecciÃ³n de Conclusiones mÃ¡s estilizada
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Conclusiones',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/img/conclusiones.png',
                              width: MediaQuery.of(context).size.width * 0.75,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Text(
                            'La tÃ©cnica EPMURAS es esencial para optimizar la selecciÃ³n ganadera, enfocÃ¡ndose en parÃ¡metros fÃ­sicos y reproductivos que aseguran la calidad y eficiencia en la producciÃ³n animal.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tabla de CaracterÃ­sticas
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          Colors.blue.shade800,
                        ),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        dataTextStyle: const TextStyle(fontSize: 12),
                        columns: const [
                          DataColumn(label: Text('CaracterÃ­stica')),
                          DataColumn(
                            label: Text('DescalificaciÃ³n'),
                            numeric: true,
                          ),
                          DataColumn(label: Text('PuntuaciÃ³n'), numeric: true),
                        ],

                        rows: const [
                          DataRow(
                            cells: [
                              DataCell(Text('(E) Estructura')),
                              DataCell(Text('0')),
                              DataCell(Text('1 2 3 4 5 6')),
                            ],
                          ),
                          DataRow(
                            cells: [
                              DataCell(Text('(P) Precocidad')),
                              DataCell(Text('0')),
                              DataCell(Text('1 2 3 4 5 6')),
                            ],
                          ),
                          DataRow(
                            cells: [
                              DataCell(Text('(M) Musculatura')),
                              DataCell(Text('0')),
                              DataCell(Text('1 2 3 4 5 6')),
                            ],
                          ),
                          DataRow(
                            cells: [
                              DataCell(Text('(U) Ombligo')),
                              DataCell(Text('0')),
                              DataCell(Text('1 2 3 4 5 6')),
                            ],
                          ),
                          DataRow(
                            cells: [
                              DataCell(Text('(R) Car. Racial')),
                              DataCell(Text('0')),
                              DataCell(Text('1 2 3 4 5 6')),
                            ],
                          ),
                          DataRow(
                            cells: [
                              DataCell(Text('(A) Aplomos')),
                              DataCell(Text('0')),
                              DataCell(Text('1 2 3 4 5 6')),
                            ],
                          ),
                          DataRow(
                            cells: [
                              DataCell(Text('(S) Car. Sexual')),
                              DataCell(Text('0')),
                              DataCell(Text('1 2 3 4')),
                            ],
                          ),
                        ],

                        dataRowHeight: 36,
                        headingRowHeight: 48,
                        dividerThickness: 1,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildAlternatingItem({
    required String imagePath,
    String? title,
    String? description,
    required bool isLeft,
  }) {
    final dot = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Imagen limitada a 150Ã—150
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150, maxHeight: 150),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
        ),
        // TÃ­tulo
        if (title != null) ...[
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ],
        // DescripciÃ³n
        if (description != null) ...[
          const SizedBox(height: 2),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          // izquierda o hueco
          Expanded(flex: 4, child: isLeft ? content : const SizedBox()),
          // conector + punto
          Expanded(
            flex: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment:
                      isLeft ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    width: 20, // longitud del conector
                    height: 2,
                    color: Colors.blue.shade200,
                  ),
                ),
                dot,
              ],
            ),
          ),
          // derecha o hueco
          Expanded(flex: 4, child: isLeft ? const SizedBox() : content),
        ],
      ),
    );
  }
}



