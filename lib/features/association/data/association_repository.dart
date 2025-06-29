import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maraudr_app/config.dart';
import '../models/association.dart';

class AssociationRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrlAssociation));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<Map<String, dynamic>>> fetchMemberships() async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await _dio.get(
      '/association/membership',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return (response.data as List).map((e) => {
      'id': e['id'],
      'name': e['name'],
    }).toList();
  }

  Future<List<Association>> fetchUserAssociations() async {
    final token = await _storage.read(key: 'jwt_token');
    print("📦 TOKEN LU : $token"); // Ajoute ceci

    final response = await _dio.get(
      '/association/membership',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );


    return (response.data as List)
        .map((json) => Association.fromJson(json))
        .toList();
  }

  Future<void> saveSelectedAssociationId(String id) async {
    await _storage.write(key: 'selected_association_id', value: id);
  }

  Future<String?> getSelectedAssociationId() async {
    return await _storage.read(key: 'selected_association_id');
  }
}
