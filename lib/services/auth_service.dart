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
        body: jsonEncode({
          'username': username.toLowerCase().trim(), 
          'password': password
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

  // --- 📝 REGISTER API (WITH DOB & NUMERIC USERNAME FIX) ---
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
    required String dob,
    required String sponsorUsername, // ✨ Backend expects this
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.toString().toLowerCase().trim(), // Numbers allow karne ke liye
          'email': email.toLowerCase().trim(),
          'password': password,
          'dob': dob,
          'sponsorUsername': sponsorUsername.toString().toLowerCase().trim(), // ✨ Match for backend
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
        Uri.parse('$baseUrl/reset-password-dob'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'dob': dob,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 404) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network Error. Is your server running?',
      };
    }
  }

  // --- 👤 GET CURRENT USER DATA ---
  static Future<Map<String, dynamic>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return {'success': false, 'message': 'Not logged in'};\
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