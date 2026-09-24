import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsAdminCreateScreen extends StatefulWidget {
  const NewsAdminCreateScreen({Key? key}) : super(key: key);

  @override
  State<NewsAdminCreateScreen> createState() => _NewsAdminCreateScreenState();
}

class _NewsAdminCreateScreenState extends State<NewsAdminCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSaving = false;
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

  String? _validateUrl(String url) {
    try {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) return null;
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> sendLocalNotification(String title) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/send-news-notification'),
        headers: {'Content-Type': 'application/json'},
        body: '{"title": "$title"}',
      );

      if (response.statusCode == 200) {
        print('âœ… NotificaciÃ³n enviada');
      } else {
        print('âŒ Error al enviar notificaciÃ³n: ${response.body}');
      }
    } catch (e) {
      print('âŒ ExcepciÃ³n al enviar notificaciÃ³n: $e');
    }
  }

  final List<String> allowedUserIds = [
    'p9HOIe0bhuXKCXtLonmO2DXIQyf2',
    'M7KKEeEg3jMgtWmm2soRswNMrWg2',
    'mVwfoVqwbTOnAt1XVhXqrzjKuwI2',
  ];

  Future<void> _submitForm() async {
    final titleText = _titleController.text.trim();
    await sendLocalNotification(titleText);
    final externalUrl =
        _urlController.text.trim().isNotEmpty
            ? _validateUrl(_urlController.text.trim())
            : null;
    final contentText = _contentController.text.trim();

    if (titleText.isEmpty && externalUrl == null) {
      setState(() {
        _errorMessage = 'Debe ingresar al menos un tÃ­tulo o URL vÃ¡lida';
        _isSaving = false;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !allowedUserIds.contains(user.uid)) {
      setState(() {
        _errorMessage = 'No tienes permisos para crear noticias';
        _isSaving = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> docData = {
        'title': titleText.isNotEmpty ? titleText : 'Sin tÃ­tulo',
        'content': contentText.isNotEmpty ? contentText : null,
        'externalUrl': externalUrl,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Admin',
        'category': _selectedCategory,
        'timestamp': FieldValue.serverTimestamp(),
        'dateString': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };

      await LocalFirestore.instance.collection('news').add(docData);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/news_public');
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Error de Firebase: ${e.message}';
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: ${e.toString()}';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text('Crear Noticia (Admin)'),
        titleTextStyle: TextStyle(
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
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
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
                    onPressed: _isSaving ? null : _submitForm,
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
                            : const Text('PUBLICAR NOTICIA'),
                  ),
                ],
              ),
            ),

            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}



