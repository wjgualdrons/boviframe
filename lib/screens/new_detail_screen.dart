import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

class NewsDetailScreen extends StatefulWidget {
  final String documentId;
  const NewsDetailScreen({Key? key, required this.documentId})
    : super(key: key);

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

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

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  bool _loading = true;
  String? _title, _content, _category, _externalUrl;
  Timestamp? _timestamp;
  String? _authorName;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _loadNewsDocument();
    _initializeLocaleAndLoad();
  }

  Future<void> _initializeLocaleAndLoad() async {
    await initializeDateFormatting('es', null); // ðŸ‘ˆ
    await _loadNewsDocument();
  }

  Future<void> _loadNewsDocument() async {
    try {
      final doc =
          await LocalFirestore.instance
              .collection('news')
              .doc(widget.documentId)
              .get();

      if (!mounted) return;

      if (!doc.exists) {
        setState(() => _loading = false);
        return;
      }

      final data = doc.data()!;
      if (!mounted) return;
      setState(() {
        _title = data['title'] as String?;
        _content = data['content'] as String?;
        _category = data['category'] as String?;
        _timestamp = data['timestamp'] as Timestamp?;
        _externalUrl = data['externalUrl'] as String?;
        _authorName = data['authorName'] as String?;
        _date = _timestamp?.toDate();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openWebView(BuildContext context) {
    if (_externalUrl == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExternalWebViewScreen(url: _externalUrl!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_title == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Noticia no encontrada')),
        body: const Center(child: Text('La noticia solicitada no existe.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'NOTICIAS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),

      body: Container(
        color: const Color(0xFFF2F2F2),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ðŸ”· CategorÃ­a y Fecha con Ã­conos
                Row(
                  children: [
                    if (_category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              categoryColors[_category!] ??
                              Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.label_important,
                              size: 14,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _category!.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),
                    if (_date != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMM yyyy', 'es').format(_date!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // ðŸ“° TÃ­tulo
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _title ?? '',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),

                // ðŸ‘¤ Autor con icono
                if (_authorName != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Por $_authorName',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // ðŸ“– Contenido
                if (_content != null && _content!.isNotEmpty)
                  Text(
                    _content!,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: Colors.black87,
                    ),
                  ),

                // ðŸ”— Contenido externo
                if (_externalUrl != null && _externalUrl!.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openWebView(context),
                      icon: const Icon(Icons.link),
                      label: const Text(
                        'Ver contenido completo',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],

                // âŒ Sin contenido
                if (_content == null && _externalUrl == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(
                          'Esta noticia no tiene contenido disponible.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExternalWebViewScreen extends StatefulWidget {
  final String url;
  const ExternalWebViewScreen({Key? key, required this.url}) : super(key: key);

  @override
  State<ExternalWebViewScreen> createState() => _ExternalWebViewScreenState();
}

class _ExternalWebViewScreenState extends State<ExternalWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    String finalUrl = widget.url.trim();

    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) => setState(() => _isLoading = false),
            ),
          )
          ..loadRequest(Uri.parse(finalUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text('Contenido completo'),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}



