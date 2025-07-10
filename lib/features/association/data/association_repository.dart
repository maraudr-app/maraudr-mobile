import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maraudr_app/config.dart';

class AssociationRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrlAssociation));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AssociationRepository() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print("🔐 Intercepteur - Token injecté automatiquement : $token");
          } else {
            print("⚠️ Aucun token trouvé dans l'intercepteur");
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchMemberships() async {
    final response = await _dio.get('/association/membership');
    return (response.data as List).map((e) => {
      'id': e['id'],
      'name': e['name'],
    }).toList();
  }

  Future<void> saveSelectedAssociationId(String id) async {
    await _storage.write(key: 'selected_association_id', value: id);
  }

  Future<String?> getSelectedAssociationId() async {
    return await _storage.read(key: 'selected_association_id');
  }
}
