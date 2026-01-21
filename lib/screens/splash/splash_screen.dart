import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _fadeIn;
  late Animation<double> _textSlide;
  late Animation<Color?> _backgroundColor;
  late Animation<double> _progressValue;

  double _progress = 0.0;
  Timer? _progressTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startProgress();
    _goNext();
  }

  void _initAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), // ⬇️ Diperpendek dari 3000ms
    );

    // ⚡ SIMPLIFY ANIMATIONS
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack, // ⚡ Lebih smooth
      ),
    );

    _logoRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut), // ⚡ Diperpendek
      ),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Curves.easeIn), // ⚡ Lebih cepat
      ),
    );

    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOut), // ⚡ Diperpendek
      ),
    );

    _backgroundColor = ColorTween(
      begin: const Color(0xFF0A2F1D),
      end: const Color(0xFF1B5E3C),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.linear),
      ),
    );

    _controller.forward();
  }

  void _startProgress() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) { // ⚡ 40ms bukan 50ms
      if (_disposed || !mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress += 0.015; // ⚡ Lebih cepat
        if (_progress >= 1.0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(milliseconds: 3000)); // ⬇️ 3500ms -> 3000ms
    
    if (_disposed || !mounted) return;

    // ⚡ HAPUS CEK INTERNET YANG TIDAK PERLU
    final user = FirebaseAuth.instance.currentUser;
    
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        user != null ? AppRoutes.home : AppRoutes.login,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _backgroundColor.value ?? const Color(0xFF0A2F1D),
                  _backgroundColor.value?.withOpacity(0.9) ?? const Color(0xFF1B5E3C),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ⚡ OPTIMIZED LOGO
                  Transform.rotate(
                    angle: 0,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 140, // ⬇️ 160 -> 140
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2), // ⬇️ 0.3 -> 0.2
                              blurRadius: 15, // ⬇️ 20 -> 15
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/Merbabu.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.terrain,
                                size: 60, // ⬇️ 70 -> 60
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30), // ⬇️ 40 -> 30

                  // ⚡ TITLE - SIMPLIFY
                  FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.3),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'MERBABU',
                            style: TextStyle(
                              fontSize: 42, // ⬇️ 48 -> 42
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 3, // ⬇️ 4 -> 3
                            ),
                          ),
                          const SizedBox(height: 4), // ⬇️ 8 -> 4
                          Text(
                            'ACCESS',
                            style: TextStyle(
                              fontSize: 22, // ⬇️ 24 -> 22
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 6, // ⬇️ 8 -> 6
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12), // ⬇️ 16 -> 12

                  // ⚡ SUBTITLE
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Pendakian Digital Taman Nasional Gunung Merbabu',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13, // ⬇️ 14 -> 13
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40), // ⬇️ 50 -> 40

                  // ⚡ LOADING INDICATOR - SIMPLIFY
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                width: 200 * _progressValue.value,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.9),
                                      Colors.white.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8), // ⬇️ 10 -> 8
                        FadeTransition(
                          opacity: _fadeIn,
                          child: Text(
                            '${(_progressValue.value * 100).toInt()}%',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16), // ⬇️ 20 -> 16

                  // ⚡ LOADING TEXT - SIMPLIFY
                  FadeTransition(
                    opacity: _fadeIn,
                    child: Text(
                      _getLoadingText(_progressValue.value),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ⚡ HELPER METHOD UNTUK LOADING TEXT
  String _getLoadingText(double progress) {
    if (progress < 0.25) return 'Menyiapkan aplikasi...';
    if (progress < 0.5) return 'Memuat data pendakian...';
    if (progress < 0.75) return 'Menyiapkan peta...';
    return 'Siap untuk petualangan!';
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }
}

class _MountainPainter extends CustomPainter {
  final Animation<double> animation;

  _MountainPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // ⚡ OPTIMASI: Gunakan warna konstan, tidak perlu rebuild tiap frame
    final paint = Paint()
      ..color = const Color(0x0DFFFFFF) // ⚡ Hex: 0D = 5% opacity (0x0DFFFFFF)
      ..style = PaintingStyle.fill;

    // ⚡ OPTIMASI: Pre-calculate values untuk menghindari perhitungan berulang
    final width = size.width;
    final height = size.height;
    final animValue = animation.value;
    
    // ⚡ OPTIMASI: Gunakan path yang lebih sederhana
    final path = Path();
    
    // Mountain 1 - Simplified
    path.moveTo(0, height);
    path.lineTo(width * 0.2, height * 0.6 * animValue);
    path.lineTo(width * 0.4, height * 0.8);
    path.close(); // ⚡ Tidak perlu line kembali ke awal
    
    // Mountain 2 - Simplified  
    path.moveTo(width * 0.3, height);
    path.lineTo(width * 0.5, height * 0.5 * animValue);
    path.lineTo(width * 0.7, height);
    path.close();
    
    // Mountain 3 - Simplified
    path.moveTo(width * 0.6, height);
    path.lineTo(width * 0.8, height * 0.7 * animValue);
    path.lineTo(width, height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // ⚡ OPTIMASI: Cek jika animation berubah
    if (oldDelegate is _MountainPainter) {
      return oldDelegate.animation.value != animation.value;
    }
    return true;
  }
}