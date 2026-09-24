import 'package:flutter/material.dart';

AppBar buildCustomAppBar(BuildContext context, String title) {
  return AppBar(
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
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    ),
  );
}



