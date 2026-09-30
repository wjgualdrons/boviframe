import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'package:boviframe/screens/providers/auth_provider.dart' as my_auth;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDataIntoProvider(String uid) async {
    try {
      final doc =
          await LocalFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          final settingsProv = Provider.of<SettingsProvider>(
            context,
            listen: false,
          );
          settingsProv.setUserData(
            name: (data['name'] ?? '').toString(),
            email: (data['email'] ?? '').toString(),
            company: (data['company'] ?? '').toString(),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _loginWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      if (FirebaseAuth.instance.currentUser == null) {
        _showAlert(
          icon: Icons.error_outline,
          color: Colors.red,
          title: 'Error de autenticación',
          message: 'No se pudo autenticar con Google. Inténtalo de nuevo.',
        );
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main_menu');
    } catch (e) {
      _showAlert(
        icon: Icons.error_outline,
        color: Colors.red,
        title: 'Error con Google',
        message: 'No se pudo iniciar sesión: $e',
      );
    }
  }

  Future<void> _loginWithFacebook() async {
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(FacebookAuthProvider());
      } else {
        final result = await FacebookAuth.instance.login();
        if (result.status != LoginStatus.success ||
            result.accessToken == null) {
          _showAlert(
            icon: Icons.warning,
            color: Colors.orange,
            title: 'Inicio cancelado',
            message: 'Inicio de sesión con Facebook cancelado.',
          );
          return;
        }
        final credential = FacebookAuthProvider.credential(
          result.accessToken!.tokenString,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      if (FirebaseAuth.instance.currentUser == null) {
        _showAlert(
          icon: Icons.error_outline,
          color: Colors.red,
          title: 'Error de autenticación',
          message: 'Facebook no devolvió una sesión válida.',
        );
        return;
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main_menu');
    } catch (e) {
      _showAlert(
        icon: Icons.error_outline,
        color: Colors.red,
        title: 'Error con Facebook',
        message: 'No se pudo iniciar sesión: $e',
      );
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showAlert(
        icon: Icons.info_outline,
        color: Colors.orange,
        title: 'Campos vacíos',
        message: 'Por favor ingresa tu usuario/email y contraseña.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<my_auth.AuthProvider>(
        context,
        listen: false,
      );
      final errorMessage = await authProvider.login(email, password);

      if (errorMessage != null) {
        setState(() => _isLoading = false);
        _showAlert(
          icon: Icons.error_outline,
          color: Colors.red,
          title: 'Error de inicio',
          message: errorMessage,
        );
        return;
      }

      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        await _loadUserDataIntoProvider(firebaseUser.uid);
        if (!mounted) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/main_menu');
        });
      }
    } catch (e) {
      _showAlert(
        icon: Icons.error_outline,
        color: Colors.red,
        title: 'Error inesperado',
        message: 'No pudimos completar el inicio de sesión. Detalle: $e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAlert({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF192A20),
                    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/img/Fondo_inicio.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3E5C23), Color(0xFF1E320D)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                );
              },
            ),
          ),

          // Main Center Content Scrollable
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.55),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          const Text(
                            "Iniciar Sesión",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtitle
                          Text(
                            "Bienvenido de nuevo, por favor ingresa a tu cuenta",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // USER NAME FIELD
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nombre de usuario',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14.5,
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.2),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 18,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.55),
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 1.8,
                                ),
                              ),
                              suffixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white.withOpacity(0.85),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // PASSWORD FIELD
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Contraseña',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14.5,
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.2),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 18,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.55),
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 1.8,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.white.withOpacity(0.85),
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // REMEMBER ME CHECKBOX & FORGOT PASSWORD
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _rememberMe
                                            ? Colors.white.withOpacity(0.4)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.8),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _rememberMe
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Recordarme",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.95),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/forgot_password',
                                ),
                                child: Text(
                                  "¿Olvidaste tu contraseña?",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12.5,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // LOGIN BUTTON
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF628929),
                                  Color(0xFF385E14),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.55),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      "Iniciar Sesión",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // SIGNUP LINK
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/register',
                              ),
                              child: RichText(
                                text: TextSpan(
                                  text: "¿No tienes una cuenta? ",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13.5,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: "Regístrate",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // SOCIAL LOGIN DIVIDER & BUTTONS
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.4),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  "o ingresar con",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.4),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _loginWithGoogle,
                                  icon: Image.asset(
                                    'assets/img/google.png',
                                    height: 18,
                                  ),
                                  label: const Text(
                                    'Google',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    backgroundColor: Colors.black.withOpacity(0.15),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _loginWithFacebook,
                                  icon: Image.asset(
                                    'assets/img/facebook.png',
                                    height: 18,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.facebook,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  label: const Text(
                                    'Facebook',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    backgroundColor: Colors.black.withOpacity(0.15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
