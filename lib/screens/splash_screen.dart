import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // ✨ PULSING ANIMATION SETUP (Tagline ke liye)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    // 3 seconds ka wait taake user animation dekh sakay
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Token check kar rahe hain
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      // Agar token hai toh direct Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      // Warna Login Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ✨ EXACT SCREENSHOT WALA DICE ICON
  Widget _buildCustomDice() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.amber, width: 8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Align(alignment: const Alignment(-0.6, -0.6), child: _buildDot()),
          Align(alignment: const Alignment(0.6, -0.6), child: _buildDot()),
          Align(alignment: Alignment.center, child: _buildDot()),
          Align(alignment: const Alignment(-0.6, 0.6), child: _buildDot()),
          Align(alignment: const Alignment(0.6, 0.6), child: _buildDot()),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Colors.amber,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF130024,
      ), // Screenshot wala Dark Purple Background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCustomDice(),
            const SizedBox(height: 30),

            const Text(
              'Jackpot',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 15),

            // ✨ ANIMATED TAGLINE YAHAN HAI
            ScaleTransition(
              scale: _pulseAnimation,
              child: const Text(
                '💰 Play - Win - Earn 💰',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 60),

            const CircularProgressIndicator(
              color: Colors.amber,
              strokeWidth: 4,
            ),
          ],
        ),
      ),
    );
  }
}
