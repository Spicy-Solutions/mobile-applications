import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sweet_manager/monitoring/models/room_type.dart';
import 'package:sweet_manager/shared/infrastructure/services/base_service.dart';
import 'package:sweet_manager/monitoring/models/room.dart';

class RoomService extends BaseService {

  Future<String?> _getValidToken() async {
    try {
      final token = await storage.read(key: 'token');

      if (token == null || token.isEmpty) {
        print('No token found in storage'); // DEBUG
        return null;
      }

      // Verificar si el token está expirado
      if (JwtDecoder.isExpired(token)) {
        print('Token is expired'); // DEBUG
        await storage.delete(key: 'token'); // Limpiar token expirado
        return null;
      }

      print('Token is valid'); // DEBUG
      return token;
    } catch (e) {
      print('Error getting token: $e'); // DEBUG
      return null;
    }
  }

  Future<int?> getHotelIdFromToken() async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        return null;
      }

      final decodedToken = JwtDecoder.decode(token);
      print('Decoded token: $decodedToken'); // DEBUG

      const hotelIdClaim = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/locality";

      if (decodedToken.containsKey(hotelIdClaim)) {
        final hotelId = int.tryParse(decodedToken[hotelIdClaim].toString());
        if (hotelId != null) {
          print('Hotel ID found: $hotelId'); // DEBUG
          return hotelId;
        }
      }

      const possibleHotelClaims = [
        "hotelId", "hotel_id", "hotel", "HotelId", "HOTEL_ID"
      ];

      for (final claim in possibleHotelClaims) {
        if (decodedToken.containsKey(claim)) {
          final hotelId = int.tryParse(decodedToken[claim].toString());
          if (hotelId != null) {
            print('Hotel ID found in $claim: $hotelId'); // DEBUG
            return hotelId;
          }
        }
      }

      print('No hotel ID found in token'); // DEBUG
      return null;

    } catch (error) {
      print('Error extracting hotel ID: $error'); // DEBUG
      return null;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getValidToken();

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    print('Headers: $headers'); // DEBUG
    return headers;
  }

  Future<List<Room>> getRoomsByHotel() async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      final hotelId = await getHotelIdFromToken();
      if (hotelId == null) {
        throw Exception('No se pudo obtener el ID del hotel del token');
      }

      final uri = Uri.parse('$baseUrl/room/get-all-rooms').replace(
          queryParameters: {'hotelId': hotelId.toString()}
      );

      print('Getting rooms from: $uri'); // DEBUG

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      print('Get rooms response status: ${response.statusCode}'); // DEBUG
      print('Get rooms response body: ${response.body}'); // DEBUG

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        List<dynamic> roomsJson;

        if (responseData is List) {
          roomsJson = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          roomsJson = responseData['data'] as List;
        } else {
          return [];
        }

        final rooms = roomsJson.map((json) => Room.fromJson(json)).toList();
        return rooms;

      } else {
        _handleHttpError(response);
        return [];
      }

    } catch (error) {
      print('Error in getRoomsByHotel: $error'); // DEBUG
      rethrow;
    }
  }

  Future<Room> createRoom(CreateRoomRequest request) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      final hotelId = await getHotelIdFromToken();
      if (hotelId == null) {
        throw Exception('Hotel ID not found in token');
      }

      // Crear el request con el ID especificado por el usuario
      final createRequest = CreateRoomRequest(
        id: request.id,
        typeRoomId: request.typeRoomId,
        hotelId: hotelId,
        state: 'active', // Usar 'active' como estado inicial
        roomNumber: request.id.toString(),
      );

      final requestBody = jsonEncode(createRequest.toJson());
      print('Create room request URL: $baseUrl/room/create-room'); // DEBUG
      print('Create room request payload: $requestBody'); // DEBUG

      final response = await http.post(
        Uri.parse('$baseUrl/room/create-room'),
        headers: await _getHeaders(),
        body: requestBody,
      );

      print('Create room response status: ${response.statusCode}'); // DEBUG
      print('Create room response body: ${response.body}'); // DEBUG

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        try {
          return Room.fromJson(responseData);
        } catch (e) {
          print('Error parsing response, creating manual room: $e'); // DEBUG
          return Room(
            id: request.id,
            number: request.id.toString(),
            guest: '',
            checkIn: '',
            checkOut: '',
            available: true,
            typeRoomId: request.typeRoomId,
            state: 'active',
          );
        }
      } else {
        print('HTTP Error creating room: ${response.statusCode} - ${response.body}'); // DEBUG
        _handleHttpError(response);
        throw Exception('Error al crear habitación');
      }

    } catch (error) {
      print('Exception in createRoom: $error'); // DEBUG
      if (error is Exception) {
        rethrow;
      } else {
        throw Exception('Error inesperado al crear habitación: $error');
      }
    }
  }

  Future<Room> updateRoomState(int roomId, String newState) async {
    try {
      // PASO 1: Verificar token
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido. Por favor, inicia sesión nuevamente.');
      }

      // PASO 2: Mapear el estado correctamente
      String apiState;
      switch (newState.toLowerCase()) {
        case 'active':
        case 'activo':
        case 'disponible':
          apiState = 'ACTIVE';
          break;
        case 'inactive':
        case 'inactivo':
        case 'no disponible':
          apiState = 'INACTIVE';
          break;
        default:
          apiState = newState.toLowerCase();
      }

      print('Updating room $roomId to state: $apiState'); // DEBUG
      print('Original state input: $newState'); // DEBUG

      // PASO 3: Preparar la URL y el payload
      final url = '$baseUrl/room/update-room-state';
      final payload = jsonEncode({'id': roomId, 'state': apiState});

      print('Update URL: $url'); // DEBUG
      print('Update payload: $payload'); // DEBUG

      // PASO 4: Obtener headers y hacer la petición
      final headers = await _getHeaders();
      print('Update headers: $headers'); // DEBUG

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: payload,
      );

      print('Update response status: ${response.statusCode}'); // DEBUG
      print('Update response body: ${response.body}'); // DEBUG
      print('Update response headers: ${response.headers}'); // DEBUG

      // PASO 5: Manejar la respuesta
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Respuesta exitosa
        if (response.body.isNotEmpty) {
          try {
            final responseData = jsonDecode(response.body);
            return Room(
              id: roomId,
              number: roomId.toString(),
              guest: '',
              checkIn: '',
              checkOut: '',
              available: apiState == 'ACTIVE',
              typeRoomId: 0,
              state: apiState,
            );
          } catch (e) {
            print('Error parsing update response: $e'); // DEBUG
          }
        }

        // Si no hay body o falla el parsing, crear Room manual
        return Room(
          id: roomId,
          number: roomId.toString(),
          guest: '',
          checkIn: '',
          checkOut: '',
          available: apiState == 'ACTIVE',
          typeRoomId: 0,
          state: apiState,
        );

      } else if (response.statusCode == 401) {
        // Token inválido - limpiar y solicitar re-login
        await storage.delete(key: 'token');
        throw Exception('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.');

      } else {
        // Otros errores HTTP
        print('HTTP Error updating room: ${response.statusCode}'); // DEBUG
        _handleHttpError(response);
        throw Exception('Error al actualizar estado de la habitación');
      }

    } catch (error) {
      print('Exception in updateRoomState: $error'); // DEBUG

      if (error.toString().contains('Invalid Token')) {
        await storage.delete(key: 'token');
        throw Exception('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.');
      }

      if (error is Exception) {
        rethrow;
      } else {
        throw Exception('Error inesperado al actualizar estado: $error');
      }
    }
  }

  Future<bool> deleteRoom(int roomId) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/room/delete-room/$roomId'),
        headers: await _getHeaders(),
      );

      print('Delete room response status: ${response.statusCode}'); // DEBUG
      print('Delete room response body: ${response.body}'); // DEBUG

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        _handleHttpError(response);
        return false;
      }

    } catch (error) {
      print('Error in deleteRoom: $error'); // DEBUG
      if (error is Exception) {
        rethrow;
      } else {
        throw Exception('Error inesperado al eliminar habitación: $error');
      }
    }
  }

  void _handleHttpError(http.Response response) {
    print('Handling HTTP error: ${response.statusCode}'); // DEBUG
    print('Error response body: ${response.body}'); // DEBUG

    switch (response.statusCode) {
      case 400:
        throw Exception('Solicitud inválida: ${response.body}');
      case 401:
        throw Exception('Token inválido o expirado. Por favor, inicia sesión nuevamente.');
      case 403:
        throw Exception('No tienes permisos para realizar esta acción');
      case 404:
        throw Exception('Recurso no encontrado');
      case 422:
        throw Exception('Datos inválidos: ${response.body}');
      case 500:
        throw Exception('Error interno del servidor');
      default:
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<List<RoomType>> getTypeRoomsByHotel(int hotelId) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/type-room/get-all-type-rooms?hotelId=$hotelId'),
        headers: await _getHeaders(),
      );

      print('Get room types response status: ${response.statusCode}'); // DEBUG
      print('Get room types response body: ${response.body}'); // DEBUG

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);

        return jsonList.map((json) {
          return RoomType(
            id: json['id'] ?? 0,
            name: json['description'] ?? '',
            price: json['price'] ?? 0,
          );
        }).toList();
      }

      _handleHttpError(response);
      return [];
    } catch (e) {
      print('Error in getTypeRoomsByHotel: $e'); // DEBUG
      rethrow;
    }
  }

  Future<double> getMinimumPriceRoomByHotelId(int hotelId) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/type-room/get-minimum-price-type-room-by-hotel-id?hotelId=$hotelId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return responseJson['minimumPrice'] as double;
      }

      _handleHttpError(response);
      return 0;
    } catch (e) {
      print('Error in getMinimumPriceRoomByHotelId: $e'); // DEBUG
      rethrow;
    }
  }

  Future<int> getRoomByTypeRoomId(int typeRoomId) async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/room/get-room-by-type-room?typeRoomId=$typeRoomId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> rooms = jsonDecode(response.body);

        // Filter only rooms with status == "active"
        final activeRooms = rooms.where((room) => room['state'] == 'ACTIVE').toList();

        if (activeRooms.isNotEmpty) {
          final randomRoom = activeRooms[Random().nextInt(activeRooms.length)];
          return randomRoom['id'] as int;
        }
      }

      return 0;
    } catch (e) {
      print('Error in getRoomByTypeRoomId: $e'); // DEBUG
      rethrow;
    }
  }

  Future<List<RoomType>> getRoomTypesByHotel() async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        throw Exception('No se encontró token de autenticación válido');
      }

      final hotelId = await getHotelIdFromToken();
      if (hotelId == null) {
        throw Exception('No se pudo obtener el ID del hotel del token');
      }

      final uri = Uri.parse('$baseUrl/type-room/get-all-type-rooms').replace(
          queryParameters: {'hotelid': hotelId.toString()}
      );

      print('Getting room types from: $uri'); // DEBUG

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      print('Room types response status: ${response.statusCode}'); // DEBUG
      print('Room types response body: ${response.body}'); // DEBUG

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        List<dynamic> roomTypesJson;

        if (responseData is List) {
          roomTypesJson = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          roomTypesJson = responseData['data'] as List;
        } else {
          return [];
        }

        final Map<int, RoomType> uniqueRoomTypes = {};

        for (final json in roomTypesJson) {
          try {
            final roomType = RoomType.fromJson(json);

            if (roomType.id > 0) {
              uniqueRoomTypes[roomType.id] = roomType;
            }
          } catch (e) {
            print('Error parsing room type: $e, json: $json'); // DEBUG
            continue;
          }
        }

        final result = uniqueRoomTypes.values.toList();
        print('Unique room types: ${result.length}'); // DEBUG

        return result;

      } else {
        _handleHttpError(response);
        return [];
      }

    } catch (error) {
      print('Error loading room types: $error'); // DEBUG
      rethrow;
    }
  }
}