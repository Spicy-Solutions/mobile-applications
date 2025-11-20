import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:sweet_manager/shared/infrastructure/services/base_service.dart';

class AuthService extends BaseService {
  Future<bool> login(String email, String password, int roleId) async {

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/authentication/sign-in'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'roleId': roleId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'email', value: email);
        await storage.write(key: 'password', value: password);

        await storage.write(key: 'token', value: data['token']);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> signupOwner(int id, String name, String surname, String phone,
      String email, String password, String photoURL) async {
    try {
      final response =
          await http.post(Uri.parse('$baseUrl/authentication/sign-up-owner'),
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'id': id,
                'name': name,
                'surname': surname,
                'phone': phone,
                'email': email,
                'password': password,
                'photoURL': photoURL
              }));

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> signupGuest(int id, String name, String surname, String phone,
      String email, String password, String photoURL) async {
    try {
      final response =
          await http.post(Uri.parse('$baseUrl/authentication/sign-up-guest'),
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'id': id,
                'name': name,
                'surname': surname,
                'phone': phone,
                'email': email,
                'password': password,
                'photoURL': photoURL
              }));

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> refreshSession() async {
    try {
      await logout();
      String? email = await storage.read(key: 'email');
      String? password = await storage.read(key: 'password');

      return await login(email!, password!, 1);
    }
    catch(e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
  }

  Future<bool> isAuthenticated() async {
    final token = await storage.read(key: 'token');

    return token == null ? false : true;
  }
}