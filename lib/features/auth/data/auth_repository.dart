import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maraudr_app/config.dart';

class AuthRepository {
  final Dio _dio = Dio(
    BaseOptions(baseUrl: AppConfig.baseUrlAuth),
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
      print('🔐 Tentative de login avec $email');

      final response = await _dio.post(
        '/api/auth',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      print('✅ Réponse reçue: ${response.data}');

      final token = response.data['accessToken'];
      if (token != null) {
        await saveToken(token);
        print('💾 Token sauvegardé');
        return token;
      } else {
        throw Exception("Token non trouvé dans la réponse.");
      }
    } on DioException catch (e) {
      print('❌ Erreur Dio : ${e.response?.data ?? e.message}');
      throw Exception("Erreur de connexion : ${e.response?.data ?? e.message}");
    }
  }
}
