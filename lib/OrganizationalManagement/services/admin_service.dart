import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sweet_manager/shared/infrastructure/services/base_service.dart';
import 'package:sweet_manager/shared/infrastructure/misc/token_helper.dart';

class AdminService extends BaseService {
  final TokenHelper _tokenHelper = TokenHelper();

  // Nueva función: Obtener admins del hotel actual basado en el token
  Future<List<Map<String, dynamic>>> getCurrentHotelAdmins() async {
    try {
      // Obtener el hotel ID del token usando getLocality()
      final hotelId = await _tokenHelper.getLocality();

      if (hotelId == null) {
        print('No hotel ID found in token');
        return [];
      }

      print('Getting admins for hotel ID: $hotelId');

      // Convertir a int si es necesario
      final hotelIdInt = int.tryParse(hotelId);
      if (hotelIdInt == null) {
        print('Invalid hotel ID format: $hotelId');
        return [];
      }

      // Usar la función existente getAdminsByHotel
      return await getAdminsByHotel(hotelIdInt);

    } catch (e) {
      print('Error getting current hotel admins: $e');
      return [];
    }
  }

  // GET: Obtener admin por email (sin filtro de hotel)
  Future<Map<String, dynamic>?> getAdminByEmail(String email) async {
    try {
      final token = await storage.read(key: 'token');

      final response = await http.get(
        Uri.parse('$baseUrl/user/admins?email=$email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        // Check if response is a single object or an array
        if (responseData is Map<String, dynamic>) {
          // Single admin object returned
          print('Admin found (single object): $responseData');
          return responseData;
        } else if (responseData is List<dynamic>) {
          // Array returned - check if not empty
          if (responseData.isNotEmpty) {
            print('Admin found (from array): ${responseData.first}');
            return responseData.first as Map<String, dynamic>;
          } else {
            print('No admin found with email: $email in response array');
            return null;
          }
        } else {
          print('Unexpected response format: ${responseData.runtimeType}');
          return null;
        }
      } else {
        print('Admin search failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting admin by email: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _searchAdminInAllHotels(String email) async {
    try {
      final token = await storage.read(key: 'token');

      // Intentar con diferentes hotelIds (puedes ajustar según tu caso)
      List<int> hotelIds = [1, 2, 3, 4, 5]; // Ajusta según tus hoteles

      for (int hotelId in hotelIds) {
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/user/admins?hotelId=$hotelId&email=$email'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            },
          );

          if (response.statusCode == 200) {
            final dynamic responseData = jsonDecode(response.body);

            if (responseData is Map<String, dynamic>) {
              print('Admin found in hotel $hotelId (single object): $responseData');
              return responseData;
            } else if (responseData is List<dynamic> && responseData.isNotEmpty) {
              print('Admin found in hotel $hotelId (from array): ${responseData.first}');
              return responseData.first as Map<String, dynamic>;
            }
          }
        } catch (e) {
          print('Error searching in hotel $hotelId: $e');
          continue;
        }
      }

      return null;
    } catch (e) {
      print('Error searching admin in all hotels: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAdminByEmailAndHotel(String email, int hotelId) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$baseUrl/user/admins?hotelId=$hotelId&email=$email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        if (responseData is Map<String, dynamic>) {
          return responseData;
        } else if (responseData is List<dynamic>) {
          if (responseData.isNotEmpty) {
            return responseData.first as Map<String, dynamic>;
          } else {
            print('No admin found with email: $email in hotel: $hotelId');
            return null;
          }
        }
      } else {
        print('Admin not found: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting admin by email and hotel: $e');
      return null;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$baseUrl/user/admins'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      print('All admins response: ${response.statusCode}');
      print('All admins body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        if (responseData is List<dynamic>) {
          return responseData.cast<Map<String, dynamic>>();
        } else {
          print('Expected array but got: ${responseData.runtimeType}');
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting all admins: $e');
      return [];
    }
  }

  Future<bool> assignAdminToHotel(int adminId, int hotelId) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.put(
        Uri.parse('$baseUrl/user/admins/$adminId/hotel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'hotelId': hotelId
        }),
      );

      print('Assign admin response: ${response.statusCode}');
      print('Assign admin body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to assign admin to hotel: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error assigning admin to hotel: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAdminsByHotel(int hotelId) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$baseUrl/user/admins?hotelId=$hotelId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      print('Admins by hotel response: ${response.statusCode}');
      print('Admins by hotel body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        if (responseData is List<dynamic>) {
          return responseData.cast<Map<String, dynamic>>();
        } else {
          print('Expected array but got: ${responseData.runtimeType}');
          return [];
        }
      } else {
        print('Failed to get admins by hotel: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting admins by hotel: $e');
      return [];
    }
  }
}