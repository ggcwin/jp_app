import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class WalletService {
  static const String baseUrl = '${AppConstants.baseUrl}/auth';

  static Future<Map<String, dynamic>> depositFunds({
    required double amount,
    required String method,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.post(
        Uri.parse('$baseUrl/deposit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'amount': amount, 'method': method}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network Error. Check your connection.',
      };
    }
  }

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
        Uri.parse('$baseUrl/withdraw'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'method': method,
          'walletType': walletType,
          'details': details,
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

  // --- 🎟️ CREATE VOUCHER (NEW) ---
  static Future<Map<String, dynamic>> createVoucher({
    required double amount,
    required String walletType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.post(
        Uri.parse('$baseUrl/create-voucher'),
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

  // --- 🎁 REDEEM VOUCHER (NEW) ---
  static Future<Map<String, dynamic>> redeemVoucher({
    required String code,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.post(
        Uri.parse('$baseUrl/redeem-voucher'),
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
}
