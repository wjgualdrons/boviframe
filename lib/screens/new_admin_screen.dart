import 'package:boviframe/services/local_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'new_edit_screen.dart';

class NewsAdminScreen extends StatefulWidget {
  const NewsAdminScreen({Key? key}) : super(key: key);

  @override
  State<NewsAdminScreen> createState() => _NewsAdminScreenState();
}

class _NewsAdminScreenState extends State<NewsAdminScreen> {
  final LocalFirestore _firestore = LocalFirestore.instance;
  final List<String> _authorizedUIDs = [
    'p9HOIe0bhuXKCXtLonmO2DXIQyf2',
    'M7KKEeEg3jMgtWmm2soRswNMrWg2',
    'mVwfoVqwbTOnAt1XVhXqrzjKuwI2',
  ];

  Future<void> _deleteNews(String docId) async {
    try {
      await _firestore.collection('news').doc(docId).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Noticia eliminada')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar noticia'),
            content: const Text('Â¿Seguro que deseas eliminar esta noticia?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _deleteNews(docId);
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAuthorized = user != null && _authorizedUIDs.contains(user.uid);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text('Administrar Noticias (Admin)'),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
      ),
      body:
          isAuthorized
              ? StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('news')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No hay noticias para administrar.'),
                    );
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final title = data['title'] as String? ?? '';
                      final ts = data['timestamp'] as Timestamp?;
                      final date = ts?.toDate();
                      final formattedDate =
                          (date != null)
                              ? '${date.day.toString().padLeft(2, '0')}/'
                                  '${date.month.toString().padLeft(2, '0')}/'
                                  '${date.year}'
                              : '';

                      final category =
                          data['category'] as String? ?? 'Sin categorÃ­a';
                      final categoryColors = {
                        'EducaciÃ³n': Colors.deepPurple.shade100,
                        'Ciencia': Colors.teal.shade100,
                        'Manejo': Colors.blue.shade100,
                        'ReproducciÃ³n': Colors.orange.shade100,
                        'GenÃ©tica': Colors.green.shade100,
                        'Sanidad': Colors.red.shade100,
                        'Agricultura': Colors.brown.shade100,
                        'Otras noticias': Colors.grey.shade300,
                        'Evento': Colors.pink.shade100,
                        'Anuncio': Colors.amber.shade100,
                        'Otro': Colors.grey.shade200,
                      };
                      final categoryColor =
                          categoryColors[category] ?? Colors.grey.shade200;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: Colors.blue.shade700,
                              width: 4,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: categorÃ­a + fecha
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: categoryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // TÃ­tulo
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Botones
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  label: const Text(
                                    'Editar',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => NewsEditScreen(
                                              documentId: docs[index].id,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed:
                                      () => _confirmDelete(docs[index].id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              )
              : Center(
                child: Text(
                  'No tienes permiso para administrar noticias.',
                  style: TextStyle(fontSize: 18, color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
    );
  }
}



