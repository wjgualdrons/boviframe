import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _bgExpandAnimation;
  late final Animation<double> _cardScaleAnimation;
  late final Animation<double> _cardFadeAnimation;
  late final Animation<double> _titleScaleAnimation;
  late final Animation<double> _titleSlideAnimation;
  late final Animation<double> _titleFadeAnimation;
  late final Animation<double> _loadingFadeAnimation;
  late final Animation<double> _progressAnimation;
  late final Animation<double> _footerFadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1) Controller para la secuencia de animacion (2.4 segundos)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // 2) Definicion de curvas escalonadas (Lottie-style timeline)
    _bgExpandAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeInOutCubic),
    );

    _cardScaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _cardFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.4, curve: Curves.easeIn),
    );

    _titleScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _titleSlideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _titleFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.6, curve: Curves.easeIn),
    );

    _loadingFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.8, curve: Curves.easeIn),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.92, curve: Curves.easeInOutCubic),
    );

    _footerFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    );

    // 3) Iniciar animacion
    _controller.forward();

    // 4) Iniciar servicios y navegacion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic("noticias");
    } catch (e) {
      debugPrint("Error al suscribirse al topic: $e");
    }

    // Esperar a que la animacion complete (2.8s)
    await Future.delayed(const Duration(milliseconds: 2800));

    final user = FirebaseAuth.instance.currentUser;
    final nextRoute = user != null ? '/main_menu' : '/login';

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
      backgroundColor: const Color(0xFFF3F7F4),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Expanding background organic rings (Shape Layer 1)
              CustomPaint(
                size: Size.infinite,
                painter: _SplashBackgroundPainter(_bgExpandAnimation.value),
              ),

              // Main Scene Content
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // Center Animated Card with Logo (Shape Layer 2 & Icon)
                    FadeTransition(
                      opacity: _cardFadeAnimation,
                      child: ScaleTransition(
                        scale: _cardScaleAnimation,
                        child: Container(
                          width: 124,
                          height: 124,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF235C3F).withOpacity(0.14),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/icons/logoapp3.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // App Title & Subtitle with Spring Scale & Slide
                    FadeTransition(
                      opacity: _titleFadeAnimation,
                      child: Transform.translate(
                        offset: Offset(0, _titleSlideAnimation.value),
                        child: ScaleTransition(
                          scale: _titleScaleAnimation,
                          child: Column(
                            children: const [
                              Text(
                                "BOVIFrame Zootecnia",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF192A20),
                                  letterSpacing: 0.6,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Plataforma Integral de Evaluación Fenotípica",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Loading Indicator & Custom Progress Bar (Layer 2 & 10)
                    FadeTransition(
                      opacity: _loadingFadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            "Iniciando BOVIFrame...",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Sleek Progress Bar
                          Container(
                            width: 160,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2EFE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 160 * _progressAnimation.value,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF235C3F),
                                      Color(0xFF4ADE80),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Copyright & Footer Text (Layer 4)
                    FadeTransition(
                      opacity: _footerFadeAnimation,
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          "© 2026 BOVIFrame Zootecnia • Todos los derechos reservados",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  final double progress;
  _SplashBackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height * 0.38);
    final maxRadius = size.height * 0.9;

    // Outer soft ring
    final outerPaint = Paint()
      ..color = const Color(0xFF235C3F).withOpacity(0.05 * progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * progress, outerPaint);

    // Inner brand ring
    final innerPaint = Paint()
      ..color = const Color(0xFFC3EAD5).withOpacity(0.25 * progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * 0.42 * progress, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _SplashBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}




