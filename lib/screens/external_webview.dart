import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) {
                setState(() => _isLoading = false);
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),

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



