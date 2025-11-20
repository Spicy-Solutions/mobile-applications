import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sweet_manager/shared/infrastructure/services/base_service.dart';

class PreferencesService extends BaseService {
  Future<int> getPreferenceByGuestId() async {
    try {
      final token = await storage.read(key: 'token');
      final guestId = await tokenHelper.getIdentity();
      final response = await http.get(
        Uri.parse('$baseUrl/guest-preferences/guests/$guestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return responseJson['id'] as int;
      } else {
        throw Exception('Error getting preferences: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}