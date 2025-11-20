
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sweet_manager/shared/infrastructure/misc/token_helper.dart';

abstract class BaseService {
  final storage = const FlutterSecureStorage();

  final baseUrl = 'https://sweetmanager-backend-emergents.onrender.com/api/v1';

  final tokenHelper = TokenHelper();
  
}