import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sweet_manager/shared/infrastructure/services/base_service.dart';
import '../models/provider.dart';

class ProviderService extends BaseService {
  Future<List<Provider>> getProvidersByHotelId(String hotelId) async {
    try {
      final token = await storage.read(key: 'token');

      final response = await http.get(
        Uri.parse('$baseUrl/providers/hotel/$hotelId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Provider.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<Provider>> getProviders() async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$baseUrl/providers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Provider.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Provider?> getProviderById(int id) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$baseUrl/providers/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Provider.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> createProvider(Provider provider, String hotelId) async {
    try {
      final token = await storage.read(key: 'token');

      final providerData = provider.toJson();
      providerData['hotelId'] = hotelId;

      final response = await http.post(
        Uri.parse('$baseUrl/providers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(providerData),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProvider(int providerId, Provider provider) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.put(
        Uri.parse('$baseUrl/providers/$providerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(provider.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Método de eliminación lógica (cambiar estado a inactive)
  Future<bool> deactivateProvider(int id) async {
    try {
      final token = await storage.read(key: 'token');

      // Primero obtenemos el proveedor actual
      final currentProvider = await getProviderById(id);
      if (currentProvider == null) return false;

      // Creamos una copia con estado 'inactive'
      final deactivatedProvider = Provider(
        id: currentProvider.id,
        name: currentProvider.name,
        email: currentProvider.email,
        phone: currentProvider.phone,
        state: 'inactive', // Cambiamos el estado
      );

      // Actualizamos el proveedor
      return await updateProvider(id, deactivatedProvider);
    } catch (e) {
      return false;
    }
  }

  // Mantener método de eliminación física como alternativa
  Future<bool> deleteProvider(int id) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.delete(
        Uri.parse('$baseUrl/providers/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      // Verificar más códigos de estado
      return response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202;
    } catch (e) {
      print('Error deleting provider: $e'); // Para debugging
      return false;
    }
  }

  // Método mejorado para manejar errores
  Future<Map<String, dynamic>> deleteProviderWithDetails(int id) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.delete(
        Uri.parse('$baseUrl/providers/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      return {
        'success': response.statusCode == 200 ||
            response.statusCode == 204 ||
            response.statusCode == 202,
        'statusCode': response.statusCode,
        'message': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Error de conexión: $e',
      };
    }
  }
}