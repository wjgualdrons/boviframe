import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1) Configuro el controller y las animaciones
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // 2) Arranco la animaciÃ³n
    _controller.forward();

    // 3) DespuÃ©s del primer frame, inicio la suscripciÃ³n y la navegaciÃ³n
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // Suscribirse al topic "noticias"
    try {
      await FirebaseMessaging.instance.subscribeToTopic("noticias");
    } catch (e) {
      debugPrint("Error al suscribirse al topic: $e");
    }

    // Espero unos segundos para mostrar el logo
    await Future.delayed(const Duration(seconds: 3));

    // Compruebo si hay un usuario logueado
    final user = FirebaseAuth.instance.currentUser;
    final nextRoute = user != null ? '/main_menu' : '/login';

    // Navego UNA SOLA VEZ
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(nextRoute);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/icons/logoapp3.png',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Iniciando BOVIFrame...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}



