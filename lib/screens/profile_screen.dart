import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'my_network_screen.dart'; // ✨ NAYA IMPORT

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // ✨ Backend se User ki details laa rahe hain
  void _fetchUserData() async {
    final data = await AuthService.getUserData();
    if (mounted) {
      setState(() {
        if (data['success'] == true) {
          _userData = data['user'];
        }
        _isLoading = false;
      });
    }
  }

  // 🚪 LOGOUT LOGIC
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // Token ko delete kar diya

    if (!mounted) return;

    // User ko wapas Login Screen par bhej do aur pichli saari screens band kar do
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.amberAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'VIP PROFILE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 🌌 Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F001F), Color(0xFF2A004F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.amberAccent),
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // 👑 Profile Avatar
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.amberAccent.withOpacity(0.5),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amberAccent.withOpacity(0.2),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.black45,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // User Details
                        Text(
                          _userData?['username']?.toString().toUpperCase() ??
                              'VIP USER',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _userData?['email'] ?? 'No Email Provided',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 👑 ADMIN PANEL BUTTON (Sirf Admin ko dikhega)
                        if (_userData?['role'] == 'admin') ...[
                          ListTile(
                            leading: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.redAccent,
                              size: 30,
                            ),
                            title: const Text(
                              'Admin Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text(
                              'Manage locked accounts & system',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white54,
                              size: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            tileColor: Colors.redAccent.withOpacity(0.1),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminDashboardScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 15),
                        ],

                        // ✨ NAYA BUTTON: MY NETWORK
                        ListTile(
                          leading: const Icon(
                            Icons.group_add,
                            color: Colors.cyanAccent,
                            size: 30,
                          ),
                          title: const Text(
                            'My Network & Affiliate',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'View Team & 5% Commissions',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white54,
                            size: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          tileColor: Colors.white.withOpacity(0.05),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyNetworkScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 15),

                        // ✏️ Update Profile Menu Item
                        ListTile(
                          leading: const Icon(
                            Icons.manage_accounts,
                            color: Colors.cyanAccent,
                            size: 30,
                          ),
                          title: const Text(
                            'Update Profile Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'Change email, etc.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white54,
                            size: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          tileColor: Colors.white.withOpacity(0.05),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Profile Update Feature Coming Soon!',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 15),

                        // 🔐 Change Security Key Menu Item
                        ListTile(
                          leading: const Icon(
                            Icons.security,
                            color: Colors.amberAccent,
                            size: 30,
                          ),
                          title: const Text(
                            'Change Security Key',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white54,
                            size: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          tileColor: Colors.white.withOpacity(0.05),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Use Forgot Password on Login Screen to reset!',
                                ),
                                backgroundColor: Colors.blueAccent,
                              ),
                            );
                          },
                        ),

                        const Spacer(),

                        // 🚪 LOGOUT BUTTON (At the Bottom)
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withOpacity(
                                0.9,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 10,
                              shadowColor: Colors.redAccent.withOpacity(0.5),
                            ),
                            icon: const Icon(
                              Icons.power_settings_new,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'SECURE LOGOUT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            onPressed: _logout,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
