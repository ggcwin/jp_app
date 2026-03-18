import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'dashboard_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Locked Accounts
  List<dynamic> _lockedUsers = [];
  String? _selectedUserId;
  bool _isLoading = true;
  bool _isUnblocking = false;

  // Draw Control
  final TextEditingController _drawNumberController = TextEditingController(
    text: "0000",
  );
  bool _isRigged = false;
  bool _isUpdatingDraw = false;

  // Ticket Stats
  List<Map<String, dynamic>> _soldNumbers = [];
  List<Map<String, dynamic>> _repeatingNumbers = [];
  List<String> _unsoldNumbers = [];

  // User Management
  List<dynamic> _allUsers = [];

  // Finance Approvals & Ledger
  List<dynamic> _pendingDeposits = [];
  List<dynamic> _pendingWithdrawals = [];
  List<dynamic> _globalHistory = [];

  // Risk Predictor Variables
  List<dynamic> _topRisks = [];
  double _totalPendingSales = 0;
  double? _customPayoutResult;
  final TextEditingController _customPredictorController =
      TextEditingController();

  // ✨ Vouchers System
  List<dynamic> _allVouchers = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchLockedUsers(),
      _fetchDrawSettings(),
      _fetchTicketStats(),
      _fetchAllUsers(),
      _fetchFinanceRequests(),
      _fetchRiskAnalysis(),
      _fetchVouchers(), // Fetching Vouchers
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  // ==========================================
  // 📥 API FETCH FUNCTIONS
  // ==========================================

  // ✨ Fetch Vouchers
  Future<void> _fetchVouchers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/voucher/admin/all'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() => _allVouchers = data['vouchers'] ?? []);
      }
    } catch (e) {}
  }

  Future<void> _fetchRiskAnalysis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/admin/risk-analysis'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _topRisks = data['top20'] ?? [];
          _totalPendingSales = (data['totalSales'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      print("Risk Fetch Error: $e");
    }
  }

  Future<void> _checkCustomNumber(
    String testNumber,
    StateSetter setModalState,
  ) async {
    if (testNumber.length != 4) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/admin/risk-analysis'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'testNumber': testNumber}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        double payout = (data['testNumberPayout'] ?? 0).toDouble();
        setModalState(() {
          _customPayoutResult = payout;
        });
      }
    } catch (e) {
      _showSnackBar("Error calculating custom number.", Colors.redAccent);
    }
  }

  Future<void> _fetchFinanceRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final depRes = await http.get(
        Uri.parse('${AppConstants.baseUrl}/wallet/admin/pending-deposits'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (depRes.statusCode == 200)
        setState(() => _pendingDeposits = jsonDecode(depRes.body));

      final withRes = await http.get(
        Uri.parse('${AppConstants.baseUrl}/withdraw/all'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (withRes.statusCode == 200) {
        List<dynamic> allRequests = jsonDecode(withRes.body);
        setState(
          () => _pendingWithdrawals = allRequests
              .where((r) => r['status'] == 'Pending')
              .toList(),
        );
      }

      final histRes = await http.get(
        Uri.parse('${AppConstants.baseUrl}/admin/ledger'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (histRes.statusCode == 200) {
        final data = jsonDecode(histRes.body);
        if (data['success'] == true)
          setState(() => _globalHistory = data['history'] ?? []);
      }
    } catch (e) {}
  }

  Future<void> _fetchLockedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/admin/locked-users'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (mounted && data['success'] == true) {
        setState(() {
          _lockedUsers = data['users'] ?? [];
          if (_lockedUsers.isNotEmpty) _selectedUserId = _lockedUsers[0]['_id'];
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchDrawSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/admin/draw-settings'),
        headers: {'Authorization': 'Bearer $token'},
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
    } catch (e) {}
  }

  Future<void> _fetchTicketStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/admin/ticket-stats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        List<dynamic> stats = data['stats'];
        List<Map<String, dynamic>> sold = [];
        List<Map<String, dynamic>> repeating = [];
        Set<String> soldSet = {};

        for (var s in stats) {
          sold.add({'number': s['number'], 'count': s['count']});
          soldSet.add(s['number'].toString());
          if (s['count'] > 1)
            repeating.add({'number': s['number'], 'count': s['count']});
        }
        List<String> unsold = [];
        for (int i = 0; i <= 9999; i++) {
          String numStr = i.toString().padLeft(4, '0');
          if (!soldSet.contains(numStr)) unsold.add(numStr);
        }
        if (mounted)
          setState(() {
            _soldNumbers = sold;
            _repeatingNumbers = repeating;
            _unsoldNumbers = unsold;
          });
      }
    } catch (e) {}
  }

  Future<void> _fetchAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/admin/users'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (mounted && data['success'] == true)
        setState(() => _allUsers = data['users']);
    } catch (e) {}
  }

  // ==========================================
  // ⚙️ ACTION FUNCTIONS
  // ==========================================

  Future<void> _approveDeposit(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/wallet/admin/approve-deposit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'transactionId': transactionId}),
      );
      final data = jsonDecode(response.body);
      _showSnackBar(
        data['message'],
        response.statusCode == 200 ? Colors.green : Colors.red,
      );
      if (response.statusCode == 200) _fetchFinanceRequests();
    } catch (e) {}
  }

  Future<void> _handleWithdrawAction(String requestId, String action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/withdraw/action'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'requestId': requestId, 'action': action}),
      );
      final data = jsonDecode(response.body);
      _showSnackBar(
        data['message'],
        response.statusCode == 200 ? Colors.green : Colors.red,
      );
      if (response.statusCode == 200) _fetchFinanceRequests();
    } catch (e) {}
  }

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
        _fetchLockedUsers();
      } else {
        _showSnackBar(data['message'] ?? 'Action Failed.', Colors.redAccent);
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isUnblocking = false);
    }
  }

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
    } finally {
      if (mounted) setState(() => _isUpdatingDraw = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // ========================================================
  // ⚠️ BOTTOM SHEETS
  // ========================================================

  // ✨ 1. VOUCHERS BOTTOM SHEET (The Missing Piece!)
  void _showCreateVoucherDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E003E),
        title: const Text(
          'Generate VIP Voucher 🎟️',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'Amount (Rs.)',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
            ),
            onPressed: () async {
              if (amountController.text.isEmpty) return;
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('auth_token');

              final response = await http.post(
                Uri.parse('${AppConstants.baseUrl}/voucher/create'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode({
                  'amount': amountController.text,
                  'walletType': 'admin_bypass',
                }),
              );

              final data = jsonDecode(response.body);
              if (data['success'] == true) {
                _showSnackBar(
                  'Voucher Generated: ${data['voucher']['code']}',
                  Colors.green,
                );
                Clipboard.setData(
                  ClipboardData(text: data['voucher']['code']),
                ); // Auto Copy
                _fetchVouchers(); // Refresh list
              }
            },
            child: const Text(
              'CREATE & COPY',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVoucherHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF1E003E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'MASTER VOUCHER RECORDS 🎟️',
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: _allVouchers.isEmpty
                    ? const Center(
                        child: Text(
                          'No vouchers found in database.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: _allVouchers.length,
                        itemBuilder: (context, index) {
                          final v = _allVouchers[index];
                          final isRedeemed = v['status'] == 'redeemed';

                          final creator = v['createdBy'] != null
                              ? v['createdBy']['username']
                              : 'Unknown';
                          final role = v['createdBy'] != null
                              ? v['createdBy']['role']
                              : 'user';
                          final redeemer = isRedeemed && v['redeemedBy'] != null
                              ? v['redeemedBy']['username']
                              : 'Not Redeemed';

                          DateTime createdDate = DateTime.parse(
                            v['createdAt'],
                          ).toLocal();
                          String dateStr =
                              "${createdDate.day}-${createdDate.month}-${createdDate.year}";
                          String timeStr =
                              "${createdDate.hour}:${createdDate.minute.toString().padLeft(2, '0')}";

                          return Card(
                            color: Colors.white.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: isRedeemed
                                    ? Colors.white12
                                    : Colors.purpleAccent.withOpacity(0.5),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        v['code'],
                                        style: TextStyle(
                                          color: isRedeemed
                                              ? Colors.white54
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      Text(
                                        'Rs. ${v['amount']}',
                                        style: TextStyle(
                                          color: isRedeemed
                                              ? Colors.white38
                                              : Colors.greenAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Date & Time:',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '$dateStr | $timeStr',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Created By:',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '$creator (${role.toUpperCase()})',
                                        style: TextStyle(
                                          color: role == 'admin'
                                              ? Colors.amberAccent
                                              : Colors.cyanAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Status:',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        isRedeemed ? 'REDEEMED' : 'ACTIVE',
                                        style: TextStyle(
                                          color: isRedeemed
                                              ? Colors.redAccent
                                              : Colors.greenAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isRedeemed) ...[
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Redeemed By:',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          redeemer,
                                          style: const TextStyle(
                                            color: Colors.orangeAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.purpleAccent,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 0,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.copy,
                                          color: Colors.purpleAccent,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'COPY CODE',
                                          style: TextStyle(
                                            color: Colors.purpleAccent,
                                            fontSize: 12,
                                          ),
                                        ),
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(text: v['code']),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Code Copied!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. Risk Predictor
  void _showRiskPredictorSheet() {
    _customPredictorController.clear();
    _customPayoutResult = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF1E003E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'PAYOUT PREDICTOR ⚠️',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 18,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Total Sold Amount',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Rs. ${_totalPendingSales.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              'Highest Risk Payout',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Rs. ${_topRisks.isNotEmpty ? _topRisks[0]['payout'] : 0}',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Custom Number Check:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customPredictorController,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  letterSpacing: 5,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  counterText: "",
                                  hintText: "e.g. 1234",
                                  hintStyle: const TextStyle(
                                    color: Colors.white38,
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.3),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val.length == 4) {
                                    _checkCustomNumber(val, setModalState);
                                  } else {
                                    setModalState(
                                      () => _customPayoutResult = null,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            Container(
                              height: 55,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.orangeAccent),
                              ),
                              child: Center(
                                child: Text(
                                  _customPayoutResult != null
                                      ? 'Rs. ${_customPayoutResult?.toStringAsFixed(0)}'
                                      : 'Payout',
                                  style: TextStyle(
                                    color: _customPayoutResult != null
                                        ? Colors.redAccent
                                        : Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Text(
                        'Top 20 High-Risk Numbers:',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: _topRisks.isEmpty
                        ? const Center(
                            child: Text(
                              'No active tickets found.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            itemCount: _topRisks.length,
                            itemBuilder: (context, index) {
                              final item = _topRisks[index];
                              return Card(
                                color: Colors.white.withOpacity(0.05),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.redAccent
                                        .withOpacity(0.2),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    'Draw Number: ${item['number']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  trailing: Text(
                                    'Loss: Rs. ${item['payout']}',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 3. Finance
  void _showFinanceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF1E003E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'FINANCE APPROVALS 💰',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const TabBar(
                      indicatorColor: Colors.greenAccent,
                      labelColor: Colors.greenAccent,
                      unselectedLabelColor: Colors.white54,
                      isScrollable: true,
                      tabs: [
                        Tab(text: "DEPOSITS"),
                        Tab(text: "WITHDRAWALS"),
                        Tab(text: "LEDGER / HISTORY"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _pendingDeposits.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No pending deposits.',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(15),
                                  itemCount: _pendingDeposits.length,
                                  itemBuilder: (context, index) {
                                    final req = _pendingDeposits[index];
                                    final username = req['userId'] != null
                                        ? req['userId']['username']
                                        : 'Unknown';
                                    return Card(
                                      color: Colors.white.withOpacity(0.05),
                                      child: ListTile(
                                        title: Text(
                                          'User: $username',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Amount: Rs. ${req['amount']}\n${req['details']}',
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                          ),
                                        ),
                                        trailing: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.greenAccent,
                                          ),
                                          child: const Text(
                                            'APPROVE',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _approveDeposit(req['_id']);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),

                          _pendingWithdrawals.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No pending withdrawals.',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(15),
                                  itemCount: _pendingWithdrawals.length,
                                  itemBuilder: (context, index) {
                                    final req = _pendingWithdrawals[index];
                                    final username = req['userId'] != null
                                        ? req['userId']['username']
                                        : 'Unknown';
                                    return Card(
                                      color: Colors.white.withOpacity(0.05),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'User: $username',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Req: Rs. ${req['amount']} | Fee: Rs. ${req['fee']}',
                                              style: const TextStyle(
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                            Text(
                                              'To Send: Rs. ${req['finalAmount']}',
                                              style: const TextStyle(
                                                color: Colors.greenAccent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Method: ${req['method']}',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                              ),
                                            ),
                                            Text(
                                              'Details: ${req['accountDetails']}',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _handleWithdrawAction(
                                                      req['_id'],
                                                      'Rejected',
                                                    );
                                                  },
                                                  child: const Text(
                                                    'REJECT',
                                                    style: TextStyle(
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.greenAccent,
                                                      ),
                                                  child: const Text(
                                                    'APPROVE',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _handleWithdrawAction(
                                                      req['_id'],
                                                      'Approved',
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                          _globalHistory.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No history available.',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(15),
                                  itemCount: _globalHistory.length,
                                  itemBuilder: (context, index) {
                                    final tx = _globalHistory[index];
                                    final username = tx['userId'] != null
                                        ? tx['userId']['username']
                                        : 'System';
                                    final type =
                                        tx['type']?.toString().toUpperCase() ??
                                        'N/A';
                                    final amount = tx['amount'] ?? 0;
                                    final status =
                                        tx['status']
                                            ?.toString()
                                            .toUpperCase() ??
                                        'COMPLETED';
                                    final details =
                                        tx['details'] ?? 'No details';

                                    Color statusColor = Colors.greenAccent;
                                    if (status == 'PENDING')
                                      statusColor = Colors.orangeAccent;
                                    if (status == 'REJECTED')
                                      statusColor = Colors.redAccent;

                                    return Card(
                                      color: Colors.white.withOpacity(0.05),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: statusColor
                                              .withOpacity(0.2),
                                          child: Icon(
                                            Icons.history,
                                            color: statusColor,
                                          ),
                                        ),
                                        title: Text(
                                          'User: $username',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 5),
                                            Text(
                                              '$type | Rs. $amount',
                                              style: const TextStyle(
                                                color: Colors.cyanAccent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              details,
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 4. Users
  void _showUserManagementSheet() {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final filteredUsers = _allUsers.where((u) {
              final un = u['username'].toString().toLowerCase();
              return un.contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Color(0xFF1E003E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'MANAGE USERS 👥',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by username...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.cyanAccent,
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setSheetState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final wallets = user['wallets'] ?? {};
                        final playBal = (wallets['deposit'] ?? 0).toDouble();
                        final winBal = (wallets['win'] ?? 0).toDouble();

                        return Card(
                          color: Colors.white.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(color: Colors.white12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.cyanAccent,
                              child: Icon(Icons.person, color: Colors.black),
                            ),
                            title: Text(
                              user['username'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Play: Rs. ${playBal.toStringAsFixed(0)} | Win: Rs. ${winBal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                              ),
                              color: const Color(0xFF2A004F),
                              onSelected: (value) {
                                if (value == 'login')
                                  _loginAsUser(user['_id'], user['username']);
                                else if (value == 'password')
                                  _showChangePasswordDialog(
                                    user['_id'],
                                    user['username'],
                                  );
                                else if (value == 'funds')
                                  _showManageFundsDialog(user, setSheetState);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'login',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.dashboard,
                                        color: Colors.greenAccent,
                                        size: 20,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'View Dashboard',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'password',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.vpn_key,
                                        color: Colors.amberAccent,
                                        size: 20,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Change Password',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'funds',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        color: Colors.pinkAccent,
                                        size: 20,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Manage Funds',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loginAsUser(String userId, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/admin/user/login-as'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        await prefs.setString('auth_token', data['token']);
        _showSnackBar(
          'Logged in as $username! Logout to return to Admin.',
          Colors.green,
        );
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        _showSnackBar(data['message'] ?? 'Failed to login', Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar('Network Error', Colors.redAccent);
    }
  }

  void _showChangePasswordDialog(String userId, String username) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E003E),
          title: Text(
            'Change Password for $username',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: TextField(
            controller: passwordController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter new password',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
              ),
              onPressed: () async {
                Navigator.pop(context);
                if (passwordController.text.isEmpty) return;
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('auth_token');
                final response = await http.post(
                  Uri.parse(
                    '${AppConstants.baseUrl}/admin/user/change-password',
                  ),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode({
                    'userId': userId,
                    'newPassword': passwordController.text,
                  }),
                );
                final data = jsonDecode(response.body);
                _showSnackBar(
                  data['message'],
                  data['success'] == true ? Colors.green : Colors.redAccent,
                );
              },
              child: const Text('SAVE', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  void _showManageFundsDialog(
    Map<String, dynamic> user,
    StateSetter setSheetState,
  ) {
    final amountController = TextEditingController();
    String selectedWallet = 'deposit';
    String selectedAction = 'add';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E003E),
              title: Text(
                'Manage Funds for ${user['username']}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedWallet,
                    dropdownColor: const Color(0xFF2A004F),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: 'deposit',
                        child: Text('Play Balance (Deposit)'),
                      ),
                      DropdownMenuItem(value: 'win', child: Text('Win Wallet')),
                      DropdownMenuItem(
                        value: 'bonus',
                        child: Text('Bonus Wallet'),
                      ),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => selectedWallet = val!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedAction,
                    dropdownColor: const Color(0xFF2A004F),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: 'add',
                        child: Text('ADD Funds 🟢'),
                      ),
                      DropdownMenuItem(
                        value: 'deduct',
                        child: Text('DEDUCT Funds 🔴'),
                      ),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => selectedAction = val!),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter amount (Rs.)',
                      hintStyle: TextStyle(color: Colors.white38),
                      prefixText: 'Rs. ',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedAction == 'add'
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (amountController.text.isEmpty) return;
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('auth_token');
                    final response = await http.post(
                      Uri.parse(
                        '${AppConstants.baseUrl}/admin/user/adjust-balance',
                      ),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode({
                        'userId': user['_id'],
                        'walletType': selectedWallet,
                        'amount': amountController.text,
                        'action': selectedAction,
                      }),
                    );
                    final data = jsonDecode(response.body);
                    _showSnackBar(
                      data['message'],
                      data['success'] == true ? Colors.green : Colors.redAccent,
                    );
                    if (data['success'] == true) {
                      _fetchAllUsers();
                      _fetchFinanceRequests();
                    }
                  },
                  child: const Text(
                    'CONFIRM',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 5. Stats
  void _showStatsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF1E003E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const SizedBox(height: 15),
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'MARKET OVERVIEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                const TabBar(
                  indicatorColor: Colors.cyanAccent,
                  labelColor: Colors.cyanAccent,
                  unselectedLabelColor: Colors.white54,
                  tabs: [
                    Tab(text: "SOLD"),
                    Tab(text: "UNSOLD"),
                    Tab(text: "REPEATING"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _soldNumbers.isEmpty
                          ? const Center(
                              child: Text(
                                'No tickets sold yet.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(15),
                              itemCount: _soldNumbers.length,
                              itemBuilder: (context, index) {
                                final item = _soldNumbers[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.receipt,
                                    color: Colors.greenAccent,
                                  ),
                                  title: Text(
                                    'Number: ${item['number']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  trailing: Text(
                                    'Sold: ${item['count']}x',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                      GridView.builder(
                        padding: const EdgeInsets.all(15),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: _unsoldNumbers.length,
                        itemBuilder: (context, index) {
                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              _unsoldNumbers[index],
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                      _repeatingNumbers.isEmpty
                          ? const Center(
                              child: Text(
                                'No repeating numbers yet.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(15),
                              itemCount: _repeatingNumbers.length,
                              itemBuilder: (context, index) {
                                final item = _repeatingNumbers[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.warning_amber,
                                    color: Colors.orangeAccent,
                                  ),
                                  title: Text(
                                    'Number: ${item['number']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Hot: ${item['count']}x',
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
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
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 🎨 UI BUILDER
  // ==========================================
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
                        // 1. RISK PREDICTOR
                        const Text(
                          'RISK MANAGEMENT ⚠️',
                          style: TextStyle(
                            color: Colors.orangeAccent,
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
                                  color: Colors.orangeAccent.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          const Text(
                                            'TOTAL SOLD',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            'Rs. ${_totalPendingSales.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text(
                                            'MAX PAYOUT',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            'Rs. ${_topRisks.isNotEmpty ? _topRisks[0]['payout'] : 0}',
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orangeAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.analytics,
                                        color: Colors.black,
                                      ),
                                      label: const Text(
                                        'OPEN PAYOUT PREDICTOR',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: _showRiskPredictorSheet,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 2. FINANCE APPROVALS
                        const Text(
                          'FINANCE & APPROVALS 💰',
                          style: TextStyle(
                            color: Colors.greenAccent,
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
                                  color: Colors.greenAccent.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          const Text(
                                            'PENDING DEPOSITS',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            '${_pendingDeposits.length}',
                                            style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text(
                                            'PENDING WITHDRAWS',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            '${_pendingWithdrawals.length}',
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.greenAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.account_balance,
                                        color: Colors.black,
                                      ),
                                      label: const Text(
                                        'MANAGE REQUESTS & LEDGER',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: _showFinanceBottomSheet,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ✨ 3. VOUCHER MANAGEMENT (ADDED BACK!)
                        const Text(
                          'VOUCHER MANAGEMENT 🎟️',
                          style: TextStyle(
                            color: Colors.purpleAccent,
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
                                  color: Colors.purpleAccent.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.card_giftcard,
                                    size: 60,
                                    color: Colors.purpleAccent,
                                  ),
                                  const SizedBox(height: 15),
                                  const Text(
                                    'GIFT VOUCHERS',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Generate free balance codes for giveaways & view redemption history.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.purpleAccent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.add,
                                            color: Colors.black,
                                          ),
                                          label: const Text(
                                            'CREATE',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onPressed: _showCreateVoucherDialog,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.purpleAccent,
                                              width: 2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.history,
                                            color: Colors.purpleAccent,
                                          ),
                                          label: const Text(
                                            'RECORDS',
                                            style: TextStyle(
                                              color: Colors.purpleAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onPressed: _showVoucherHistorySheet,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 4. USER MANAGEMENT
                        const Text(
                          'USER MANAGEMENT 👥',
                          style: TextStyle(
                            color: Colors.pinkAccent,
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
                                  color: Colors.pinkAccent.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.manage_accounts,
                                    size: 60,
                                    color: Colors.pinkAccent,
                                  ),
                                  const SizedBox(height: 15),
                                  const Text(
                                    'ALL PLAYERS',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Total Users Registered: ${_allUsers.length}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.pinkAccent,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.people,
                                        color: Colors.pinkAccent,
                                      ),
                                      label: const Text(
                                        'VIEW & MANAGE USERS',
                                        style: TextStyle(
                                          color: Colors.pinkAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: _showUserManagementSheet,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 5. LIVE TICKET STATS
                        const Text(
                          'LIVE TICKET STATS 📊',
                          style: TextStyle(
                            color: Colors.cyanAccent,
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
                                  color: Colors.cyanAccent.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        children: [
                                          const Text(
                                            'SOLD',
                                            style: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                          Text(
                                            '${_soldNumbers.length}',
                                            style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text(
                                            'UNSOLD',
                                            style: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                          Text(
                                            '${_unsoldNumbers.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text(
                                            'REPEATING',
                                            style: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                          Text(
                                            '${_repeatingNumbers.length}',
                                            style: const TextStyle(
                                              color: Colors.orangeAccent,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 25),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.cyanAccent,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.list_alt,
                                        color: Colors.cyanAccent,
                                      ),
                                      label: const Text(
                                        'VIEW DETAILED LISTS',
                                        style: TextStyle(
                                          color: Colors.cyanAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: _showStatsBottomSheet,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 6. SYSTEM OVERRIDE
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
                                  TextField(
                                    controller: _drawNumberController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 45,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.amberAccent,
                                      letterSpacing: 15,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      counterText: "",
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.3),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
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

                        // 7. SECURITY CONTROLS
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
