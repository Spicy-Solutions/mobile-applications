import 'dart:convert';

import 'package:sweetmanager/shared/infrastructure/services/base_service.dart';
import 'package:http/http.dart' as http;

class ContractOwnerService extends BaseService {
  Future<bool> registerContractOwner(int subscriptionId) async {
    try{  
      final ownerId = await tokenHelper.getIdentity();
      final token = await storage.read(key: 'token');
      final now = DateTime.now().toUtc();
      final end = DateTime.now().add(const Duration(days: 30));

      final response = await http.post(Uri.parse('$baseUrl/contract-owner'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        'ownerId': ownerId,
        'startDate': now.toIso8601String(),
        'finalDate': end.toIso8601String(),
        'subscriptionId': subscriptionId,
        'status': 'ACTIVE'
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
}