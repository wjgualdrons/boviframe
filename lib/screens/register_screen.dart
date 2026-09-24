import 'package:flutter/material.dart';
import 'package:boviframe/services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  final List<String> _professions = [
    'Veterinario',
    'Zootecnista',
    'AgrÃ³nomo',
    'Otro',
  ];
  String? _selectedProfession;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nombreCtrl.dispose();
    _ubicacionCtrl.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Correo enviado',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale:
              CurvedAnimation(
                parent: animation,
                curve: Curves.elasticOut,
              ).value,
          child: Opacity(
            opacity: animation.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: const [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 30,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Â¡Correo enviado!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Te enviamos un enlace de verificaciÃ³n a tu correo. Haz clic en Ã©l para activar tu cuenta. Si no lo ves, revisa tambiÃ©n tu carpeta de spam o correo no deseado.',
              ),
              actions: [
                TextButton.icon(
                  icon: Icon(Icons.login, color: Colors.blue),
                  label: Text(
                    'Ir a login',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onRegisterPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.registerWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      nombre: _nombreCtrl.text.trim(),
      profesion: _selectedProfession!,
      ubicacion: _ubicacionCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.user != null) {
      await result.user!.sendEmailVerification();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Â¡Registro exitoso! Revisa tu correo para verificar tu cuenta.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _showSuccessDialog();

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.mark_email_read_rounded, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(child: Text('Â¡Correo enviado!')),
                ],
              ),
              content: const Text(
                'Te enviamos un enlace de verificaciÃ³n a tu correo electrÃ³nico. Haz clic en Ã©l para activar tu cuenta.',
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.login, color: Colors.blue),
                  label: const Text(
                    'Ir a login',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/login');
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                const LoginScreen(),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.ease;

                          final tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
      );
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? 'Error desconocido';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEDF6FF), // celeste clarito
              Color(0xFFFFFFFF),
            ],
          ),
        ),

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Card(
                elevation: 10,
                shadowColor: Colors.blue.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 80,
                          color: Colors.blueAccent,
                        ),
                        Text(
                          'Crea tu cuenta',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1), // Azul mÃ¡s fuerte
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ãšnete a Boviframe en segundos',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: _inputDecoration(
                            'Email',
                            Icons.email_outlined,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Ingresa un email';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                              return 'Email invÃ¡lido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordCtrl,
                          decoration: _inputDecoration(
                            'ContraseÃ±a',
                            Icons.lock_outline,
                          ),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Ingresa una contraseÃ±a';
                            if (v.length < 6) return 'MÃ­nimo 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmCtrl,
                          decoration: _inputDecoration(
                            'Confirmar contraseÃ±a',
                            Icons.lock,
                          ),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Confirma tu contraseÃ±a';
                            if (v != _passwordCtrl.text)
                              return 'Las contraseÃ±as no coinciden';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nombreCtrl,
                          decoration: _inputDecoration(
                            'Nombre y apellido',
                            Icons.person_outline,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Ingresa tu nombre'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedProfession,
                          decoration: _inputDecoration(
                            'ProfesiÃ³n',
                            Icons.work_outline,
                          ),
                          isExpanded: true,
                          hint: const Text('Selecciona una profesiÃ³n'),

                          items:
                              _professions.map((String prof) {
                                return DropdownMenuItem<String>(
                                  value: prof,
                                  child: Text(prof),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedProfession = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor selecciona una profesiÃ³n';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ubicacionCtrl,
                          decoration: _inputDecoration(
                            'UbicaciÃ³n (ciudad, paÃ­s)',
                            Icons.location_on_outlined,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Ingresa tu ubicaciÃ³n'
                                      : null,
                        ),
                        const SizedBox(height: 24),

                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                        ],

                        AnimatedScale(
                          scale: _isLoading ? 0.95 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _onRegisterPressed,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.blue[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
                                        'Registrarme',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Â¿Ya tienes cuenta? Inicia sesiÃ³n'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      labelStyle: const TextStyle(
        color: Colors.blueGrey,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      hintStyle: TextStyle(color: Colors.grey.shade400),
    );
  }
}



