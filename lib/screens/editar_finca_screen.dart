import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';

class EditarFincaScreen extends StatefulWidget {
  @override
  _EditarFincaScreenState createState() => _EditarFincaScreenState();
}

class _EditarFincaScreenState extends State<EditarFincaScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> fincaData = {};
  final Map<String, TextEditingController> controllers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    fincaData = args;

    // Inicializar controladores
    for (final field in ['nombreUP', 'direccion', 'estado', 'municipio']) {
      controllers[field] = TextEditingController(text: fincaData[field] ?? '');
    }
  }

  Future<void> _guardarCambios() async {
    final key = fincaData['key'];
    final ref = LocalFirestore.instance.collection('sesiones').doc(key);

    final actualizada = {
      'nombreUP': controllers['nombreUP']!.text,
      'direccion': controllers['direccion']!.text,
      'estado': controllers['estado']!.text,
      'municipio': controllers['municipio']!.text,
    };

    await ref.update(actualizada);
    Navigator.pop(context); // Vuelve a la pantalla anterior
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar Finca')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField('Nombre de la UP', 'nombreUP'),
              _buildTextField('DirecciÃ³n', 'direccion'),
              _buildTextField('Estado', 'estado'),
              _buildTextField('Municipio', 'municipio'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardarCambios,
                child: Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controllers[key],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}




