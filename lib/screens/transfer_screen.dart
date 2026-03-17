import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'dashboard_screen.dart';

class TransferScreen extends StatefulWidget {
  final String senderId;
  final String defaultWallet;

  const TransferScreen({
    super.key,
    required this.senderId,
    required this.defaultWallet,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _usernameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  late String _selectedWallet;

  @override
  void initState() {
    super.initState();
    _selectedWallet = widget.defaultWallet;
  }

  Future<void> _handleTransfer() async {
    final receiverUsername = _usernameController.text.trim();
    final amountText = _amountController.text.replaceAll('Rs.', '').trim();
    final amount = double.tryParse(amountText);

    if (receiverUsername.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid username and amount.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/transfer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'senderId': widget.senderId,
          'receiverUsername': receiverUsername,
          'amount': amount,
          'walletType': _selectedWallet,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Transfer Success!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Transfer Failed!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network Error!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0014),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'P2P TRANSFER',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transfer from Wallet:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedWallet,
                dropdownColor: const Color(0xFF1E003E),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.cyanAccent,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'deposit',
                    child: Text('Play Balance'),
                  ),
                  DropdownMenuItem(value: 'win', child: Text('Win Wallet')),
                  DropdownMenuItem(value: 'bonus', child: Text('Bonus Wallet')),
                ],
                onChanged: (val) => setState(() => _selectedWallet = val!),
              ),
              const SizedBox(height: 30),

              const Text(
                'Receiver Details:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter Receiver Username',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.person,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Amount to Transfer:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  prefixText: 'Rs. ',
                  prefixStyle: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '⚠️ Note: 3% fee will be charged on all transfers.',
                style: TextStyle(color: Colors.redAccent, fontSize: 11),
              ),

              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.send, color: Colors.black),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'SEND SECURELY',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.5,
                          ),
                        ),
                  onPressed: _isLoading ? null : _handleTransfer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
