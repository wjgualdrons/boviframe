// lib/screens/new_public_screen.dart

import 'package:boviframe/services/local_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewsPublicScreen extends StatefulWidget {
  const NewsPublicScreen({Key? key}) : super(key: key);

  @override
  State<NewsPublicScreen> createState() => _NewsPublicScreenState();
}

class _NewsPublicScreenState extends State<NewsPublicScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalFirestore _firestore = LocalFirestore.instance;

  // Cambia aquÃ­ por el UID exacto de tu administrador:
  bool get _isAdmin {
    final user = _auth.currentUser;
    if (user == null) return false;

    const allowedUserIds = [
      'p9HOIe0bhuXKCXtLonmO2DXIQyf2',
      'M7KKEeEg3jMgtWmm2soRswNMrWg2',
      'mVwfoVqwbTOnAt1XVhXqrzjKuwI2',
    ];

    return allowedUserIds.contains(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text('ðŸ“°  ULTIMAS NOTICIAS  ðŸ“°'),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ESTE BLOQUE SOLO SE VE SI _isAdmin == true
          if (_isAdmin) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Noticia'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade200,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/news_create');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.manage_accounts),
                      label: const Text('Administrar Noticias'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade200,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/news_admin');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          // El listado (visible para todos, admin o no)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                  return const Center(child: Text('AÃºn no hay noticias.'));
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Sin tÃ­tulo';
                    final category = data['category'] ?? 'General';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final formattedDate =
                        timestamp != null
                            ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
                            : 'Fecha no disponible';
                    final newsCategory = data['category'] as String? ?? 'Otro';
                    final categoryColors = {
                      'EducaciÃ³n': Colors.deepPurple.shade100,
                      'Ciencia': Colors.teal.shade100,
                      'Manejo': Colors.blue.shade100,
                      'ReproducciÃ³n': Colors.orange.shade100,
                      'GenÃ©tica': Colors.green.shade100,
                      'Sanidad': Colors.red.shade100,
                      'Agricultura': Colors.brown.shade100,
                      'Otras noticias': Colors.grey.shade300,
                      'General': Colors.indigo.shade100,
                      'Evento': Colors.pink.shade100,
                      'Anuncio': Colors.amber.shade100,
                      'Otro': Colors.grey.shade200,
                    };

                    final categoryColor =
                        categoryColors[newsCategory] ?? Colors.grey.shade200;

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed('/news_detail', arguments: docs[index].id);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo
                            Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/icons/logo1.png',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            // Contenido
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // CategorÃ­a con fondo
                                  const SizedBox(height: 8),

                                  // TÃ­tulo
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Fecha y categorÃ­a juntos (debajo del tÃ­tulo)
                                  Row(
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: categoryColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



