import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_opname_app/services/api_service.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _initialized = false;

  // --- Animation Controllers ---
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _dotsController;

  // --- Logo Animations ---
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // --- App Name Animations ---
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;

  // --- Tagline Animation ---
  late Animation<double> _taglineOpacity;

  // --- Loading Dots Animation ---
  late Animation<double> _dotsAnimation;
  
  String _statusText = 'Memuat aplikasi...';

  @override
  void initState() {
    super.initState();
    _initApp();



    // Logo: scale from 0.4 to 1.0 + fade in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Text: slide up + fade in (starts after logo)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _titleOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // Dots: repeating pulse
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _dotsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_dotsController);

    _initialized = true;

    // Sequence: logo → text → navigate
    _runAnimationSequence();
  }

      Future<void> _initApp() async {
      setState(() => _statusText = "Menyiapkan koneksi....");

      await Future.wait([
        APIService().warmUpServer(),
        Future.delayed(const Duration(seconds: 2)),
      ]);

      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }

  Future<void> _runAnimationSequence() async {
    // 1. Logo enters
    await _logoController.forward();

    // 2. Text slides up (slight delay after logo)
    await Future.delayed(const Duration(milliseconds: 100));
    await _textController.forward();

    // 3. Wait, then navigate
    await Future.delayed(const Duration(milliseconds: 1500));
    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            auth.isAuthenticated ? const MainScreen() : const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    if (_initialized) {
      _logoController.dispose();
      _textController.dispose();
      _dotsController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(backgroundColor: Color(0xFF0D47A1));
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D47A1), // Deep Cobalt Blue
              Color(0xFF1565C0), // Navy Blue
              Color(0xFF1976D2), // Mid Blue
              Color(0xFF0A2F6B), // Dark Navy
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              top: -80,
              right: -60,
              child: _buildDecorativeCircle(
                220,
                Colors.white.withOpacity(0.05),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _buildDecorativeCircle(
                280,
                Colors.white.withOpacity(0.04),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: -40,
              child: _buildDecorativeCircle(
                140,
                Colors.white.withOpacity(0.04),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // --- Logo ---
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, __) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 40,
                                spreadRadius: 0,
                                offset: const Offset(0, 16),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 0,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/logo_BAg.jpg',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- App Title + Tagline ---
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleOpacity,
                      child: Column(
                        children: [
                          const Text(
                            'Stock Opname',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'KAPAL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _taglineOpacity,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: const Text(
                                'Inventarisasi Cepat & Akurat',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // --- Animated Loading Dots & Status Text ---
                  FadeTransition(
                    opacity: _titleOpacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AnimatedDots(animation: _dotsAnimation),
                        const SizedBox(height: 16),
                        Text(
                          _statusText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// Animated three-dot loading indicator
class _AnimatedDots extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedDots({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            // Stagger each dot by 0.25
            final delay = index * 0.25;
            final t = ((animation.value - delay) % 1.0).clamp(0.0, 1.0);
            // Sine-based pulse: 0 → 1 → 0
            final pulse = (t < 0.5 ? t * 2 : (1.0 - t) * 2);
            final size = 6.0 + pulse * 4.0;
            final opacity = 0.4 + pulse * 0.6;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
