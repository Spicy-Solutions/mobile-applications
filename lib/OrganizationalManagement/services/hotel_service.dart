import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sweet_manager/OrganizationalManagement/models/hotel.dart';
import 'package:sweet_manager/OrganizationalManagement/models/multimedia.dart';
import 'package:sweet_manager/shared/infrastructure/services/base_service.dart';

class HotelService extends BaseService {
  Future<List<Hotel>> getHotels() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hotels'),
        headers: {
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Hotel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Hotel?> getHotelById(int hotelId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hotels/$hotelId'),
        headers: {
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Hotel.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<Hotel>> getHotelByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hotels'),
        headers: {
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => Hotel.fromJson(json))
            .where((hotel) => hotel.category == category)
            .toList();
      } else {
        return [];
      }
    }catch (e) {
      return [];
    }
  }

  Future<Multimedia?> getMainHotelMultimedia(int hotelId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/multimedia/main?hotelId=$hotelId'),
        headers: {
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Multimedia.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Multimedia?> getHotelLogoMultimedia(int hotelId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/multimedia/logo?hotel=$hotelId'),
        headers: {
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Multimedia.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<Multimedia>> getHotelDetailMultimedia(int hotelId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/multimedia/details?hotelId=$hotelId'),
        headers: {
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Multimedia.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> registerHotel(String name, String description, String email, String address, String phone, String category) async {
    try{
      final token = await storage.read(key: 'token');
      final ownerId = await tokenHelper.getIdentity();
      final response = await http.post(Uri.parse('$baseUrl/hotels'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
          body: jsonEncode({
            'ownerId': ownerId,
            'name': name,
            'description': description,
            'email': email,
            'address': address,
            'phone': phone,
            'category': category
          }));

      if (response.statusCode == 201) {
        return true;
      }

      return false;
    }
    catch(e) {
      rethrow;
    }
  }

}