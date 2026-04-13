import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _navigateToLogin();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 4), () {});
    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      
      if (token != null && token.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF005293);
    const accentBlue = Color(0xFF00A3FF);

    return Scaffold(
      body: Stack(
        children: [
          // Modern Abstract Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF0F7FF)],
                ),
              ),
            ),
          ),
          
          // Animated Abstract Circles
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                   _buildAbstractCircle(
                    top: -100 + (20 * math.sin(_controller.value * 2 * math.pi)),
                    right: -50,
                    size: 300,
                    color: primaryBlue.withOpacity(0.05),
                  ),
                  _buildAbstractCircle(
                    bottom: -150 + (30 * math.cos(_controller.value * 2 * math.pi)),
                    left: -100,
                    size: 400,
                    color: accentBlue.withOpacity(0.03),
                  ),
                ],
              );
            },
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with subtle zoom-in animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo/Cleane.png',
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                
                // Minimal loading
                LoadingAnimationWidget.staggeredDotsWave(
                  color: primaryBlue,
                  size: 50,
                ),
              ],
            ),
          ),
          
          // Footer branding or version
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "خدمة غسيل احترافية من باب بيتك لباب بيتك",
                style: TextStyle(
                  letterSpacing: 1,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryBlue.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbstractCircle({double? top, double? bottom, double? left, double? right, required double size, required Color color}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
