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
      if (doc.exists) {
        final data = doc.data()!;
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
    } catch (_) {}
  }

  Future<void> _loginWithGoogle() async {
    try {
      late final UserCredential userCredential;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
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
        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }
      final user = userCredential.user;

      if (user == null) {
        _showAlert(
          icon: Icons.error_outline,
          color: Colors.red,
          title: 'Error de autenticaciÃ³n',
          message: 'No se pudo autenticar con Google. IntÃ©ntalo de nuevo.',
        );
        return;
      }

      final String email = user.email ?? '';

      // ðŸ” Ahora que ya estÃ¡ autenticado, puedes consultar Firestore sin error
      final query =
          await LocalFirestore.instance
              .collection('usuarios')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
      print('Email buscado: $email');
      print('Documentos encontrados: ${query.docs.length}');

      if (query.docs.isEmpty) {
        // Crear nuevo usuario en Firestore si no existe
        await LocalFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set({
              'name': user.displayName ?? '',
              'email': user.email,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      // âœ… Cargar datos del usuario al Provider
      await _loadUserDataIntoProvider(user.uid);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/main_menu');
      });
    } catch (e) {
      _showAlert(
        icon: Icons.error_outline,
        color: Colors.red,
        title: 'Error con Google',
        message: 'No se pudo iniciar sesiÃ³n: $e',
      );
    }
  }

  Future<void> _loginWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success && result.accessToken != null) {
        final userData = await FacebookAuth.instance.getUserData();
        final email = userData['email'];

        if (email == null || email.isEmpty) {
          _showAlert(
            icon: Icons.warning,
            color: Colors.orange,
            title: 'Correo no disponible',
            message:
                'No pudimos acceder al correo de tu cuenta de Facebook. Por favor, asegÃºrate de que tu cuenta tiene un correo vÃ¡lido o usa otro mÃ©todo para iniciar sesiÃ³n.',
          );
          return;
        }

        // ðŸ” Verificar en Firestore si ese correo ya estÃ¡ registrado
        final query =
            await LocalFirestore.instance
                .collection('usuarios')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

        if (query.docs.isEmpty) {
          _showAlert(
            icon: Icons.lock_outline,
            color: Colors.orange,
            title: 'Acceso restringido',
            message:
                'Este correo no estÃ¡ registrado. Por favor regÃ­strate primero antes de usar Facebook.',
          );
          return;
        }

        // âœ… Autenticarse con Firebase usando el token de Facebook
        final credential = FacebookAuthProvider.credential(
          result.accessToken!.tokenString,
        );
        final userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );

        final user = userCredential.user;

        if (user != null) {
          await _loadUserDataIntoProvider(user.uid);
          if (!mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/main_menu');
          });
        }
      } else {
        _showAlert(
          icon: Icons.warning,
          color: Colors.orange,
          title: 'Inicio cancelado',
          message: 'Inicio de sesiÃ³n con Facebook cancelado.',
        );
      }
    } catch (e) {
      _showAlert(
        icon: Icons.error_outline,
        color: Colors.red,
        title: 'Error con Facebook',
        message: 'No se pudo iniciar sesiÃ³n: $e',
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
        title: 'Campos vacÃ­os',
        message: 'Por favor ingresa tu email y contraseÃ±a.',
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
        await firebaseUser.reload();
        if (!firebaseUser.emailVerified) {
          await FirebaseAuth.instance.signOut();
          setState(() => _isLoading = false);
          _showAlert(
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            title: 'VerificaciÃ³n pendiente',
            message:
                'Tu cuenta aÃºn no ha sido verificada. Revisa tu correo y verifica tu email antes de iniciar sesiÃ³n.',
          );
          return;
        }

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
        message: 'No pudimos completar el inicio de sesiÃ³n. Detalle: $e',
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/icons/fondo6.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 80),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 115),
                SizedBox(
                  width: 250,
                  child: Image.asset('assets/icons/logoapp3.png'),
                ),
                const SizedBox(height: 25),

                // EMAIL
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.blue,
                    ),
                    labelText: 'Correo electrÃ³nico',
                    labelStyle: const TextStyle(color: Colors.blueGrey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    hintText: 'ejemplo@correo.com',
                    hintStyle: const TextStyle(color: Colors.grey),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),

                const SizedBox(height: 16),

                // CONTRASEÃ‘A
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.blue,
                    ),
                    labelText: 'ContraseÃ±a',
                    labelStyle: const TextStyle(color: Colors.blueGrey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    hintText: 'MÃ­nimo 6 caracteres',
                    hintStyle: const TextStyle(color: Colors.grey),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),

                const SizedBox(height: 10),

                // ENLACES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed:
                          () => Navigator.pushNamed(context, '/register'),
                      child: const Text(
                        'Registrarse',
                        style: TextStyle(
                          color: Colors.blue, // CAMBIO: azul fuerte
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          () =>
                              Navigator.pushNamed(context, '/forgot_password'),
                      child: const Text(
                        'Â¿Olvidaste tu contraseÃ±a?',
                        style: TextStyle(
                          color: Colors.blue, // CAMBIO: azul fuerte
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // BOTÃ“N INICIAR SESIÃ“N
                ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Iniciar SesiÃ³n',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 30),
                const Text(
                  'O inicia sesiÃ³n con',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // BOTÃ“N GOOGLE
                ElevatedButton.icon(
                  onPressed: _loginWithGoogle,
                  icon: Image.asset('assets/img/google.png', height: 24),
                  label: const Text('Iniciar SesiÃ³n con Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // BOTÃ“N FACEBOOK
                ElevatedButton.icon(
                  onPressed: _loginWithFacebook,
                  icon: Image.asset('assets/img/facebook.png', height: 24),
                  label: const Text('Iniciar SesiÃ³n con Facebook'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.grey),
                    ),
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


