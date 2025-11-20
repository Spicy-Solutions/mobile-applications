import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sweet_manager/shared/infrastructure/services/base_service.dart';

class ProfileService extends BaseService {
   // Método mejorado para manejar errores HTTP
  void _handleHttpError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        throw Exception('Token de autenticación inválido. Por favor, inicia sesión nuevamente.');
      case 403:
        throw Exception('No tienes permisos para acceder a esta información.');
      case 404:
        throw Exception('Endpoint no encontrado. Verifica la URL de la API.');
      case 500:
      case 502:
      case 503:
        throw Exception('Error del servidor. Por favor, intenta más tarde.');
      default:
        try {
          final responseData = jsonDecode(response.body);
          final message = responseData['message'] ?? 'Error desconocido';
          throw Exception(message);
        } catch (e) {
          throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
        }
    }
  }

  // Método para obtener un token válido (similar a RoomService)
  Future<String?> _getValidToken() async {
    try {
      final token = await storage.read(key: 'token');

      if (token == null || token.isEmpty) {
        print('No token found in storage');
        return null;
      }

      if (JwtDecoder.isExpired(token)) {
        print('Token is expired');
        await storage.delete(key: 'token');
        await storage.delete(key: 'user_data');
        return null;
      }

      return token;
    } catch (e) {
      print('Error validating token: $e');
      return null;
    }
  }

  // Método auxiliar para obtener el guest ID del token
  Future<int?> _getGuestIdFromToken() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return null;

      final decodedToken = JwtDecoder.decode(token);

      // Buscar el guest ID en el claim específico
      final guestId = decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/sid'];

      if (guestId != null) {
        return int.tryParse(guestId.toString());
      }

      return null;
    } catch (e) {
      print('Error extracting guest ID from token: $e');
      return null;
    }
  }

  // Método auxiliar para obtener el owner ID del token
  Future<int?> _getOwnerIdFromToken() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return null;

      final decodedToken = JwtDecoder.decode(token);

      // Buscar el owner ID en el claim específico
      final ownerId = decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/sid'];

      if (ownerId != null) {
        return int.tryParse(ownerId.toString());
      }

      return null;
    } catch (e) {
      print('Error extracting owner ID from token: $e');
      return null;
    }
  }

  // Método para obtener headers con autenticación (mejorado)
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getValidToken();

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (token != null) 'X-Auth-Token': token,
    };
  }

  // Método corregido para obtener el guest actual (del token)
  Future<Map<String, dynamic>?> getCurrentGuest() async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      // Obtener el guest ID del token
      final guestId = await _getGuestIdFromToken();
      if (guestId == null) {
        throw Exception('No se pudo obtener el ID del guest del token');
      }

      // Usar el endpoint correcto con el guest ID del token
      final uri = Uri.parse('$baseUrl/user/guests/$guestId');

      print('Making request to: $uri');

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      print('Response status for current guest: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        print('Successfully loaded current guest data');
        return responseData;
      } else {
        _handleHttpError(response);
        return null;
      }

    } catch (error) {
      print('Error fetching current guest: $error');
      rethrow;
    }
  }

  // Método para obtener el owner actual (del token)
  Future<Map<String, dynamic>?> getCurrentOwner() async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      // Obtener el owner ID del token
      final ownerId = await _getOwnerIdFromToken();
      if (ownerId == null) {
        throw Exception('No se pudo obtener el ID del owner del token');
      }

      // Usar el endpoint correcto con el owner ID del token
      final uri = Uri.parse('$baseUrl/user/owners/$ownerId');

      print('Making request to: $uri');

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      print('Response status for current owner: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        print('Successfully loaded current owner data');
        return responseData;
      } else {
        _handleHttpError(response);
        return null;
      }

    } catch (error) {
      print('Error fetching current owner: $error');
      rethrow;
    }
  }

  // Método para obtener guest por ID específico (mantiene funcionalidad original)
  Future<Map<String, dynamic>?> getGuestById(int guestId) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      final uri = Uri.parse('$baseUrl/user/guests/$guestId');

      print('Making request to: $uri');

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      print('Response status for guest $guestId: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        _handleHttpError(response);
        return null;
      }
    } catch (e) {
      print('Error fetching guest by ID: $e');
      rethrow;
    }
  }

  // Método mejorado para actualizar guest
  Future<bool> updateGuest(int guestId, Map<String, dynamic> guestData) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/user/guests/$guestId'),
        headers: await _getHeaders(),
        body: json.encode(guestData),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        _handleHttpError(response);
        return false;
      }
    } catch (e) {
      print('Error updating guest: $e');
      rethrow;
    }
  }

  // Método para actualizar el guest actual
  Future<bool> updateCurrentGuest(Map<String, dynamic> guestData) async {
    try {
      final guestId = await _getGuestIdFromToken();
      if (guestId == null) {
        throw Exception('No se pudo obtener el ID del guest del token');
      }

      return await updateGuest(guestId, guestData);
    } catch (e) {
      print('Error updating current guest: $e');
      rethrow;
    }
  }

  // Método para actualizar el owner actual
  Future<bool> updateCurrentOwner(Map<String, dynamic> ownerData) async {
    try {
      final ownerId = await _getOwnerIdFromToken();
      if (ownerId == null) {
        throw Exception('No se pudo obtener el ID del owner del token');
      }

      return await updateOwner(ownerId, ownerData);
    } catch (e) {
      print('Error updating current owner: $e');
      rethrow;
    }
  }

  // Método mejorado para obtener owner por ID
  Future<Map<String, dynamic>?> getOwnerById(int ownerId) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/owners/$ownerId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        _handleHttpError(response);
        return null;
      }
    } catch (e) {
      print('Error fetching owner by ID: $e');
      rethrow;
    }
  }

  // Método mejorado para actualizar owner
  Future<bool> updateOwner(int ownerId, Map<String, dynamic> ownerData) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/user/owners/$ownerId'),
        headers: await _getHeaders(),
        body: json.encode(ownerData),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        _handleHttpError(response);
        return false;
      }
    } catch (e) {
      print('Error updating owner: $e');
      rethrow;
    }
  }

  // Método mejorado para obtener admin por ID
  Future<Map<String, dynamic>?> getAdminById(int adminId) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/admins/$adminId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        _handleHttpError(response);
        return null;
      }
    } catch (e) {
      print('Error fetching admin by ID: $e');
      rethrow;
    }
  }

  // Metodo para obtener el rol del usuario desde el token
  Future<String?> getUserRoleFromToken() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return null;

      final decodedToken = JwtDecoder.decode(token);

      // Buscar el rol en el claim específico
      final role = decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];

      return role?.toString();
    } catch (e) {
      print('Error extracting role from token: $e');
      return null;
    }
  }

  // Método mejorado para actualizar admin
  Future<bool> updateAdmin(int adminId, Map<String, dynamic> adminData) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/user/admins/$adminId'),
        headers: await _getHeaders(),
        body: json.encode(adminData),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        _handleHttpError(response);
        return false;
      }
    } catch (e) {
      print('Error updating admin: $e');
      rethrow;
    }
  }

  // Método para limpiar la sesión
  Future<void> clearSession() async {
    await storage.delete(key: 'token');
    await storage.delete(key: 'user_data');
    print('Session cleared');
  }

  // Método mejorado para verificar si hay una sesión activa
  Future<bool> hasActiveSession() async {
    final token = await _getValidToken();
    return token != null;
  }
}