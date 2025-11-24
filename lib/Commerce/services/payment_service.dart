import 'dart:convert';

import 'package:sweetmanager/shared/infrastructure/services/base_service.dart';
import 'package:http/http.dart' as http;

class PaymentService extends BaseService {
  Future<bool> registerPaymentOwner(String description, int finalAmount) async {
    try {
      final token = await storage.read(key: 'token');
      final ownerId = await tokenHelper.getIdentity();
      final response = await http.post(Uri.parse('$baseUrl/payment-owner'),headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        'ownerId': ownerId,
        'description': description,
        'finalAmount': finalAmount
      }));

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    }
    catch(e) {
      rethrow;
    }
  }

  Future<int> registerPaymentCustomer(int finalAmount) async {
    try {
      final token = await storage.read(key: 'token');
      final guestId = await tokenHelper.getIdentity();
      
      final response = await http.post(
        Uri.parse('$baseUrl/payment-customer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'guestId': guestId,
          'finalAmount': finalAmount,
        }),
      );

      if (response.statusCode == 201) {
        final responseJson = jsonDecode(response.body);
        return responseJson['id'] as int;
      } else {
        throw Exception('Error creating payment: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

}