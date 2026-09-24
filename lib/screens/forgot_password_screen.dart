import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();

  void _showAlert(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.check_circle_outline, color: color),
            label: Text('Cerrar', style: TextStyle(color: color)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _resetPassword(BuildContext context) async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showAlert(
        context,
        icon: Icons.info_outline,
        color: Colors.orange,
        title: 'Campo vacÃ­o',
        message: 'Por favor ingresa tu correo electrÃ³nico.',
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showAlert(
        context,
        icon: Icons.mark_email_read_rounded,
        color: Colors.green,
        title: 'Correo enviado',
        message:
            'Te hemos enviado un enlace para restablecer tu contraseÃ±a. Revisa tu bandeja de entrada o spam.',
      );
      Future.delayed(const Duration(seconds: 2), () => Navigator.pop(context));
    } on FirebaseAuthException catch (e) {
      String message = 'Ha ocurrido un error al intentar recuperar tu cuenta.';
      if (e.code == 'user-not-found') {
        message = 'Este usuario no estÃ¡ registrado.';
      } else if (e.code == 'invalid-email') {
        message = 'El correo electrÃ³nico no tiene un formato vÃ¡lido.';
      } else if (e.code == 'operation-not-allowed') {
        message =
            'La recuperaciÃ³n por correo no estÃ¡ habilitada en Firebase Authentication.';
      } else if (e.code == 'too-many-requests') {
        message =
            'Se realizaron demasiados intentos. Espera unos minutos y vuelve a intentarlo.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }
      _showAlert(
        context,
        icon: Icons.error_outline,
        color: Colors.red,
        title: 'Error',
        message: message,
      );
    } catch (_) {
      _showAlert(
        context,
        icon: Icons.error_outline,
        color: Colors.red,
        title: 'Error inesperado',
        message: 'OcurriÃ³ un error inesperado al procesar tu solicitud.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text('Recuperar ContraseÃ±a', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_reset_rounded, size: 60, color: Colors.blueAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Â¿Olvidaste tu contraseÃ±a?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingresa tu correo para recibir el enlace de recuperaciÃ³n:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo electrÃ³nico',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _resetPassword(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Enviar enlace de recuperaciÃ³n',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


