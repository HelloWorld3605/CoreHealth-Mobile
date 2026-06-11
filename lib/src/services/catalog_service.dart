import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'environment_config.dart';

/// Read-only catalog/data reads from the shared CoreHealth backend, used to
/// hydrate catalog screens from backend records. Returns lightweight maps so the
/// existing screen widgets can render real BE data with minimal change.
class CatalogService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'corehealth_jwt';

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: _tokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _get(String path) async {
    final res = await http
        .get(
          Uri.parse('${EnvironmentConfig.apiBaseUrl}$path'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Future<void> _post(String path, [Map<String, Object?>? body]) async {
    final res = await http
        .post(
          Uri.parse('${EnvironmentConfig.apiBaseUrl}$path'),
          headers: await _headers(),
          body: jsonEncode(body ?? const {}),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }
  }

  List<Map<String, dynamic>> _asList(dynamic v) => v is List
      ? v.map((e) => (e as Map).cast<String, dynamic>()).toList()
      : const [];

  // --- Mutations (persist user actions to BE) ---
  Future<void> hideFavorite(String id) =>
      _post('/me/favorites/hide', {'id': id});
  Future<void> toggleHabit(String id) => _post('/me/habits/$id/toggle');
  Future<void> createHabit(String name) => _post(
      '/me/habits', {'name': name, 'icon': '🎯', 'color': 'text-emerald-400'});

  // GET /api/shop/products -> { products: [...] }
  Future<List<Map<String, dynamic>>> products() async {
    final data = await _get('/shop/products?size=100');
    final list = data is Map<String, dynamic> ? data['products'] : data;
    return _asList(list);
  }

  // GET /api/exercises -> [ {id,name,muscleGroup,equipment,sets,category,
  //                          difficulty,thumbnailUrl,instructionsJson,videoUrl,tips} ]
  Future<List<Map<String, dynamic>>> exercises() async =>
      _asList(await _get('/exercises?size=100'));

  // GET /api/foods -> [ {id,name,brand,kcal,protein,carbs,fat,category,imageUrl} ]
  Future<List<Map<String, dynamic>>> foods() async =>
      _asList(await _get('/foods?size=100'));

  // GET /api/foods/{id} -> detail incl. ingredientsJson, instructionsJson
  Future<Map<String, dynamic>> foodDetail(String id) async {
    final data = await _get('/foods/$id');
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  // GET /api/challenges -> [ {id,title,description,image,participants,daysLeft,
  //                           totalDays,prize,rewardTokens,status,joined,progress} ]
  Future<List<Map<String, dynamic>>> challenges() async =>
      _asList(await _get('/challenges'));

  // GET /api/me/habits -> { items: [...], summary: {...} }
  Future<List<Map<String, dynamic>>> habits() async {
    final data = await _get('/me/habits');
    final items = data is Map<String, dynamic> ? data['items'] : data;
    return _asList(items);
  }

  // GET /api/me/favorites -> { Meals:[], Workouts:[], Exercises:[], Products:[] }
  Future<Map<String, List<Map<String, dynamic>>>> favorites() async {
    final data = await _get('/me/favorites');
    if (data is! Map<String, dynamic>) return const {};
    return data.map((k, v) => MapEntry(k, _asList(v)));
  }

  // GET /api/leaderboard -> [ {id,name,avatar,streak,points,delta,rank,isCurrentUser} ]
  Future<List<Map<String, dynamic>>> leaderboard() async =>
      _asList(await _get('/leaderboard?scope=global&timeframe=week'));
}
