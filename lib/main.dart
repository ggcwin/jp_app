import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
// (Aap ke baqi imports aisay hi rahenge)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✨ Check for existing login token
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final bool isLoggedIn = token != null && token.isNotEmpty;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jackpot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      // ✨ Agar login hai toh seedha Dashboard, warna Login Screen
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
