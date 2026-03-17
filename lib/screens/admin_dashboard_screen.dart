import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Locked Accounts Variables
  List<dynamic> _lockedUsers = [];
  String? _selectedUserId;
  bool _isLoading = true;
  bool _isUnblocking = false;

  // Draw Control Variables
  final TextEditingController _drawNumberController = TextEditingController(
    text: "0000",
  );
  bool _isRigged = false;
  bool _isUpdatingDraw = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Ek sath dono APIs call karne ke liye
  Future<void> _initializeData() async {
    await Future.wait([_fetchLockedUsers(), _fetchDrawSettings()]);
    if (mounted) setState(() => _isLoading = false);
  }

  // 🔒 Backend se locked users mangwana
  Future<void> _fetchLockedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/admin/locked-users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (mounted && data['success'] == true) {
        setState(() {
          _lockedUsers = data['users'] ?? [];
          if (_lockedUsers.isNotEmpty) {
            _selectedUserId = _lockedUsers[0]['_id'];
          } else {
            _selectedUserId = null;
          }
        });
      }
    } catch (e) {
      _showSnackBar('Network Error: Could not fetch users.', Colors.redAccent);
    }
  }

  // 🎰 Backend se Draw Settings mangwana
  Future<void> _fetchDrawSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/admin/draw-settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (mounted && data['success'] == true) {
        setState(() {
          _isRigged = data['settings']['isRigged'] ?? false;
          List nextWinners = data['settings']['nextWinners'] ?? ['0000'];
          _drawNumberController.text = nextWinners.isNotEmpty
              ? nextWinners[0]
              : '0000';
        });
      }
    } catch (e) {
      _showSnackBar(
        'Network Error: Could not fetch draw settings.',
        Colors.amber,
      );
    }
  }

  // 🔓 Specific user ko unblock karna
  Future<void> _unblockUser() async {
    if (_selectedUserId == null) return;

    setState(() => _isUnblocking = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/admin/unblock'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': _selectedUserId}),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        _showSnackBar(data['message'] ?? 'User Unblocked!', Colors.green);
        _fetchLockedUsers(); // Refresh
      } else {
        _showSnackBar(data['message'] ?? 'Action Failed.', Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar('Network Error: Could not unblock.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isUnblocking = false);
    }
  }

  // 🛠️ Admin Draw Settings Save Karna
  Future<void> _updateDrawSettings() async {
    final number = _drawNumberController.text.trim();
    if (number.length != 4) {
      _showSnackBar('Please enter exactly 4 digits!', Colors.redAccent);
      return;
    }

    setState(() => _isUpdatingDraw = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/admin/draw-settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'nextWinningNumber': number, 'isRigged': _isRigged}),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        _showSnackBar(data['message'] ?? 'Settings Updated!', Colors.green);
      } else {
        _showSnackBar(data['message'] ?? 'Failed to update!', Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar(
        'Network Error: Could not update settings.',
        Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _isUpdatingDraw = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
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
          'VIP ADMIN PANEL',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
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

          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.amberAccent),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // ==========================================
                        // 🎰 1. DRAW CONTROL (RIGGED SETTINGS)
                        // ==========================================
                        const Text(
                          'SYSTEM OVERRIDE 🎰',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 15),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.amberAccent.withOpacity(0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amberAccent.withOpacity(0.1),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.casino,
                                    size: 60,
                                    color: Colors.amberAccent,
                                  ),
                                  const SizedBox(height: 15),
                                  const Text(
                                    'DRAW CONTROL',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Set the 4-digit winning number for the next draw.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // ✨ 4-Digit Number Input
                                  TextField(
                                    controller: _drawNumberController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 45,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.amberAccent,
                                      letterSpacing:
                                          15, // Digits ke beech space
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      counterText: "", // Hide 0/4 counter
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.3),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // ✨ Rigged Switch
                                  SwitchListTile(
                                    title: const Text(
                                      'Enable Rigged System',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Force slot machine to pick this exact number.',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                    activeColor: Colors.amberAccent,
                                    contentPadding: EdgeInsets.zero,
                                    value: _isRigged,
                                    onChanged: (val) {
                                      setState(() {
                                        _isRigged = val;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 15),

                                  // 💾 UPDATE BUTTON
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amberAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.save,
                                        color: Colors.black,
                                        size: 28,
                                      ),
                                      label: _isUpdatingDraw
                                          ? const CircularProgressIndicator(
                                              color: Colors.black,
                                            )
                                          : const Text(
                                              'UPDATE SETTINGS',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                      onPressed: _isUpdatingDraw
                                          ? null
                                          : _updateDrawSettings,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ==========================================
                        // 🔒 2. SECURITY CONTROLS (LOCKED ACCOUNTS)
                        // ==========================================
                        const Text(
                          'SECURITY CONTROLS 🛡️',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 15),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.redAccent.withOpacity(0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.lock_person,
                                    size: 60,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(height: 15),
                                  const Text(
                                    'LOCKED ACCOUNTS',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _lockedUsers.isEmpty
                                        ? 'All user accounts are safe and active.'
                                        : '${_lockedUsers.length} account(s) locked due to multiple failed attempts.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  if (_lockedUsers.isNotEmpty) ...[
                                    // ✨ DROPDOWN MENU
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          dropdownColor: const Color(
                                            0xFF1E003E,
                                          ),
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.amberAccent,
                                          ),
                                          value: _selectedUserId,
                                          items: _lockedUsers.map((user) {
                                            return DropdownMenuItem<String>(
                                              value: user['_id'],
                                              child: Text(
                                                '${user['username']} (Attempts: ${user['failedLoginAttempts']})',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (newValue) {
                                            setState(() {
                                              _selectedUserId = newValue;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 25),

                                    // 🔓 UNBLOCK BUTTON
                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.greenAccent
                                              .withOpacity(0.9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.lock_open,
                                          color: Colors.black,
                                          size: 28,
                                        ),
                                        label: _isUnblocking
                                            ? const CircularProgressIndicator(
                                                color: Colors.black,
                                              )
                                            : const Text(
                                                'AUTHORIZE UNBLOCK',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.black,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                        onPressed: _isUnblocking
                                            ? null
                                            : _unblockUser,
                                      ),
                                    ),
                                  ] else ...[
                                    // State when no users are locked
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Colors.greenAccent.withOpacity(
                                            0.5,
                                          ),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.greenAccent,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'No Actions Required',
                                            style: TextStyle(
                                              color: Colors.greenAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
