import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenHelper {

  final storage = const FlutterSecureStorage();

  Future<String?> getIdentity() async {
    // Retrieve token from local storage
    String? token = await storage.read(key: 'token');
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    // Get Role in Claims token
    return decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/sid']?.toString();
  }

  Future<String?> getRole() async {
    // Retrieve token from local storage
    String? token = await storage.read(key: 'token');
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    // Get Role in Claims token
    return decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']?.toString();
  }

  Future<String?> getLocality() async {
    // Retrieve token from local storage
    String? token = await storage.read(key: 'token');
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    // Get Role in Claims token
    return decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/locality']?.toString();
  }
}