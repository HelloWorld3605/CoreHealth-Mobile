import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models.dart';
import 'environment_config.dart';

/// AI features are served entirely by the shared CoreHealth backend
/// (`/api/ai/*`): prompts, provider fallback, content guards and token
/// charging all live server-side. This client only forwards the request with
/// the user's JWT and maps the backend response into the app's models. No
/// third-party AI keys exist in the client.
class AiService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'corehealth_jwt';

  // In-memory insight cache: profileHash → (insights, timestamp)
  static const _cacheTtl = Duration(hours: 6);
  final Map<String, _InsightCache> _insightCache = {};
  // In-memory plan cache: không expire — bị xóa khi profile thay đổi
  final Map<String, List<MealPlanDay>> _mealPlanCache = {};
  final Map<String, List<WorkoutDay>> _workoutPlanCache = {};

  bool get hasApiKey => true;

  // ---------------------------------------------------------------------------
  // Backend transport
  // ---------------------------------------------------------------------------

  Future<String?> _token() => _storage.read(key: _tokenKey);

  Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    final res = await http
        .post(
          Uri.parse('${EnvironmentConfig.apiBaseUrl}$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Future<dynamic> _get(String path) async {
    final res = await http
        .get(
          Uri.parse('${EnvironmentConfig.apiBaseUrl}$path'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  String _todayIso() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Insights  →  GET /api/ai/insights
  // ---------------------------------------------------------------------------

  Future<List<InsightItem>> generateInsights(DemoProfile profile) async {
    final cacheKey = _profileHash(profile);
    final cached = _insightCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return cached.insights;
    }
    try {
      final data = await _get('/ai/insights');
      final list = data is List ? data : const [];
      if (list.isEmpty) return const [];
      final insights = list.map((e) {
        final m = e as Map<String, dynamic>;
        return InsightItem(
          title: m['title'] as String? ?? '',
          message: m['message'] as String? ?? '',
          accent: m['accent'] as String? ?? 'emerald',
        );
      }).toList();
      _insightCache[cacheKey] = _InsightCache(insights, DateTime.now());
      return insights;
    } catch (e) {
      debugPrint('AI insights error: $e');
      return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // Coach chat  →  POST /api/ai/chat
  // ---------------------------------------------------------------------------

  Future<String> chat({
    required String userMessage,
    required DemoProfile profile,
    required List<ChatMessage> history,
    required CoachType coachType,
  }) async {
    final recent =
        history.length > 8 ? history.sublist(history.length - 8) : history;
    final historyJson = recent
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();
    try {
      final json = await _post('/ai/chat', {
        'message': userMessage,
        'coachType': coachType.name,
        'history': historyJson,
      });
      return (json['message'] as String?)?.trim() ?? '';
    } catch (e) {
      debugPrint('AI chat error: $e');
      return 'Lỗi kết nối AI: $e';
    }
  }

  void invalidateCache(DemoProfile profile) {
    final key = _profileHash(profile);
    _insightCache.remove(key);
    _mealPlanCache.remove(key);
    _workoutPlanCache.remove('w_$key');
  }

  void invalidateAllPlanCaches() {
    _mealPlanCache.clear();
    _workoutPlanCache.clear();
  }

  // ---------------------------------------------------------------------------
  // Plan generation  →  POST /api/ai/generate-plan
  // ---------------------------------------------------------------------------

  Future<List<MealPlanDay>> generateMealPlan(DemoProfile profile) async {
    final key = _profileHash(profile);
    if (_mealPlanCache.containsKey(key)) return _mealPlanCache[key]!;
    try {
      final json = await _post('/ai/generate-plan', {
        'type': 'meal',
        'duration': 7,
        'goal': profile.goal.name,
        'intensity': profile.activityLevel.name,
        'notes': '',
        'startDate': _todayIso(),
      });
      final result = _parseBeMealPlan(json['mealPlan']);
      if (result.isEmpty) return const [];
      _mealPlanCache[key] = result;
      return result;
    } catch (e) {
      debugPrint('AI meal plan error: $e');
      return const [];
    }
  }

  Future<List<WorkoutDay>> generateWorkoutPlan(DemoProfile profile) async {
    final key = 'w_${_profileHash(profile)}';
    if (_workoutPlanCache.containsKey(key)) return _workoutPlanCache[key]!;
    try {
      final json = await _post('/ai/generate-plan', {
        'type': 'workout',
        'duration': 7,
        'goal': profile.goal.name,
        'intensity': profile.activityLevel.name,
        'notes': '',
        'startDate': _todayIso(),
      });
      final result = _parseBeWorkoutPlan(json['workoutPlan']);
      if (result.isEmpty) return const [];
      _workoutPlanCache[key] = result;
      return result;
    } catch (e) {
      debugPrint('AI workout plan error: $e');
      return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // Backend response parsers (BE shapes from AiProxyService)
  // ---------------------------------------------------------------------------

  // BE meal day: {day, label, calories, totalProtein, totalCarbs, totalFat,
  //               meals:[{slot, name, kcal, protein, carbs, fat, details}]}
  List<MealPlanDay> _parseBeMealPlan(Object? raw) {
    if (raw is! List) return [];
    return raw.asMap().entries.map((dayEntry) {
      final day = dayEntry.value as Map<String, dynamic>;
      final meals = (day['meals'] as List? ?? []).asMap().entries.map((mEntry) {
        final m = mEntry.value as Map<String, dynamic>;
        final details = m['details'] as String? ?? '';
        return MealItem(
          id: 'ai_d${dayEntry.key}_m${mEntry.key}',
          nameVi: m['name'] as String? ?? '',
          slotLabel: m['slot'] as String? ?? '',
          calories: (m['kcal'] as num? ?? 0).toInt(),
          protein: (m['protein'] as num? ?? 0).toInt(),
          carbs: (m['carbs'] as num? ?? 0).toInt(),
          fat: (m['fat'] as num? ?? 0).toInt(),
          imageUrl: '',
          ingredients: details.isEmpty ? const [] : [details],
        );
      }).toList();
      return MealPlanDay(
        dayNumber: (day['day'] as num? ?? dayEntry.key + 1).toInt(),
        meals: meals,
      );
    }).toList();
  }

  // BE workout day: {day, title, focus, duration, intensity,
  //                  exercises:[String...], caloriesEst, notes}
  List<WorkoutDay> _parseBeWorkoutPlan(Object? raw) {
    if (raw is! List) return [];
    return raw.asMap().entries.map((dayEntry) {
      final day = dayEntry.value as Map<String, dynamic>;
      final rawExercises = day['exercises'] as List? ?? [];
      final calEst = (day['caloriesEst'] as num? ?? 0).toInt();
      final perEx =
          rawExercises.isEmpty ? 0 : (calEst / rawExercises.length).round();
      final exercises = rawExercises.asMap().entries.map((eEntry) {
        return WorkoutExercise(
          id: 'ai_d${dayEntry.key}_e${eEntry.key}',
          nameVi: eEntry.value.toString(),
          description: '',
          caloriesBurned: perEx,
        );
      }).toList();
      return WorkoutDay(
        dayNumber: (day['day'] as num? ?? dayEntry.key + 1).toInt(),
        focusVi: day['focus'] as String? ?? day['title'] as String? ?? '',
        exercises: exercises,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _profileHash(DemoProfile p) =>
      '${p.name}_${p.weightKg}_${p.targetWeightKg}_${p.goal.name}_${p.activityLevel.name}'
      '_${p.trainingFrequency}_${p.focusAreas.join(',')}_${p.preferredActivities.join(',')}'
      '_${p.mealBudget}_${p.cookingTime}_${p.nutritionPriorities.join(',')}'
      '_${p.allergies.join(',')}_${p.dietaryRestrictions.join(',')}_${p.healthConditions.join(',')}';
}

class _InsightCache {
  final List<InsightItem> insights;
  final DateTime timestamp;
  _InsightCache(this.insights, this.timestamp);
}
