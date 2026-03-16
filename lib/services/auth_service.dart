import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart'; // ✨ IMPORT CONSTANTS

class AuthService {
  // ✨ YAHAN CONSTANT USE KIYA HAI
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

  // --- 📝 REGISTER API ---
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
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
          'dob': '2000-01-01', // Dummy DOB for now
          'sponsorUsername': sponsorUsername,
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

  // --- 👤 GET CURRENT USER DATA (Balance & Wallets) ---
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
