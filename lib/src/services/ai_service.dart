import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../demo_data.dart';
import '../models.dart';
import 'rag_service.dart';

class AiService {
  // Build: flutter run --dart-define=BEEKNOEE_API_KEY=sk-bee-xxxxx
  static const _apiKey = String.fromEnvironment(
    'BEEKNOEE_API_KEY',
    defaultValue: '',
  );
  static const _baseUrl = 'https://platform.beeknoee.com';
  static const _model = 'openai/gpt-oss-120b';

  // Cycle qua các ảnh có sẵn cho bữa ăn AI-generated
  static const _mealImages = [
    DemoData.heroFood,
    DemoData.bowlPhoto,
    DemoData.heroFood,
    DemoData.bowlPhoto,
  ];

  // In-memory insight cache: profileHash → (insights, timestamp)
  static const _cacheTtl = Duration(hours: 6);
  final Map<String, _InsightCache> _insightCache = {};
  // In-memory plan cache: không expire — bị xóa khi profile thay đổi
  final Map<String, List<MealPlanDay>> _mealPlanCache = {};
  final Map<String, List<WorkoutDay>> _workoutPlanCache = {};

  final _rag = RagService();

  bool get hasApiKey => _apiKey.isNotEmpty;

  Future<List<InsightItem>> generateInsights(DemoProfile profile) async {
    if (!hasApiKey) return _fallbackInsights();

    final cacheKey = _profileHash(profile);
    final cached = _insightCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return cached.insights;
    }

    final ragCtx = _rag.buildContext(
      userQuery: 'sức khỏe tổng quát BMI mục tiêu ${profile.goal.title}',
      profile: profile,
      coachType: CoachType.wellness,
    );

    final prompt =
        '''Bạn là AI sức khỏe cá nhân. Phân tích hồ sơ và tạo 3 insight ngắn bằng tiếng Việt.

Hồ sơ:
- ${profile.name}, ${profile.age} tuổi, ${profile.gender.title}
- Cao ${profile.heightCm}cm, nặng ${profile.weightKg}kg (mục tiêu: ${profile.targetWeightKg}kg)
- BMI: ${profile.bmi.toStringAsFixed(1)}, Mục tiêu: ${profile.goal.title}
- Vận động: ${profile.activityLevel.title}, tần suất: ${profile.trainingFrequency.isEmpty ? profile.schedule : profile.trainingFrequency}
${profile.focusAreas.isNotEmpty ? "- Vùng tập trung: ${profile.focusAreas.join(', ')}" : ""}
${profile.preferredActivities.isNotEmpty ? "- Hoạt động thích: ${profile.preferredActivities.join(', ')}" : ""}
${profile.dietaryRestrictions.isNotEmpty ? "- Kiêng ăn: ${profile.dietaryRestrictions.join(', ')}" : ""}
${profile.nutritionPriorities.isNotEmpty ? "- Ưu tiên meal: ${profile.nutritionPriorities.join(', ')}" : ""}
${profile.mealBudget.isNotEmpty ? "- Ngân sách meal: ${profile.mealBudget}" : ""}
${profile.cookingTime.isNotEmpty ? "- Thời gian nấu: ${profile.cookingTime}" : ""}
${profile.allergies.isNotEmpty ? "- ⚠️ DỊ ỨNG (tuyệt đối tránh): ${profile.allergies.join(', ')}" : ""}
${profile.healthConditions.isNotEmpty ? "- Bệnh án: ${profile.healthConditions.join(', ')}" : ""}

${ragCtx.isNotEmpty ? "$ragCtx\n" : ""}Trả về JSON array, không thêm text nào khác:
[
  {"title":"...","message":"...","accent":"success"},
  {"title":"...","message":"...","accent":"emerald"},
  {"title":"...","message":"...","accent":"violet"}
]
accent chỉ dùng: success, emerald, blue, orange, violet
title ≤ 30 ký tự, message 1-2 câu ngắn''';

    try {
      final text = await _callMessages(
        messages: [
          {'role': 'user', 'content': prompt}
        ],
        maxTokens: 512,
      );
      final insights = _parseInsights(text);
      _insightCache[cacheKey] = _InsightCache(insights, DateTime.now());
      return insights;
    } on _RateLimitException {
      return _fallbackInsights();
    } catch (e) {
      debugPrint('AI insights error: $e');
      return _fallbackInsights();
    }
  }

  Future<String> chat({
    required String userMessage,
    required DemoProfile profile,
    required List<ChatMessage> history,
    required CoachType coachType,
  }) async {
    if (!hasApiKey) {
      return 'AI Coach chưa được kích hoạt. Vui lòng liên hệ hỗ trợ.';
    }

    String ragCtx = '';
    try {
      ragCtx = _rag.buildContext(
        userQuery: userMessage,
        profile: profile,
        coachType: coachType,
      );
    } catch (e) {
      debugPrint('RAG error: $e');
    }

    final role = switch (coachType) {
      CoachType.nutrition => 'chuyên gia dinh dưỡng',
      CoachType.workout => 'huấn luyện viên thể lực',
      CoachType.wellness => 'chuyên gia sức khỏe tổng thể',
    };

    final topicScope = switch (coachType) {
      CoachType.nutrition =>
        'dinh dưỡng, chế độ ăn, thực phẩm, calo, macro, bữa ăn',
      CoachType.workout =>
        'tập luyện, bài tập, lịch tập, cơ bắp, cardio, phục hồi',
      CoachType.wellness =>
        'sức khỏe tổng thể, giấc ngủ, stress, thói quen lành mạnh, cân nặng',
    };

    final system = StringBuffer();
    system
        .writeln('Tên bạn là CoreHealth Coach — $role của ứng dụng CoreHealth. '
            'KHÔNG phải Claude, ChatGPT, hay bất kỳ AI nào khác. '
            'Không bao giờ tự nhận là AI ngôn ngữ.');
    system.writeln('Phạm vi: $topicScope. '
        'Câu hỏi ngoài phạm vi: từ chối lịch sự. '
        'Từ ngữ thô tục/không phù hợp: nhắc nhở lịch sự.');
    system.writeln(
        'Hồ sơ: ${profile.name}, ${profile.age}t, ${profile.gender.title}, '
        '${profile.heightCm}cm, ${profile.weightKg}kg, BMI ${profile.bmi.toStringAsFixed(1)}, '
        'mục tiêu: ${profile.goal.title}, vận động: ${profile.activityLevel.title}.');
    if (profile.trainingFrequency.isNotEmpty) {
      system.writeln('Tần suất tập: ${profile.trainingFrequency}.');
    }
    if (profile.focusAreas.isNotEmpty) {
      system.writeln('Vùng tập trung: ${profile.focusAreas.join(', ')}.');
    }
    if (profile.preferredActivities.isNotEmpty) {
      system.writeln(
          'Hoạt động yêu thích: ${profile.preferredActivities.join(', ')}.');
    }
    if (profile.allergies.isNotEmpty) {
      system
          .writeln('DỊ ỨNG tuyệt đối tránh: ${profile.allergies.join(', ')}.');
    }
    if (profile.dietaryRestrictions.isNotEmpty) {
      system.writeln('Kiêng ăn: ${profile.dietaryRestrictions.join(', ')}.');
    }
    if (profile.nutritionPriorities.isNotEmpty) {
      system
          .writeln('Ưu tiên meal: ${profile.nutritionPriorities.join(', ')}.');
    }
    if (profile.mealBudget.isNotEmpty || profile.cookingTime.isNotEmpty) {
      system.writeln(
          'Meal thực tế: ngân sách ${profile.mealBudget.isEmpty ? 'không rõ' : profile.mealBudget}, thời gian nấu ${profile.cookingTime.isEmpty ? 'không rõ' : profile.cookingTime}.');
    }
    if (profile.healthConditions.isNotEmpty) {
      system.writeln('Bệnh: ${profile.healthConditions.join(', ')}.');
    }
    if (ragCtx.isNotEmpty) {
      final capped =
          ragCtx.length > 800 ? '${ragCtx.substring(0, 800)}…' : ragCtx;
      system.writeln(capped);
    }
    system.writeln(
        'Trả lời tối đa 100 từ, tiếng Việt, KHÔNG dùng markdown (**, *, #). Text thuần.');

    final recentHistory =
        history.length > 6 ? history.sublist(history.length - 6) : history;

    final messages = <Map<String, String>>[
      for (final m in recentHistory)
        {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
      {'role': 'user', 'content': userMessage},
    ];

    try {
      return await _callMessages(
        system: system.toString(),
        messages: messages,
        maxTokens: 400,
      );
    } on _RateLimitException {
      return 'Bạn đang nhắn quá nhanh, vui lòng đợi vài giây rồi thử lại.';
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
  // AI meal plan generation
  // ---------------------------------------------------------------------------

  Future<List<MealPlanDay>> generateMealPlan(DemoProfile profile) async {
    if (!hasApiKey) return [];
    final key = _profileHash(profile);
    if (_mealPlanCache.containsKey(key)) return _mealPlanCache[key]!;

    final targetCal = _targetCalories(profile);
    final parts = <String>[];
    if (profile.allergies.isNotEmpty) {
      parts.add('DỊ ỨNG BẮT BUỘC TRÁNH: ${profile.allergies.join(", ")}');
    }
    if (profile.dietaryRestrictions.isNotEmpty) {
      parts.add('Kiêng ăn: ${profile.dietaryRestrictions.join(", ")}');
    }
    if (profile.nutritionPriorities.isNotEmpty) {
      parts.add('Ưu tiên: ${profile.nutritionPriorities.join(", ")}');
    }
    if (profile.mealBudget.isNotEmpty) {
      parts.add('Ngân sách: ${profile.mealBudget}');
    }
    if (profile.cookingTime.isNotEmpty) {
      parts.add('Thời gian nấu: ${profile.cookingTime}');
    }
    final restrictions =
        parts.isNotEmpty ? parts.map((s) => '- $s').join('\n') : '';

    final prompt =
        '''Tạo thực đơn 7 ngày cho người Việt Nam. CHỈ trả JSON, không text khác.
Thông tin:
- Mục tiêu: ${profile.goal.title}, ${profile.gender.title} ${profile.age} tuổi
- Calo mục tiêu: ~$targetCal kcal/ngày${restrictions.isNotEmpty ? '\n$restrictions' : ''}
Format (7 phần tử, tổng calo/ngày ≈ $targetCal):
[{"day":1,"meals":[{"slot":"🌅 Sáng","name":"...","cal":N,"pro":N,"carb":N,"fat":N,"ing":["...","..."]},{"slot":"☀️ Trưa","name":"...","cal":N,"pro":N,"carb":N,"fat":N,"ing":["...","..."]},{"slot":"🌙 Tối","name":"...","cal":N,"pro":N,"carb":N,"fat":N,"ing":["...","..."]},{"slot":"🍎 Phụ","name":"...","cal":N,"pro":N,"carb":N,"fat":N,"ing":["..."]}]}]
Dùng món Việt Nam quen thuộc, đa dạng từng ngày.''';

    try {
      final text = await _callMessages(
        messages: [
          {'role': 'user', 'content': prompt}
        ],
        maxTokens: 1800,
      );
      final result = _parseMealPlan(text);
      if (result.isNotEmpty) _mealPlanCache[key] = result;
      return result;
    } on _RateLimitException {
      return [];
    } catch (e) {
      debugPrint('AI meal plan error: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // AI workout plan generation
  // ---------------------------------------------------------------------------

  Future<List<WorkoutDay>> generateWorkoutPlan(DemoProfile profile) async {
    if (!hasApiKey) return [];
    final key = 'w_${_profileHash(profile)}';
    if (_workoutPlanCache.containsKey(key)) return _workoutPlanCache[key]!;

    final prompt =
        '''Tạo lịch tập 7 ngày (ngày 7 nghỉ phục hồi). CHỈ trả JSON, không text khác.
Thông tin:
- Mục tiêu: ${profile.goal.title}
- Mức vận động: ${profile.activityLevel.title}
- Tần suất: ${profile.trainingFrequency.isEmpty ? profile.schedule : profile.trainingFrequency}
${profile.focusAreas.isNotEmpty ? "- Vùng cơ thể muốn tập trung: ${profile.focusAreas.join(', ')}" : ""}
${profile.preferredActivities.isNotEmpty ? "- Hoạt động yêu thích: ${profile.preferredActivities.join(', ')}" : ""}
- ${profile.gender.title} ${profile.age} tuổi
Format (7 phần tử):
[{"day":1,"focus":"Toàn thân","exercises":[{"id":"e1","name":"...","desc":"...","sets":3,"reps":"10-15","cal":50},...]},...,{"day":7,"focus":"Nghỉ ngơi & phục hồi","exercises":[]}]
Mỗi ngày 4-5 bài (trừ ngày 7). Đa dạng nhóm cơ. Phù hợp mục tiêu và mức vận động.''';

    try {
      final text = await _callMessages(
        messages: [
          {'role': 'user', 'content': prompt}
        ],
        maxTokens: 1800,
      );
      final result = _parseWorkoutPlan(text);
      if (result.isNotEmpty) _workoutPlanCache[key] = result;
      return result;
    } on _RateLimitException {
      return [];
    } catch (e) {
      debugPrint('AI workout plan error: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Plan parsing helpers
  // ---------------------------------------------------------------------------

  int _targetCalories(DemoProfile profile) {
    final tdee = profile.tdee;
    return switch (profile.goal) {
      GoalType.loseWeight => (tdee * 0.80).round(),
      GoalType.gainMuscle => (tdee * 1.10).round(),
      _ => tdee.round(),
    };
  }

  List<MealPlanDay> _parseMealPlan(String raw) {
    try {
      final start = raw.indexOf('[');
      final end = raw.lastIndexOf(']');
      if (start == -1 || end == -1) return [];
      final list = jsonDecode(raw.substring(start, end + 1)) as List;
      return list.asMap().entries.map((dayEntry) {
        final day = dayEntry.value as Map<String, dynamic>;
        final meals =
            (day['meals'] as List? ?? []).asMap().entries.map((mEntry) {
          final m = mEntry.value as Map<String, dynamic>;
          return MealItem(
            id: 'ai_d${dayEntry.key}_m${mEntry.key}',
            nameVi: m['name'] as String? ?? '',
            slotLabel: m['slot'] as String? ?? '',
            calories: (m['cal'] as num? ?? 0).toInt(),
            protein: (m['pro'] as num? ?? 0).toInt(),
            carbs: (m['carb'] as num? ?? 0).toInt(),
            fat: (m['fat'] as num? ?? 0).toInt(),
            imageUrl: _mealImages[mEntry.key % _mealImages.length],
            ingredients: (m['ing'] as List?)?.cast<String>() ?? [],
          );
        }).toList();
        return MealPlanDay(
          dayNumber: (day['day'] as num? ?? dayEntry.key + 1).toInt(),
          meals: meals,
        );
      }).toList();
    } catch (e) {
      debugPrint('_parseMealPlan error: $e');
      return [];
    }
  }

  List<WorkoutDay> _parseWorkoutPlan(String raw) {
    try {
      final start = raw.indexOf('[');
      final end = raw.lastIndexOf(']');
      if (start == -1 || end == -1) return [];
      final list = jsonDecode(raw.substring(start, end + 1)) as List;
      return list.asMap().entries.map((dayEntry) {
        final day = dayEntry.value as Map<String, dynamic>;
        final exercises =
            (day['exercises'] as List? ?? []).asMap().entries.map((eEntry) {
          final e = eEntry.value as Map<String, dynamic>;
          return WorkoutExercise(
            id: e['id'] as String? ?? 'ai_d${dayEntry.key}_e${eEntry.key}',
            nameVi: e['name'] as String? ?? '',
            description: e['desc'] as String? ?? '',
            sets: (e['sets'] as num?)?.toInt(),
            reps: e['reps'] as String?,
            durationMinutes: (e['duration'] as num?)?.toInt(),
            caloriesBurned: (e['cal'] as num? ?? 50).toInt(),
          );
        }).toList();
        return WorkoutDay(
          dayNumber: (day['day'] as num? ?? dayEntry.key + 1).toInt(),
          focusVi: day['focus'] as String? ?? '',
          exercises: exercises,
        );
      }).toList();
    } catch (e) {
      debugPrint('_parseWorkoutPlan error: $e');
      return [];
    }
  }

  Future<String> _callMessages({
    required List<Map<String, String>> messages,
    required int maxTokens,
    String? system,
  }) async {
    final body = <String, dynamic>{
      'model': _model,
      'max_tokens': maxTokens,
      'messages': messages,
    };
    if (system != null) body['system'] = system;

    final response = await http.post(
      Uri.parse('$_baseUrl/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'User-Agent': 'CoreHealth/1.0',
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 429) {
      throw const _RateLimitException();
    }
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content = json['content'] as List;
    return content.first['text'] as String;
  }

  String _profileHash(DemoProfile p) =>
      '${p.name}_${p.weightKg}_${p.targetWeightKg}_${p.goal.name}_${p.activityLevel.name}'
      '_${p.trainingFrequency}_${p.focusAreas.join(',')}_${p.preferredActivities.join(',')}'
      '_${p.mealBudget}_${p.cookingTime}_${p.nutritionPriorities.join(',')}'
      '_${p.allergies.join(',')}_${p.dietaryRestrictions.join(',')}_${p.healthConditions.join(',')}';

  List<InsightItem> _parseInsights(String raw) {
    try {
      final start = raw.indexOf('[');
      final end = raw.lastIndexOf(']');
      if (start == -1 || end == -1) return _fallbackInsights();
      final list = jsonDecode(raw.substring(start, end + 1)) as List;
      return list
          .map((e) => InsightItem(
                title: e['title'] as String? ?? '',
                message: e['message'] as String? ?? '',
                accent: e['accent'] as String? ?? 'emerald',
              ))
          .toList();
    } catch (_) {
      return _fallbackInsights();
    }
  }

  List<InsightItem> _fallbackInsights() => const [
        InsightItem(
          title: 'Tiếp tục cố lên! 💪',
          message:
              'Duy trì lịch tập và ăn uống đều đặn mỗi ngày để đạt mục tiêu.',
          accent: 'success',
        ),
        InsightItem(
          title: 'Uống đủ nước',
          message: 'Ít nhất 2 lít nước/ngày giúp trao đổi chất tốt hơn.',
          accent: 'emerald',
        ),
        InsightItem(
          title: 'Ngủ đủ giấc',
          message:
              '7-8 tiếng ngủ mỗi đêm là yếu tố quan trọng để phục hồi cơ thể.',
          accent: 'violet',
        ),
      ];
}

class _RateLimitException implements Exception {
  const _RateLimitException();
}

class _InsightCache {
  final List<InsightItem> insights;
  final DateTime timestamp;
  _InsightCache(this.insights, this.timestamp);
}
