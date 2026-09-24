import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';

import 'package:intl/intl.dart';

class NewsEditScreen extends StatefulWidget {
  final String documentId;

  const NewsEditScreen({Key? key, required this.documentId}) : super(key: key);

  @override
  State<NewsEditScreen> createState() => _NewsEditScreenState();
}

class _NewsEditScreenState extends State<NewsEditScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;
  String? _errorMessage;

  final Map<String, Color> categoryColors = {
    'EducaciÃ³n': Colors.deepPurple.shade100,
    'Ciencia': Colors.teal.shade100,
    'Manejo': Colors.blue.shade100,
    'ReproducciÃ³n': Colors.orange.shade100,
    'GenÃ©tica': Colors.green.shade100,
    'Sanidad': Colors.red.shade100,
    'Agricultura': Colors.brown.shade100,
    'Otras noticias': Colors.grey.shade300,
  };

  final List<String> _categories = [
    'EducaciÃ³n',
    'Ciencia',
    'Manejo',
    'ReproducciÃ³n',
    'GenÃ©tica',
    'Sanidad',
    'Agricultura',
    'Otras noticias',
  ];
  String _selectedCategory = 'EducaciÃ³n';

 @override
void initState() {
  super.initState();
  _loadExistingData();
}


  Future<void> _loadExistingData() async {
    try {
      final doc =
          await LocalFirestore.instance
              .collection('news')
              .doc(widget.documentId)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        _titleController.text = (data['title'] ?? '') as String;
        _urlController.text = (data['externalUrl'] ?? '') as String;
        _contentController.text = (data['content'] ?? '') as String;
        _selectedCategory = (data['category'] ?? 'EducaciÃ³n') as String;
      }
    } catch (e) {
      _errorMessage = 'Error al cargar la noticia';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _saveChanges() async {
    final title = _titleController.text.trim();
    final url = _urlController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && url.isEmpty) {
      setState(() {
        _errorMessage = 'Debe ingresar al menos un tÃ­tulo o URL vÃ¡lida';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await LocalFirestore.instance
          .collection('news')
          .doc(widget.documentId)
          .update({
            'title': title.isNotEmpty ? title : 'Sin tÃ­tulo',
            'externalUrl': url.isNotEmpty ? url : null,
            'content': content.isNotEmpty ? content : null,
            'category': _selectedCategory,
            'timestamp': FieldValue.serverTimestamp(),
            'dateString': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          });
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al guardar los cambios';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Editar Noticia (Admin)'),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'CategorÃ­a',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      value: _selectedCategory,
                      items:
                          _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: categoryColors[category],
                                    ),
                                  ),
                                  Text(category),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'TÃ­tulo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'URL Externa (opcional)',
                        hintText: 'https://www.ejemplo.com/noticia.html',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText:
                            _urlController.text.isEmpty
                                ? 'Contenido'
                                : 'Contenido (opcional cuando hay URL)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          _isSaving
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('GUARDAR CAMBIOS'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}



