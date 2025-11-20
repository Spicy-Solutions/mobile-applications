import 'package:http/http.dart' as http;
import 'package:sweet_manager/iam/domain/model/aggregates/guest.dart';
import 'package:sweet_manager/iam/domain/model/aggregates/owner.dart';
import 'package:sweet_manager/iam/domain/model/commands/update_guest_preferences.dart';
import 'package:sweet_manager/iam/domain/model/commands/update_user_profile_request.dart';
import 'package:sweet_manager/iam/domain/model/entities/guest_preference.dart';

import 'dart:convert';

import 'package:sweet_manager/shared/infrastructure/services/base_service.dart';

class UserService extends BaseService {
  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = await storage.read(key: 'token');
      headers['Authorization'] = 'Bearer $token';

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<int?> getUserId() async {
    try {
      final id = await tokenHelper.getIdentity();
      if (id == null) {
        throw Exception('User ID not found in token');
      }

      print('User ID: $id');
      return int.parse(id);
    } catch (e) {
      print('Error fetching user ID: $e');
      return null;
    }
  }

  Future<int?> getRoleId() async {
    try {
      final role = await tokenHelper.getRole();
      if (role == null) {
        throw Exception('Role ID not found in token');
      }

      print('Role ID: $role');
      return role == "ROLE_OWNER" ? 1 : 3;
    } catch (e) {
      print('Error fetching role ID: $e');
      return null;
    }
  }

  Future<Owner?> getOwnerProfile() async {
    try {
      final headers = await _getHeaders();
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('Owner ID is null');
      }
      print('uri $baseUrl/user/owners/$userId');

      final response = await http.get(
        Uri.parse('$baseUrl/user/owners/$userId'),
        headers: headers,
      );
      print(response.body);
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load user profile: ${response.reasonPhrase}');
      }

      final data = json.decode(response.body);
      return Owner.fromJson(data);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Guest?> getGuestProfile() async {
    try {
      final headers = await _getHeaders();
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('Guest ID is null');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/guests/$userId'),
        headers: headers,
      );
      print('Response body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load user profile: ${response.reasonPhrase}');
      }

      final data = json.decode(response.body);
      return Guest.fromJson(data);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<bool> updateUserProfile(EditUserProfileRequest request) async {
    try {
      final headers = await _getHeaders();
      final userId = await getUserId();
      final roleId = await getRoleId();

      if (userId == null || roleId == null) {
        throw Exception('User ID or Role ID is null');
      }

      final uri = (roleId == 3)
          ? Uri.parse('$baseUrl/user/guests/$userId')
          : Uri.parse('$baseUrl/user/owners/$userId');

      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update owner profile: ${response.reasonPhrase}');
      }

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  Future<bool> setGuestPreferences(GuestPreferences preferences) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/guest-preferences'),
        headers: headers,
        body: json.encode(preferences.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to set guest preferences: ${response.reasonPhrase}');
      }

      return true;
    } catch (e) {
      print('Error setting guest preferences: $e');
      return false;
    }
  }

  Future<GuestPreferences?> getGuestPreferences() async {
    try {
      final headers = await _getHeaders();
      final guestId = await getUserId();
      if (guestId == null) {
        throw Exception('Guest ID is null');
      }
      final response = await http.get(
        Uri.parse('$baseUrl/guest-preferences/guests/$guestId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load guest preferences: ${response.reasonPhrase}');
      }

      final data = json.decode(response.body);
      return GuestPreferences.fromJson(data);
    } catch (e) {
      print('Error fetching guest preferences: $e');
      return null;
    }
  }

  Future<bool> updateGuestPreferences(
      EditGuestPreferences preferences, int preferenceId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/guest-preferences/$preferenceId'),
        headers: headers,
        body: json.encode(preferences.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update guest preferences: ${response.reasonPhrase}');
      }

      return true;
    } catch (e) {
      print('Error updating guest preferences: $e');
      return false;
    }
  }
}