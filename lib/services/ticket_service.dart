import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class TicketService {
  static const String baseUrl = '${AppConstants.baseUrl}/ticket';

  static Future<Map<String, dynamic>> buyTicket({
    required String gameType,
    required int quantity,
    required List<Map<String, dynamic>> lines,
    required String walletType, // ✨ NAYA PARAMETER ADD KIYA HAI
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication Error. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/buy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'gameType': gameType,
          'quantity': quantity,
          'lines': lines,
          'walletType': walletType, // ✨ Backend ko wallet bheja ja raha hai
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
        'message': 'Network Error. Check your connection.',
      };
    }
  }

  // --- 🎟️ GET MY TICKETS API ---
  static Future<Map<String, dynamic>> getMyTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return {'success': false, 'message': 'Not logged in'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/my-tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch tickets'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network Error. Check your connection.',
      };
    }
  }
}
