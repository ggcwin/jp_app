import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // ✨ NAYA: URL Launcher Import
import '../constants.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _trxController = TextEditingController();

  File? _slipImage;
  bool _isLoading = false;
  String _selectedCryptoNetwork = 'TRC20';
  final ImagePicker _picker = ImagePicker();

  // ✨ LIVE SETTINGS VARIABLES
  Map<String, dynamic> _financialSettings = {};
  bool _isFetchingSettings = true;

  @override
  void initState() {
    super.initState();
    _fetchFinancialSettings();
  }

  // ✨ FETCH LIVE ADMIN SETTINGS
  Future<void> _fetchFinancialSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/settings/financial'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _financialSettings = data['settings'];
          _isFetchingSettings = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingSettings = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _slipImage = File(pickedFile.path));
    }
  }

  Future<void> _submitDepositRequest(String method) async {
    if (_amountController.text.isEmpty || _trxController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Amount and TRX ID!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_slipImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload the payment slip screenshot!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/wallet/deposit-request'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['amount'] = _amountController.text;
      request.fields['method'] = method == 'Crypto'
          ? 'Crypto ($_selectedCryptoNetwork)'
          : method;
      request.fields['trxId'] = _trxController.text;
      request.files.add(
        await http.MultipartFile.fromPath('slip', _slipImage!.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit Request Sent to Admin! ✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit request.'),
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied! 📋'),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }

  Widget _buildFormInput(String method) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Deposit Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Amount (e.g. 500)',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(
                Icons.attach_money,
                color: Colors.greenAccent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _trxController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Transaction ID / Reference No.',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.tag, color: Colors.cyanAccent),
            ),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: _slipImage == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          color: Colors.white54,
                          size: 40,
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Tap to upload Payment Slip screenshot',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_slipImage!, fit: BoxFit.cover),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isLoading
                  ? null
                  : () => _submitDepositRequest(method),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'SUBMIT DEPOSIT REQUEST',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentCryptoAddress = _selectedCryptoNetwork == 'TRC20'
        ? (_financialSettings['usdtTrc20'] ?? 'Loading...')
        : (_financialSettings['usdtBep20'] ?? 'Loading...');

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
          'TOP UP WALLET',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _isFetchingSettings
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Top-up Method',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 15),

                  // 1. Crypto (USDT)
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      collapsedBackgroundColor: const Color(0xFF0D2520),
                      backgroundColor: const Color(0xFF0D2520),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: Colors.greenAccent),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: Colors.greenAccent),
                      ),
                      leading: const Icon(
                        Icons.currency_bitcoin,
                        color: Colors.greenAccent,
                      ),
                      title: const Text(
                        'Crypto (USDT)',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedCryptoNetwork = 'TRC20',
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _selectedCryptoNetwork == 'TRC20'
                                              ? Colors.greenAccent
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.greenAccent,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'TRC20',
                                            style: TextStyle(
                                              color:
                                                  _selectedCryptoNetwork ==
                                                      'TRC20'
                                                  ? Colors.black
                                                  : Colors.greenAccent,
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
                                      onTap: () => setState(
                                        () => _selectedCryptoNetwork = 'BEP20',
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _selectedCryptoNetwork == 'BEP20'
                                              ? Colors.greenAccent
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.greenAccent,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'BEP20',
                                            style: TextStyle(
                                              color:
                                                  _selectedCryptoNetwork ==
                                                      'BEP20'
                                                  ? Colors.black
                                                  : Colors.greenAccent,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        currentCryptoAddress,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _copyToClipboard(
                                        currentCryptoAddress,
                                      ),
                                      child: const Icon(
                                        Icons.copy,
                                        color: Colors.greenAccent,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(color: Colors.white24, height: 30),
                              _buildFormInput('Crypto'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 2. Local Bank Transfer
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      collapsedBackgroundColor: const Color(0xFF1E003E),
                      backgroundColor: const Color(0xFF1E003E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: Colors.white12),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: Colors.white12),
                      ),
                      leading: const Icon(
                        Icons.account_balance,
                        color: Colors.pinkAccent,
                      ),
                      title: const Text(
                        'Local Bank Transfer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bank Name: ${_financialSettings['bankName'] ?? 'Loading...'}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                'Account Title: ${_financialSettings['bankTitle'] ?? 'Loading...'}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Account No: ${_financialSettings['bankAccount'] ?? 'Loading...'}',
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.copy,
                                      color: Colors.cyanAccent,
                                    ),
                                    onPressed: () => _copyToClipboard(
                                      _financialSettings['bankAccount'] ?? '',
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white24, height: 30),
                              _buildFormInput('Bank Transfer'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ✨ NAYA: Help Button (Telegram Link Logic)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.support_agent,
                          color: Colors.cyanAccent,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Need Help?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.telegram, color: Colors.white),
                          label: const Text(
                            'CONTACT SUPPORT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            final String telegramUrl =
                                _financialSettings['telegramLink'] ??
                                'https://t.me/';
                            final Uri url = Uri.parse(telegramUrl);
                            if (!await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            )) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open Telegram'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
