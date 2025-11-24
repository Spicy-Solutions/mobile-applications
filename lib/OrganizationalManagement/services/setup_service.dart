import 'dart:convert';

import 'package:sweet_manager/shared/infrastructure/services/base_service.dart';
import 'package:http/http.dart' as http;

class SetupService extends BaseService {
  Future<bool> setUpRoomsWithTypeRoom(String description, double price, int countRooms) async {
    try {
      final token = await storage.read(key: 'token');
      final responseTypeRoom = await http.post(Uri.parse('$baseUrl/type-room/create-type-room'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
          body: jsonEncode({
            'description': description,
            'price': price
          }));

      final responseJson = jsonDecode(responseTypeRoom.body);
      final hotelId = await tokenHelper.getLocality();
      final responseRooms = await http.post(Uri.parse('$baseUrl/room/set-up'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
          body: jsonEncode({
            'count': countRooms,
            'typeRoomId': responseJson['id'],
            'hotelId': hotelId
          }));

      if (responseTypeRoom.statusCode == 200 && responseRooms.statusCode == 200) {
        return true;
      }

      return false;
    }
    catch(e) {
      rethrow;
    }
  }
}