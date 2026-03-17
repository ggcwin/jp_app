import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import 'play_screen.dart';
import 'my_tickets_screen.dart';
import 'deposit_screen.dart';
import 'withdraw_screen.dart';
import 'create_voucher_screen.dart';
import 'profile_screen.dart'; // ✨ NAYA IMPORT: Profile Screen ke liye

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _fetchData();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _fetchData() async {
    final data = await AuthService.getUserData();
    if (mounted) {
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Widget _buildGlowOrb(Color color, double size, double top, double left) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.5),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildGlassWallet(
    String title,
    String amount,
    Color neonColor,
    IconData icon,
    VoidCallback? onTap, // ✨ Tap logic added
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(color: neonColor.withOpacity(0.1), blurRadius: 20),
                ],
              ),
              child: Column(
                children: [
                  Icon(icon, color: neonColor, size: 28),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      amount,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: neonColor, blurRadius: 15)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0014),
        body: Center(
          child: CircularProgressIndicator(color: Colors.amberAccent),
        ),
      );
    }

    final user = _userData?['user'];
    final username = user?['username']?.toString().toUpperCase() ?? 'BOSS';

    final playBalance = (user?['wallets']?['deposit'] ?? 0.0).toDouble();
    final winBalance = (user?['wallets']?['win'] ?? 0.0).toDouble();
    final bonusBalance = (user?['wallets']?['bonus'] ?? 0.0).toDouble();

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0014),
      body: Stack(
        children: [
          _buildGlowOrb(Colors.amberAccent, 250, 100, -50),
          _buildGlowOrb(Colors.purpleAccent, 300, 400, 150),
          _buildGlowOrb(Colors.cyanAccent, 200, -50, 250),
          _buildGlowOrb(Colors.pinkAccent, 250, 600, -100),

          Positioned.fill(
            child: Opacity(
              opacity: 0.7,
              child: Lottie.network(
                'https://assets9.lottiefiles.com/packages/lf20_XyZOuB.json',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // ✨ PROFILE SCREEN NAVIGATION
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Colors.amberAccent, Colors.orange],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amberAccent.withOpacity(0.5),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: const CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.black87,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.amberAccent,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'VIP Member',
                                style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                width: screenWidth * 0.45,
                                child: FittedBox(
                                  alignment: Alignment.centerLeft,
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Welcome, $username',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.receipt_long,
                              color: Colors.amberAccent,
                              size: 28,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyTicketsScreen(),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_active,
                              color: Colors.amberAccent,
                              size: 28,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),

                  Center(
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(35),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 35,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(35),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amberAccent.withOpacity(0.15),
                                    blurRadius: 50 + _glowAnimation.value,
                                    spreadRadius: _glowAnimation.value,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.amberAccent.withOpacity(
                                        0.1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amberAccent.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 30,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.monetization_on,
                                      size: 60,
                                      color: Colors.amberAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'TOTAL WINNINGS 🏆',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      letterSpacing: 2,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      // ✨ PKR Formatting applied here
                                      'Rs. ${winBalance.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 55,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.amberAccent,
                                            blurRadius: 20,
                                          ),
                                          Shadow(
                                            color: Colors.orangeAccent,
                                            blurRadius: 40,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 35),

                  const Text(
                    'YOUR VAULTS',
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ✨ PKR Formatting applied in all wallets below
                      _buildGlassWallet(
                        'PLAY BALANCE',
                        'Rs. ${playBalance.toStringAsFixed(2)}',
                        Colors.greenAccent,
                        Icons.account_balance_wallet,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DepositScreen(),
                          ),
                        ),
                      ),
                      _buildGlassWallet(
                        'WIN WALLET',
                        'Rs. ${winBalance.toStringAsFixed(2)}',
                        Colors.pinkAccent,
                        Icons.emoji_events,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WithdrawScreen(),
                          ),
                        ),
                      ),
                      _buildGlassWallet(
                        'BONUS',
                        'Rs. ${bonusBalance.toStringAsFixed(2)}',
                        Colors.cyanAccent,
                        Icons.card_giftcard,
                        null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 45),

                  SizedBox(
                    width: double.infinity,
                    height: 65,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.amberAccent, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amberAccent.withOpacity(0.6),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.black,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlayScreen(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.casino, size: 28),
                            const SizedBox(width: 10),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: const Text(
                                  'PLAY JACKPOT NOW',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ✨ P2P Voucher Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.cyanAccent.withOpacity(0.5),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateVoucherScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.card_giftcard,
                        color: Colors.cyanAccent,
                      ),
                      label: const Text(
                        'CREATE P2P VOUCHER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                          letterSpacing: 1,
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
