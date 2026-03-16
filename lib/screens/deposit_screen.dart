import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/wallet_service.dart'; // ✨ Service Import
import 'dashboard_screen.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final bool _isBankTransferEnabledByAdmin = true;

  String _expandedMethod = 'Voucher';
  String _usdtNetwork = 'TRC20';

  final _voucherController = TextEditingController();
  final _itunesController = TextEditingController();
  bool _isLoading = false;

  final String _trc20Address = "TXYZ...DummyAddress...TRC20...9876";
  final String _bep20Address = "0xABC...DummyAddress...BEP20...1234";

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address Copied to Clipboard! 📋'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ✨ Asal Redeem Logic
  void _handleRedeemVoucher() async {
    final code = _voucherController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    final response = await WalletService.redeemVoucher(code: code);
    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message'] ?? 'Action completed!'),
        backgroundColor: response['success'] == true
            ? Colors.green
            : Colors.redAccent,
      ),
    );

    if (response['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildUSDTLogo() {
    return Container(
      width: 35,
      height: 35,
      decoration: const BoxDecoration(
        color: Color(0xFF26A17B),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '₮',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required String title,
    required Widget icon,
    required Color glowColor,
    required Widget content,
  }) {
    bool isExpanded = _expandedMethod == title;

    return GestureDetector(
      onTap: () => setState(() => _expandedMethod = isExpanded ? '' : title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: isExpanded
              ? glowColor.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded ? glowColor.withOpacity(0.8) : Colors.white12,
            width: isExpanded ? 2 : 1,
          ),
          boxShadow: isExpanded
              ? [BoxShadow(color: glowColor.withOpacity(0.2), blurRadius: 20)]
              : [],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: 15),
                  Text(
                    title,
                    style: TextStyle(
                      color: isExpanded ? glowColor : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isExpanded ? glowColor : Colors.white54,
                  ),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: content,
              ),
          ],
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.amberAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DEPOSIT FUNDS',
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Top-up Method',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  _buildMethodCard(
                    title: 'Redeem Voucher',
                    icon: const Icon(
                      Icons.card_giftcard,
                      color: Colors.amberAccent,
                      size: 35,
                    ),
                    glowColor: Colors.amberAccent,
                    content: Column(
                      children: [
                        TextField(
                          controller: _voucherController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter 16-digit Voucher Code',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amberAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : _handleRedeemVoucher, // ✨ Fixed Logic
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.black,
                                  )
                                : const Text(
                                    'REDEEM NOW',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildMethodCard(
                    title: 'Crypto (USDT)',
                    icon: _buildUSDTLogo(),
                    glowColor: const Color(0xFF26A17B),
                    content: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _usdtNetwork = 'TRC20'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _usdtNetwork == 'TRC20'
                                        ? const Color(0xFF26A17B)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF26A17B),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'TRC20',
                                      style: TextStyle(
                                        color: _usdtNetwork == 'TRC20'
                                            ? Colors.white
                                            : const Color(0xFF26A17B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _usdtNetwork = 'BEP20'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _usdtNetwork == 'BEP20'
                                        ? const Color(0xFF26A17B)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF26A17B),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'BEP20',
                                      style: TextStyle(
                                        color: _usdtNetwork == 'BEP20'
                                            ? Colors.white
                                            : const Color(0xFF26A17B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: QrImageView(
                            data: _usdtNetwork == 'TRC20'
                                ? _trc20Address
                                : _bep20Address,
                            version: QrVersions.auto,
                            size: 150.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _usdtNetwork == 'TRC20'
                                      ? _trc20Address
                                      : _bep20Address,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  color: Color(0xFF26A17B),
                                ),
                                onPressed: () => _copyToClipboard(
                                  _usdtNetwork == 'TRC20'
                                      ? _trc20Address
                                      : _bep20Address,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildMethodCard(
                    title: 'iTunes Card Redeem',
                    icon: const Icon(
                      Icons.apple,
                      color: Colors.blueAccent,
                      size: 35,
                    ),
                    glowColor: Colors.blueAccent,
                    content: Column(
                      children: [
                        TextField(
                          controller: _itunesController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter iTunes Code',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: null,
                            child: const Text(
                              'SUBMIT FOR VERIFICATION',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_isBankTransferEnabledByAdmin)
                    _buildMethodCard(
                      title: 'Local Bank Transfer',
                      icon: const Icon(
                        Icons.account_balance,
                        color: Colors.purpleAccent,
                        size: 35,
                      ),
                      glowColor: Colors.purpleAccent,
                      content: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bank Name: Standard Chartered',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Account Title: Jackpot GGC',
                              style: TextStyle(color: Colors.white70),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'IBAN: AE12 3456 7890 1234 5678',
                              style: TextStyle(
                                color: Colors.purpleAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.1),
                          Colors.lightBlueAccent.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.lightBlueAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.support_agent,
                          color: Colors.lightBlueAccent,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Need Help?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.telegram, size: 28),
                            label: const Text(
                              'CONTACT SUPPORT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0088cc),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
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
