import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class WalletService {
  // --- 💸 WITHDRAW FUNDS (10% Fee Logic) ---
  static Future<Map<String, dynamic>> withdrawFunds({
    required double amount,
    required String method,
    required String walletType,
    required String details,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.post(
        Uri.parse(
          '${AppConstants.baseUrl}/withdraw/request',
        ), // ✨ FIX: Correct Route
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'method': method,
          'walletType': walletType,
          'accountDetails': details,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network Error. Check your connection.',
      };
    }
  }

  // --- 🎟️ CREATE VOUCHER (User Paid + 3% Fee) ---
  static Future<Map<String, dynamic>> createVoucher({
    required double amount,
    required String walletType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.post(
        Uri.parse(
          '${AppConstants.baseUrl}/voucher/create',
        ), // ✨ FIX: Correct Route
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'amount': amount, 'walletType': walletType}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network Error.'};
    }
  }

  // --- 🎁 REDEEM VOUCHER ---
  static Future<Map<String, dynamic>> redeemVoucher({
    required String code,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.post(
        Uri.parse(
          '${AppConstants.baseUrl}/voucher/redeem',
        ), // ✨ FIX: Correct Route
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network Error.'};
    }
  }

  // --- 💸 TRANSFER FUNDS (P2P - 7% Fee) ---
  static Future<Map<String, dynamic>> transferFunds({
    required String receiverUsername,
    required double amount,
    required String walletType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/transfer'), // ✨ FIX: Correct Route
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'receiverUsername': receiverUsername,
          'amount': amount,
          'walletType': walletType,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network Error.'};
    }
  }
}
