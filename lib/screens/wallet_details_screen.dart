import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'deposit_screen.dart';
import 'withdraw_screen.dart';
import 'transfer_screen.dart'; // Nayi file

class WalletDetailsScreen extends StatefulWidget {
  final String walletType; // 'deposit', 'win', 'bonus'
  final String title;
  final double balance;
  final String username;
  final String userId;
  final Color themeColor;

  const WalletDetailsScreen({
    super.key,
    required this.walletType,
    required this.title,
    required this.balance,
    required this.username,
    required this.userId,
    required this.themeColor,
  });

  @override
  State<WalletDetailsScreen> createState() => _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends State<WalletDetailsScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Global Ledger History Fetch Kar Rahe Hain
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/wallet/history/${widget.username}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> allHistory = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _transactions = allHistory;
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

  @override
  Widget build(BuildContext context) {
    // Agar Deposit wallet hai toh Deposit Button, warna Withdraw Button
    bool isDepositWallet = widget.walletType == 'deposit';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0014),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: widget.themeColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 💰 BALANCE CARD
            Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: widget.themeColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.themeColor.withOpacity(0.1),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'AVAILABLE BALANCE',
                          style: TextStyle(
                            color: Colors.white70,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Rs. ${widget.balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: widget.themeColor,
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // ✨ ACTION BUTTONS
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  backgroundColor: isDepositWallet
                                      ? Colors.greenAccent
                                      : Colors.pinkAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                icon: Icon(
                                  isDepositWallet
                                      ? Icons.add_circle
                                      : Icons.account_balance,
                                  color: Colors.black,
                                ),
                                label: Text(
                                  isDepositWallet ? 'DEPOSIT' : 'WITHDRAW',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => isDepositWallet
                                          ? const DepositScreen()
                                          : const WithdrawScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  backgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(
                                      color: widget.themeColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.swap_horiz,
                                  color: widget.themeColor,
                                ),
                                label: Text(
                                  'TRANSFER',
                                  style: TextStyle(
                                    color: widget.themeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TransferScreen(
                                        senderId: widget.userId,
                                        defaultWallet: widget.walletType,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 📜 TRANSACTION HISTORY
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TRANSACTION HISTORY',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: widget.themeColor,
                      ),
                    )
                  : _transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No history found.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final tx = _transactions[index];
                        final isPositive = (tx['netAmount'] ?? 0) > 0;
                        final amount = (tx['amount'] ?? 0).toDouble();

                        return Card(
                          color: Colors.white.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPositive
                                  ? Colors.greenAccent.withOpacity(0.2)
                                  : Colors.redAccent.withOpacity(0.2),
                              child: Icon(
                                isPositive
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isPositive
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                            ),
                            title: Text(
                              tx['type']?.toString().toUpperCase() ??
                                  'TRANSACTION',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              tx['details'] ?? 'No details',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            trailing: Text(
                              '${isPositive ? '+' : '-'} Rs. ${amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: isPositive
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
