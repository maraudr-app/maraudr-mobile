import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final Dio _dio = Dio(
    BaseOptions(baseUrl: 'http://localhost:8000'),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<String> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/token', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['access_token'];
      if (token != null) {
        await saveToken(token);
        return token;
      } else {
        throw Exception("Token non trouvé dans la réponse.");
      }
    } on DioException catch (e) {
      throw Exception("Erreur de connexion : ${e.response?.data?['message'] ?? e.message}");
    }
  }
}
