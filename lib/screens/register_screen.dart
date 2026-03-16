import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sponsorController = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    final response = await AuthService.registerUser(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      sponsorUsername: _sponsorController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success'] == true ||
        response['message'] != null &&
            response['message'].contains('successful') ||
        response['message'].contains('Admin')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Wapis Login screen par le jao
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Registration failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.amber),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F001F), Color(0xFF2A004F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'JOIN VIP CLUB',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Glassmorphism Form
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                labelStyle: TextStyle(color: Colors.white54),
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: Colors.white54),
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Colors.white54),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _sponsorController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Sponsor Username',
                                labelStyle: TextStyle(color: Colors.white54),
                                prefixIcon: Icon(
                                  Icons.group_add,
                                  color: Colors.amber,
                                ),
                                helperText:
                                    'Leave empty ONLY if you are the first Admin.',
                                helperStyle: TextStyle(
                                  color: Colors.amberAccent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _register,
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.black,
                                      )
                                    : const Text(
                                        'CREATE EMPIRE',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
