import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/wallet_service.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  String _selectedMethod = 'Crypto (USDT)';
  String _selectedWallet = 'win';

  Map<String, dynamic>? _wallets;
  bool _isFetchingWallets = true;

  double _feeAmount = 0.0;
  double _payableAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchWallets();
    _amountController.addListener(() {
      final val = double.tryParse(_amountController.text) ?? 0.0;
      setState(() {
        _feeAmount = val * 0.10; // 10% Fee
        _payableAmount = val - _feeAmount;
      });
    });
  }

  void _fetchWallets() async {
    final data = await AuthService.getUserData();
    if (mounted) {
      setState(() {
        if (data['success'] == true) _wallets = data['user']['wallets'];
        _isFetchingWallets = false;
      });
    }
  }

  void _handleWithdraw() async {
    // ✨ FIX: Rs. replace kiya gaya hai
    final amountText = _amountController.text.replaceAll('Rs.', '').trim();
    final amount = double.tryParse(amountText);
    final address = _addressController.text.trim();

    // ✨ FIX: Minimum limit Rs. 500 kar di gayi hai
    if (amount == null || amount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum withdrawal is Rs. 500'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter destination address'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await WalletService.withdrawFunds(
      amount: amount,
      method: _selectedMethod,
      walletType: _selectedWallet,
      details: address,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Withdrawal Requested!'),
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
          content: Text(response['message'] ?? 'Failed!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildWalletSelector(
    String type,
    String title,
    Color color,
    IconData icon,
  ) {
    bool isSelected = _selectedWallet == type;
    double balance = (_wallets?[type] ?? 0.0).toDouble();

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedWallet = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? color : Colors.white12,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 5),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // ✨ FIX: Rs. Symbol
              Text(
                'Rs. ${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0014),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.pinkAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'WITHDRAW FUNDS',
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Wallet:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _isFetchingWallets
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.pinkAccent,
                      ),
                    )
                  : Row(
                      children: [
                        _buildWalletSelector(
                          'win',
                          'WIN WALLET',
                          Colors.pinkAccent,
                          Icons.emoji_events,
                        ),
                        const SizedBox(width: 10),
                        _buildWalletSelector(
                          'deposit',
                          'PLAY BALANCE',
                          Colors.greenAccent,
                          Icons.account_balance_wallet,
                        ),
                      ],
                    ),
              const SizedBox(height: 30),

              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'AMOUNT TO WITHDRAW',
                          style: TextStyle(
                            color: Colors.pinkAccent,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 45, // Thora chota kiya fit karne ke liye
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: TextStyle(color: Colors.white24),
                            // ✨ FIX: Prefix ab Rs. hai
                            prefixText: 'Rs. ',
                            prefixStyle: TextStyle(
                              fontSize: 35,
                              color: Colors.pinkAccent,
                            ),
                          ),
                        ),
                        const Divider(color: Colors.white24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tx Fee (10%):',
                              style: TextStyle(color: Colors.white54),
                            ),
                            // ✨ FIX: Rs. Symbol
                            Text(
                              'Rs. ${_feeAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'You Receive:',
                              style: TextStyle(color: Colors.white),
                            ),
                            // ✨ FIX: Rs. Symbol
                            Text(
                              'Rs. ${_payableAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                'Destination Details:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter Account Title / Bank Name / IBAN',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.pinkAccent,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleWithdraw,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'REQUEST WITHDRAWAL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
