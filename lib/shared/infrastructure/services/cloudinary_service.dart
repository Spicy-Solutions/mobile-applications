import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final String _cloudName;
  final String _uploadPreset;
  final String _baseUrl;

  CloudinaryService({
    String cloudName = 'dqawjz3ih',
    String uploadPreset = 'sweetmanager',
  })  : _cloudName = cloudName,
        _uploadPreset = uploadPreset,
        _baseUrl = 'https://api.cloudinary.com/v1_1/$cloudName';

  /// Sube una imagen a Cloudinary desde un XFile
  ///
  /// [image] - El archivo de imagen seleccionado
  /// [folder] - Carpeta opcional donde guardar la imagen (ej: 'user_profiles')
  /// [webImageBytes] - Bytes de la imagen para web (requerido en web)
  /// [publicId] - ID público opcional para la imagen
  /// [tags] - Tags opcionales para la imagen
  ///
  /// Retorna la URL segura de la imagen subida
  Future<String> uploadImage(
    XFile image, {
    String? folder,
    Uint8List? webImageBytes,
    String? publicId,
    List<String>? tags,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/image/upload'),
      );

      print("upload preset: $_uploadPreset");
      print("cloud name: $_cloudName");
      // Campos obligatorios
      request.fields['upload_preset'] = _uploadPreset;

      // Campos opcionales
      if (folder != null) request.fields['folder'] = folder;
      if (publicId != null) request.fields['public_id'] = publicId;
      if (tags != null && tags.isNotEmpty) {
        request.fields['tags'] = tags.join(',');
      }

      // Preparar el archivo según la plataforma
      http.MultipartFile file;

      if (kIsWeb) {
        if (webImageBytes == null) {
          throw CloudinaryException(
              'webImageBytes is required for web platform');
        }
        file = http.MultipartFile.fromBytes('file', webImageBytes,
            filename: publicId ??
                'image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      } else {
        file = await http.MultipartFile.fromPath('file', image.path);
      }

      request.files.add(file);

      // Enviar petición
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var result = String.fromCharCodes(responseData);
      var jsonResult = json.decode(result);

      if (response.statusCode == 200) {
        return jsonResult['secure_url'] as String;
      } else {
        print('Error response: $jsonResult');
        throw CloudinaryException(
          'Failed to upload image: ${jsonResult['error']?['message'] ?? 'Unknown error'}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CloudinaryException) rethrow;
      throw CloudinaryException('Upload failed: $e');
    }
  }
}

// Clase para manejar excepciones específicas de Cloudinary
class CloudinaryException implements Exception {
  final String message;
  final int? statusCode;

  CloudinaryException(this.message, {this.statusCode});

  @override
  String toString() => 'CloudinaryException: $message';
}