import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const JackpotApp());
}

class JackpotApp extends StatelessWidget {
  const JackpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jackpot', // ✨ Naam change ho gaya
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(
          0xFF1E003E,
        ), // Deep Purple Background
        primaryColor: const Color(0xFFFFB300), // Gold/Orange Color
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E003E)),
      ),
      home: const SplashScreen(),
    );
  }
}
