import 'package:flutter/material.dart';
import 'custom_bottom_nav_bar.dart';

class CustomAppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final bool showBackButton;

  const CustomAppScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 4,
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading:
            showBackButton
                ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
                : null, // No muestra nada si no se indica
      ),

      body: body,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
      ), // <- aquÃ­ tambiÃ©n
    );
  }
}



