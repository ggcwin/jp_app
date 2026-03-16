import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class AuthService {
  static const String baseUrl = '${AppConstants.baseUrl}/auth';

  // --- 🔐 LOGIN API ---
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network Error: Check your connection.',
      };
    }
  }

  // --- 📝 REGISTER API (WITH DOB) ---
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
    required String dob, // ✨ DOB ADD HO GAYI
    required String sponsorUsername,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'dob': dob, // ✨ Backend ko asli DOB bhej rahe hain
          'referrer': sponsorUsername, // Backend 'referrer' accept karta hai
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network Error: Check your connection.',
      };
    }
  }

  // --- 🔄 RESET PASSWORD (WITH DOB) ---
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String dob,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password-dob'), // Backend API Link
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'dob': dob,
          'newPassword': newPassword,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network Error'};
    }
  }

  // --- 👤 GET CURRENT USER DATA ---
  static Future<Map<String, dynamic>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return {'success': false, 'message': 'Not logged in'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch user data'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network Error'};
    }
  }
}
