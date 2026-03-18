import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class MyNetworkScreen extends StatefulWidget {
  const MyNetworkScreen({super.key});

  @override
  State<MyNetworkScreen> createState() => _MyNetworkScreenState();
}

class _MyNetworkScreenState extends State<MyNetworkScreen> {
  bool _isLoading = true;
  String _inviteCode = '';
  int _totalReferrals = 0;
  double _totalEarnings = 0.0;
  List<dynamic> _referralsList = [];

  @override
  void initState() {
    super.initState();
    _fetchNetworkStats();
  }

  Future<void> _fetchNetworkStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/network/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        if (mounted) {
          setState(() {
            _inviteCode = data['inviteCode'] ?? '';
            _totalReferrals = data['totalReferrals'] ?? 0;
            _totalEarnings = (data['totalEarnings'] ?? 0).toDouble();
            _referralsList = data['referrals'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _copyInviteCode() {
    Clipboard.setData(ClipboardData(text: _inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite Code Copied! 📋'),
        backgroundColor: Colors.greenAccent,
        behavior: SnackBarBehavior.floating,
      ),
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MY NETWORK 👥',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
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
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 💳 INVITE CODE CARD
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.cyanAccent.withOpacity(0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.1),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'YOUR VIP INVITE CODE',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.cyanAccent,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _inviteCode,
                                          style: const TextStyle(
                                            color: Colors.cyanAccent,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 4,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.copy,
                                            color: Colors.white,
                                          ),
                                          onPressed: _copyInviteCode,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  const Text(
                                    'Share this code with your friends and earn 5% commission every time they WIN a jackpot! 💸',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // 📊 STATS ROW
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'TOTAL TEAM',
                                '$_totalReferrals',
                                Colors.pinkAccent,
                                Icons.group,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildStatCard(
                                'TEAM EARNINGS',
                                'Rs. ${_totalEarnings.toStringAsFixed(0)}',
                                Colors.amberAccent,
                                Icons.account_balance_wallet,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          'MY REFERRALS (LEVEL 1)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // 📝 REFERRALS LIST
                        _referralsList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 30),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.group_off,
                                        size: 80,
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      const SizedBox(height: 15),
                                      const Text(
                                        "You haven't invited anyone yet.\nStart building your team!",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _referralsList.length,
                                itemBuilder: (context, index) {
                                  final ref = _referralsList[index];
                                  final joinDate = DateTime.parse(
                                    ref['createdAt'],
                                  ).toString().split(' ')[0];

                                  return Card(
                                    color: Colors.white.withOpacity(0.05),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.cyanAccent,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.black,
                                        ),
                                      ),
                                      title: Text(
                                        ref['username']
                                            .toString()
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Joined: $joinDate',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: const Text(
                                        'ACTIVE 🟢',
                                        style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: color, blurRadius: 10)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
