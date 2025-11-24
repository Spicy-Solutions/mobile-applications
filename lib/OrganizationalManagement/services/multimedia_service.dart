import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sweet_manager/shared/infrastructure/services/base_service.dart';

class MultimediaService extends BaseService {

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



  Future<List<String>> getHotelImages(int hotelId) async {
    final headers = await _getAuthHeaders();

    try {
      // Hacer ambas peticiones en paralelo
      final responses = await Future.wait([
        http.get(
          Uri.parse('$baseUrl/multimedia/main?hotelId=$hotelId'),
          headers: headers,
        ),
        http.get(
          Uri.parse('$baseUrl/multimedia/details?hotelId=$hotelId'),
          headers: headers,
        ),
      ]);

      final mainResponse = responses[0];
      final detailsResponse = responses[1];

      List<String> allImages = [];

      // Procesar respuesta de main (van primero)
      if (mainResponse.statusCode == 200) {
        final mainJsonData = json.decode(mainResponse.body);

        allImages.add(mainJsonData['url']);

      } else {
        print('Error en endpoint main: ${mainResponse.statusCode}');
      }

      // Procesar respuesta de details (van después)
      if (detailsResponse.statusCode == 200) {
        final detailsJsonData = json.decode(detailsResponse.body);

        if (detailsJsonData is List) {
          allImages.addAll(detailsJsonData
              .map((item) => item['url']?.toString() ?? '')
              .where((url) => url.isNotEmpty)
              .toList());
        } else if (detailsJsonData is Map && detailsJsonData['images'] != null) {
          allImages.addAll(List<String>.from(detailsJsonData['images']));
        } else if (detailsJsonData is Map && detailsJsonData['data'] != null) {
          allImages.addAll(List<String>.from(detailsJsonData['data']));
        }
      } else {
        print('Error en endpoint details: ${detailsResponse.statusCode}');
      }

      return allImages;


    } catch (e) {
      print('Error en MultimediaService: $e');
      return []; // Retorna lista vacía en caso de error
    }
  }

  Future<bool> registerMultimedia(String url, String type, int position) async {
    try {
      // Don't forget to refresh token after completing the hotel set up
      final hotelId = await tokenHelper.getLocality();
      final response = await http.post(Uri.parse('$baseUrl/multimedia'), headers: await _getAuthHeaders(),
          body: jsonEncode({
            'hotelId': hotelId,
            'url': url,
            'type': type,
            'position': position
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