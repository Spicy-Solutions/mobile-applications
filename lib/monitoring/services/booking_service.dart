// services/booking_service.dart
import 'dart:convert';
import 'package:http/http.dart' as https;
import '../models/booking.dart';
import '../models/hotel.dart';
import '../services/hotel_service.dart';
import '../../shared/infrastructure/services/base_service.dart';
import '../../shared/infrastructure/misc/token_helper.dart';

class BookingService extends BaseService {
  final HotelService _hotelService = HotelService();
  final TokenHelper _tokenHelper = TokenHelper();

  // Método para obtener headers con autenticación
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await storage.read(key: 'token');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      print('Using token for request: ${token.substring(0, 20)}...'); // Log parcial del token
    } else {
      print('No token found in storage');
    }

    return headers;
  }

  // Método corregido para obtener reservas activas por hotel
  Future<List<Booking>> getActiveBookingsByHotel() async {
    try {
      // Obtener el hotel ID del token usando TokenHelper
      final hotelId = await _tokenHelper.getLocality();
      if (hotelId == null) {
        throw Exception('No se pudo obtener el ID del hotel desde el token');
      }

      final headers = await _getAuthHeaders();
      final url = '$baseUrl/booking/get-booking-by-hotel-id-and-state?hotelId=$hotelId&state=active';

      print('Making request to: $url');

      final response = await https.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Manejar diferentes estructuras de respuesta
        List<dynamic> bookingsJson = [];

        if (data is List) {
          // Si la respuesta es directamente un array
          bookingsJson = data;
        } else if (data is Map && data['data'] != null) {
          // Si la respuesta tiene estructura { data: [...] }
          bookingsJson = data['data'];
        } else if (data is Map && data.containsKey('id')) {
          // Si la respuesta es un solo objeto
          bookingsJson = [data];
        }

        print('Processing ${bookingsJson.length} active bookings for hotel $hotelId');

        // Obtener información del hotel para enriquecer las reservas
        Hotel? hotelInfo;
        try {
          hotelInfo = await _hotelService.getHotelById(hotelId);
        } catch (e) {
          print('Error getting hotel info: $e');
        }

        return bookingsJson.map((json) {
          try {
            final booking = Booking.fromJson(json);

            // Enriquecer con información del hotel si está disponible
            if (hotelInfo != null) {
              return Booking(
                id: booking.id,
                paymentCustomerId: booking.paymentCustomerId,
                roomId: booking.roomId,
                description: booking.description,
                startDate: booking.startDate,
                finalDate: booking.finalDate,
                priceRoom: booking.priceRoom,
                nightCount: booking.nightCount,
                amount: booking.amount,
                state: booking.state,
                preferenceId: booking.preferenceId,
                hotelName: hotelInfo.name,
                hotelLogo: null, // El API no retorna logo, mantener null
                hotelPhone: hotelInfo.phone, // Asignar el teléfono del hotel
              );
            }

            return booking;
          } catch (e) {
            print('Error parsing booking: $e');
            print('Booking data: $json');
            // Crear un booking con valores por defecto para datos faltantes
            return _createBookingWithDefaults(json, hotelInfo);
          }
        }).toList();

      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        throw Exception('Failed to load bookings: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getActiveBookingsByHotel: $e');
      throw Exception('Error fetching active bookings: $e');
    }
  }

  // Mantener el método original para compatibilidad (si se necesita)
  Future<List<Booking>> getBookingsByCustomer(String customerId) async {
    try {
      final headers = await _getAuthHeaders();
      print('Making request to: $baseUrl/booking/get-booking-by-customer-id?customerId=$customerId');

      final response = await https.get(
        Uri.parse('$baseUrl/booking/get-booking-by-customer-id?customerId=$customerId'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Manejar diferentes estructuras de respuesta
        List<dynamic> bookingsJson = [];

        if (data is List) {
          // Si la respuesta es directamente un array
          bookingsJson = data;
        } else if (data is Map && data['data'] != null) {
          // Si la respuesta tiene estructura { data: [...] }
          bookingsJson = data['data'];
        } else if (data is Map && data.containsKey('id')) {
          // Si la respuesta es un solo objeto
          bookingsJson = [data];
        }

        print('Processing ${bookingsJson.length} bookings');

        // Obtener el hotelId del token para enriquecer las reservas
        final hotelId = await tokenHelper.getLocality();
        Hotel? hotelInfo;

        if (hotelId != null) {
          hotelInfo = await _hotelService.getHotelById(hotelId);
        }

        return bookingsJson.map((json) {
          try {
            final booking = Booking.fromJson(json);

            // Enriquecer con información del hotel si está disponible
            if (hotelInfo != null) {
              return Booking(
                id: booking.id,
                paymentCustomerId: booking.paymentCustomerId,
                roomId: booking.roomId,
                description: booking.description,
                startDate: booking.startDate,
                finalDate: booking.finalDate,
                priceRoom: booking.priceRoom,
                nightCount: booking.nightCount,
                amount: booking.amount,
                state: booking.state,
                preferenceId: booking.preferenceId,
                hotelName: hotelInfo.name,
                hotelLogo: null, // El API no retorna logo, mantener null
                hotelPhone: hotelInfo.phone, // Asignar el teléfono del hotel
              );
            }

            return booking;
          } catch (e) {
            // Crear un booking con valores por defecto para datos faltantes
            rethrow;
          }
        }).toList();

      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        throw Exception('Failed to load bookings: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  // Método para obtener el hotelId del token
  Future<String?> _getHotelIdFromToken() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        print('No token found');
        return null;
      }

      final parts = token.split('.');
      if (parts.length != 3) {
        print('Invalid JWT format');
        return null;
      }

      String base64Payload = parts[1];
      while (base64Payload.length % 4 != 0) {
        base64Payload += '=';
      }

      final payload = json.decode(utf8.decode(base64Decode(base64Payload)));

      // Buscar el hotelId en el claim específico
      final hotelId = payload["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/locality"];

      if (hotelId != null) {
        print('Found hotel ID in token: $hotelId');
        return hotelId.toString();
      }

      print('Hotel ID not found in token');
      return null;
    } catch (e) {
      print('Error getting hotel ID from token: $e');
      return null;
    }
  }

  // Método auxiliar para crear booking con valores por defecto
  Booking _createBookingWithDefaults(Map<String, dynamic> json, Hotel? hotelInfo) {
    return Booking(
      id: json['id']?.toString() ?? '',
      paymentCustomerId: json['paymentCustomerId']?.toString() ?? json['customerId']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? json['room_id']?.toString() ?? '',
      description: json['description']?.toString(),
      startDate: _parseDate(json['startDate']) ?? DateTime.now(),
      finalDate: _parseDate(json['finalDate']) ?? DateTime.now().add(const Duration(days: 1)),
      priceRoom: _parseDouble(json['priceRoom'] ?? json['price_room'] ?? json['price']) ?? 0.0,
      nightCount: _parseInt(json['nightCount'] ?? json['night_count']) ?? 1,
      amount: _parseDouble(json['amount']) ?? 0.0,
      state: json['state']?.toString()?.toLowerCase() ?? 'inactive',
      preferenceId: json['preferenceId']?.toString() ?? json['preference_id']?.toString(),
      hotelName: hotelInfo?.name ?? json['hotelName']?.toString() ?? json['hotel_name']?.toString() ?? 'Hotel',
      hotelLogo: json['hotelLogo']?.toString() ?? json['hotel_logo']?.toString(),
      hotelPhone: hotelInfo?.phone ?? json['hotelPhone']?.toString() ?? json['hotel_phone']?.toString(),
    );
  }

  // Métodos auxiliares para parsing seguro
  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String) {
        return DateTime.parse(value);
      }
      return null;
    } catch (e) {
      print('Error parsing date: $value');
      return null;
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    try {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.parse(value);
      }
      return null;
    } catch (e) {
      print('Error parsing double: $value');
      return null;
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    try {
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.parse(value);
      }
      if (value is double) {
        return value.toInt();
      }
      return null;
    } catch (e) {
      print('Error parsing int: $value');
      return null;
    }
  }

  Future<bool> updateBooking(String bookingId, String state) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await https.put(
        Uri.parse('$baseUrl/booking/update-booking-state'),
        headers: headers,
        body: json.encode({
          'id': bookingId,
          'state': state,
        }),
      );

      if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      }

      return response.statusCode == 200;
    } catch (e) {
      print('Error in updateBooking: $e');
      throw Exception('Error updating booking state: $e');
    }
  }

  Future<Booking> createBooking(Booking booking) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await https.post(
        Uri.parse('$baseUrl/booking/create-booking'),
        headers: headers,
        body: json.encode(Booking.toDisplayableBooking(booking)),
      );

      if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return booking;
      } else {
        throw Exception('Failed to create booking: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in createBooking: $e');
      throw Exception('Error creating booking: $e');
    }
  }

  Future<List<Booking>> getBookings(String hotelId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await https.get(
        Uri.parse('$baseUrl/booking/get-all-bookings?hotelId=$hotelId'),
        headers: headers,
      );

      if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> bookingsJson = data['data'] ?? [];
        return bookingsJson.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bookings: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getBookings: $e');
      throw Exception('Error fetching bookings: $e');
    }
  }
}