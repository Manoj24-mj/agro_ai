import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'country_selection_screen.dart';

class IntroAnimationScreen extends StatefulWidget {
  const IntroAnimationScreen({super.key});

  @override
  State<IntroAnimationScreen> createState() => _IntroAnimationScreenState();
}

class _IntroAnimationScreenState extends State<IntroAnimationScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _particleController;

  final List<Particle> _particles = List.generate(20, (index) => Particle());

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          for (var p in _particles) {
            p.update();
          }
        });
      })..repeat();

    Future.delayed(const Duration(seconds: 6), () async {
      final prefs = await SharedPreferences.getInstance();
      final isNewUser = prefs.getBool('is_new_user') ?? true;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 1200),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Futuristic Gradient Background
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5 + (_pulseController.value * 0.1),
                    colors: [
                      const Color(0xFF0F2027), // Deep dark green/black
                      const Color(0xFF203A43),
                      const Color(0xFF2C5364),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Animated Particles (Spores/Pollen)
          ..._particles.map((p) {
            return Positioned(
              left: p.x * MediaQuery.of(context).size.width,
              top: p.y * MediaQuery.of(context).size.height,
              child: Opacity(
                opacity: p.alpha,
                child: Container(
                  width: p.size,
                  height: p.size,
                  decoration: BoxDecoration(
                    color: Colors.lightGreenAccent.withOpacity(0.6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.lightGreenAccent, blurRadius: p.size * 2)
                    ],
                  ),
                ),
              ),
            );
          }),

          // 3. Central Glassmorphism Card with 3D loader
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: 340,
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: -5,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Organic 3D Leaf Loader
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: AnimatedBuilder(
                          animation: _rotateController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                _buildLeaf(0, Colors.greenAccent),
                                _buildLeaf(pi / 3, Colors.lightGreen),
                                _buildLeaf(2 * pi / 3, Colors.tealAccent),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Glitch-like or glowing text
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Text(
                            "Agro AI Doctor",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              shadows: [
                                BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.5 + (_pulseController.value * 0.5)),
                                  blurRadius: 20,
                                )
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Smart 3D Diagnostics & AI Insights",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 1.2,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaf(double offsetAngle, Color color) {
    final angle = (_rotateController.value * 2 * pi) + offsetAngle;
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // 3D Perspective
        ..rotateZ(angle)
        ..rotateX(sin(angle) * 0.5)
        ..rotateY(cos(angle) * 0.5),
      alignment: Alignment.center,
      child: Container(
        width: 80,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.6),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 15)
          ],
        ),
      ),
    );
  }
}

class Particle {
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double speedY = Random().nextDouble() * 0.002 + 0.001;
  double speedX = (Random().nextDouble() - 0.5) * 0.001;
  double size = Random().nextDouble() * 4 + 2;
  double alpha = Random().nextDouble() * 0.5 + 0.1;

  void update() {
    y -= speedY;
    x += speedX;
    if (y < 0) {
      y = 1.0;
      x = Random().nextDouble();
    }
  }
}
