// services/hotel_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/infrastructure/services/base_service.dart';
import '../models/hotel.dart';

class HotelService extends BaseService {
  // Usar storage heredado de BaseService en lugar de crear una nueva instancia

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await storage.read(key: 'token'); // Usar storage heredado
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': '*/*',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('Using token for hotel request: ${token.substring(0, 20)}...'); // Log parcial del token
    } else {
      print('No token found in storage');
    }

    return headers;
  }

  // Método para validar si el token es válido
  Future<bool> _isTokenValid() async {
    try {
      final token = await storage.read(key: 'token'); // Usar storage heredado
      if (token == null || token.isEmpty) {
        print('No token found');
        return false;
      }

      // Decodificar el token para verificar expiración
      final parts = token.split('.');
      if (parts.length != 3) {
        print('Invalid JWT format');
        return false;
      }

      // Normalizar el payload base64
      String payload = parts[1];
      // Agregar padding si es necesario
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decoded = utf8.decode(base64Decode(payload));
      final payloadMap = json.decode(decoded);

      final exp = payloadMap['exp'];
      if (exp != null) {
        final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final now = DateTime.now();

        // Agregar buffer de 30 segundos para evitar problemas de timing
        final isValid = expirationTime.isAfter(now.add(Duration(seconds: 30)));

        print('Token expiration: $expirationTime');
        print('Current time: $now');
        print('Token is valid: $isValid');

        return isValid;
      }

      return true; // Si no hay exp, asumimos que es válido
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  Future<Hotel?> getHotelById(String hotelId) async {
    try {
      print('Getting hotel by ID: $hotelId');

      // Verificar si el token es válido antes de hacer la petición
      final isValid = await _isTokenValid();
      if (!isValid) {
        await storage.delete(key: 'token'); // Limpiar token inválido
        throw Exception('Token inválido o expirado. Por favor, inicia sesión nuevamente.');
      }

      final headers = await _getAuthHeaders();

      // Corregir la URL - evitar duplicación de /api/v1
      // Verificar si baseUrl ya incluye /api/v1
      String url;
      if (baseUrl.endsWith('/api/v1')) {
        url = '$baseUrl/hotels/$hotelId';
      } else {
        url = '$baseUrl/api/v1/hotels/$hotelId';
      }

      print('Making request to: $url');
      print('Headers: ${headers.keys.join(', ')}');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Hotel response status: ${response.statusCode}');
      print('Hotel response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Hotel data parsed successfully: ${data['name']}');
        return Hotel.fromJson(data);
      } else if (response.statusCode == 401) {
        print('Unauthorized access - token may be expired');
        // Limpiar el token inválido
        await storage.delete(key: 'token');
        throw Exception('Token inválido o expirado. Por favor, inicia sesión nuevamente.');
      } else if (response.statusCode == 404) {
        print('Hotel not found with ID: $hotelId');
        throw Exception('Hotel no encontrado');
      } else {
        print('Failed to load hotel info: ${response.statusCode} - ${response.body}');
        throw Exception('Error al cargar información del hotel: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getHotelById: $e');
      rethrow; // Re-lanzamos la excepción para que sea manejada en la vista
    }
  }

  Future<Hotel?> updateHotel(String hotelId, Map<String, dynamic> hotelData) async {
    try {
      print('Updating hotel with ID: $hotelId');

      // Verificar si el token es válido antes de hacer la petición
      final isValid = await _isTokenValid();
      if (!isValid) {
        await storage.delete(key: 'token');
        throw Exception('Token inválido o expirado. Por favor, inicia sesión nuevamente.');
      }

      final headers = await _getAuthHeaders();

      // Corregir la URL - evitar duplicación de /api/v1
      String url;
      if (baseUrl.endsWith('/api/v1')) {
        url = '$baseUrl/hotels/$hotelId';
      } else {
        url = '$baseUrl/api/v1/hotels/$hotelId';
      }

      print('Making PUT request to: $url');
      print('Request body: ${json.encode(hotelData)}');
      print('Headers: ${headers.keys.join(', ')}');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(hotelData),
      );

      print('Update hotel response status: ${response.statusCode}');
      print('Update hotel response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Hotel updated successfully: ${data['name']}');
        return Hotel.fromJson(data);
      } else if (response.statusCode == 401) {
        print('Unauthorized access - token may be expired');
        await storage.delete(key: 'token');
        throw Exception('Token inválido o expirado. Por favor, inicia sesión nuevamente.');
      } else if (response.statusCode == 404) {
        print('Hotel not found with ID: $hotelId');
        throw Exception('Hotel no encontrado');
      } else if (response.statusCode == 400) {
        print('Bad request - invalid data: ${response.body}');
        throw Exception('Datos inválidos para actualizar el hotel');
      } else if (response.statusCode == 403) {
        print('Forbidden - insufficient permissions');
        throw Exception('No tienes permisos para actualizar este hotel');
      } else {
        print('Failed to update hotel: ${response.statusCode} - ${response.body}');
        throw Exception('Error al actualizar el hotel: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateHotel: $e');
      rethrow; // Re-lanzamos la excepción para que sea manejada en la vista
    }
  }


  Future<List<Hotel>> getAllHotels() async {
    try {
      // Verificar si el token es válido antes de hacer la petición
      final isValid = await _isTokenValid();
      if (!isValid) {
        await storage.delete(key: 'token');
        throw Exception('Token expirado. Por favor, inicia sesión nuevamente.');
      }

      final headers = await _getAuthHeaders();

      // Corregir la URL - evitar duplicación
      String url;
      if (baseUrl.endsWith('/api/v1')) {
        url = '$baseUrl/hotels';
      } else {
        url = '$baseUrl/api/v1/hotels';
      }

      print('Making request to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Hotels response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Hotel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        // Limpiar el token inválido
        await storage.delete(key: 'token');
        throw Exception('Token inválido o expirado. Por favor, inicia sesión nuevamente.');
      } else {
        throw Exception('Error al cargar hoteles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllHotels: $e');
      rethrow;
    }
  }



  // Método para verificar el estado del token
  Future<bool> checkTokenStatus() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        print('No token found');
        return false;
      }

      print('Token found, checking validity...');
      final isValid = await _isTokenValid();

      if (!isValid) {
        print('Token is expired, clearing storage');
        await storage.delete(key: 'token');
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking token status: $e');
      return false;
    }
  }

  // Método para limpiar el token
  Future<void> clearToken() async {
    await storage.delete(key: 'token');
    print('Token cleared from storage');
  }
}