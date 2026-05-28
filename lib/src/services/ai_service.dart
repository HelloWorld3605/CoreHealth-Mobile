import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../demo_data.dart';
import '../models.dart';
import 'gemini_service.dart';
import 'rag_service.dart';

class AiService {
  // API keys are injected at build time via --dart-define (see .env file)
  static const _groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const _groqBaseUrl = 'https://api.groq.com/openai';
  static const _groqModel = 'llama-3.3-70b-versatile';

  static const _beeknoeeApiKey = String.fromEnvironment('BEEKNOEE_API_KEY');
  static const _beeknoeeBaseUrl = 'https://platform.beeknoee.com';
  static const _beeknoeeModel = 'qwen-3-235b-a22b-instruct-2507';

  static const _goLlmApiKey = String.fromEnvironment('GOLLM_API_KEY');
  static const _goLlmBaseUrl = 'https://api.gollm.cloud';
  static const _goLlmModel = 'gpt-4.1';

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

  final _gemini = GeminiService();
  final _rag = RagService();

  bool get hasApiKey =>
      _groqApiKey.isNotEmpty ||
      _beeknoeeApiKey.isNotEmpty ||
      _goLlmApiKey.isNotEmpty ||
      _gemini.isAvailable;

  /// Helper for calling Open AI compatible chat completions endpoints.
  Future<String> _invokeOpenAiCompatible({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    required int maxTokens,
    required bool useSlashCompletions,
  }) async {
    final path = useSlashCompletions ? '/v1/chat/completions' : '/chat/completions';
    final url = Uri.parse('$baseUrl$path');

    final body = {
      'model': model,
      'messages': messages,
      'max_tokens': maxTokens,
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'User-Agent': 'CoreHealth/1.0',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 429) {
      throw const _RateLimitException();
    }
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      return '';
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    if (message == null) {
      return '';
    }
    final text = message['content'] as String? ?? '';
    return text.trim();
  }

  /// AI Chat Completions with standard fallback logic: Groq -> Beeknoee -> GoLLM
  Future<String> _callChatCompletions({
    required String system,
    required String prompt,
    required int maxTokens,
    List<Map<String, String>>? historyMessages,
  }) async {
    // 1. Primary: Groq
    if (_groqApiKey.isNotEmpty) {
      try {
        final messages = <Map<String, String>>[];
        messages.add({'role': 'system', 'content': system});
        if (historyMessages != null) {
          messages.addAll(historyMessages);
        }
        messages.add({'role': 'user', 'content': prompt});

        final text = await _invokeOpenAiCompatible(
          baseUrl: _groqBaseUrl,
          apiKey: _groqApiKey,
          model: _groqModel,
          messages: messages,
          maxTokens: maxTokens,
          useSlashCompletions: true,
        );
        if (text.isNotEmpty) return text;
      } catch (e) {
        debugPrint('[CoreHealth AI] Groq completions failed: $e. Trying Beeknoee...');
      }
    }

    // 2. Fallback 1: Beeknoee
    if (_beeknoeeApiKey.isNotEmpty) {
      try {
        final messages = <Map<String, String>>[];
        messages.add({'role': 'system', 'content': system});
        if (historyMessages != null) {
          messages.addAll(historyMessages);
        }
        messages.add({'role': 'user', 'content': prompt});

        final text = await _invokeOpenAiCompatible(
          baseUrl: _beeknoeeBaseUrl,
          apiKey: _beeknoeeApiKey,
          model: _beeknoeeModel,
          messages: messages,
          maxTokens: maxTokens,
          useSlashCompletions: true,
        );
        if (text.isNotEmpty) return text;
      } catch (e) {
        debugPrint('[CoreHealth AI] Beeknoee completions failed: $e. Trying GoLLM...');
      }
    }

    // 3. Fallback 2: GoLLM
    if (_goLlmApiKey.isNotEmpty) {
      try {
        final messages = <Map<String, String>>[];
        messages.add({'role': 'system', 'content': system});
        if (historyMessages != null) {
          messages.addAll(historyMessages);
        }
        messages.add({'role': 'user', 'content': prompt});

        final text = await _invokeOpenAiCompatible(
          baseUrl: _goLlmBaseUrl,
          apiKey: _goLlmApiKey,
          model: _goLlmModel,
          messages: messages,
          maxTokens: maxTokens,
          useSlashCompletions: false,
        );
        if (text.isNotEmpty) return text;
      } catch (e) {
        debugPrint('[CoreHealth AI] GoLLM completions failed: $e.');
      }
    }

    // 4. Fallback 3: Gemini
    if (_gemini.isAvailable) {
      try {
        final messages = <Map<String, String>>[];
        messages.add({'role': 'system', 'content': system});
        if (historyMessages != null) {
          messages.addAll(historyMessages);
        }
        messages.add({'role': 'user', 'content': prompt});

        final text = await _gemini.chatCompletions(
          messages: messages,
          maxTokens: maxTokens,
        );
        if (text.isNotEmpty) return text;
      } catch (e) {
        debugPrint('[CoreHealth AI] Gemini completions failed: $e.');
      }
    }

    throw Exception('Tất cả các nhà cung cấp dịch vụ AI đều thất bại.');
  }

  String _buildProfileText(DemoProfile profile) {
    final buffer = StringBuffer('=== PROFILE NGƯỜI DÙNG ===\n');
    if (profile.heightCm > 0 && profile.weightKg > 0) {
      buffer.writeln(
        'Cân nặng: ${profile.weightKg.toStringAsFixed(0)}kg | '
        'Chiều cao: ${profile.heightCm.toStringAsFixed(0)}cm | '
        'BMI: ${profile.bmi.toStringAsFixed(1)}'
      );
    }
    if (profile.age > 0) {
      final genderText = profile.gender == Gender.female
          ? 'Nữ'
          : (profile.gender == Gender.male ? 'Nam' : 'Khác');
      buffer.writeln('Tuổi: ${profile.age} | Giới tính: $genderText');
    }
    if (profile.targetWeightKg > 0) {
      buffer.writeln('Mục tiêu cân: ${profile.targetWeightKg.toStringAsFixed(0)}kg');
    }
    final goalText = switch (profile.goal) {
      GoalType.loseWeight => 'Giảm mỡ',
      GoalType.gainMuscle => 'Tăng cơ',
      GoalType.maintain => 'Duy trì vóc dáng',
    };
    buffer.writeln('Mục tiêu: $goalText');

    final activityText = switch (profile.activityLevel) {
      ActivityLevel.sedentary => 'Ít vận động',
      ActivityLevel.light => 'Nhẹ (1-3 buổi/tuần)',
      ActivityLevel.active => 'Tích cực (4-5 buổi/tuần)',
      ActivityLevel.veryActive => 'Rất tích cực',
      ActivityLevel.moderate => 'Vừa phải (3-4 buổi/tuần)',
    };
    buffer.writeln('Mức vận động: $activityText');

    if (profile.allergies.isNotEmpty) {
      buffer.writeln('Dị ứng: ${profile.allergies.join(", ")}');
    }
    if (profile.dietaryRestrictions.isNotEmpty) {
      buffer.writeln('Kiêng ăn: ${profile.dietaryRestrictions.join(", ")}');
    }
    if (profile.healthConditions.isNotEmpty) {
      buffer.writeln('Bệnh án / tình trạng sức khoẻ: ${profile.healthConditions.join(", ")}');
    }
    buffer.writeln('===========================');
    return buffer.toString();
  }

  String _buildTodayPlanContext(DemoProfile profile) {
    final buffer = StringBuffer('\n=== PLAN HÔM NAY ===\n');
    buffer.writeln('Workout plan: ${profile.hasWorkoutPlan ? "CÓ" : "CHƯA TẠO"}');
    buffer.writeln('Meal plan: ${profile.hasMealPlan ? "CÓ" : "CHƯA TẠO"}');

    final targetCal = _targetCalories(profile);
    buffer.writeln('Calo mục tiêu hôm nay: $targetCal kcal');

    final hour = DateTime.now().hour;
    String currentMealContext;
    if (hour < 10) {
      currentMealContext = 'Hiện tại là BUỔI SÁNG. Các bữa còn lại: Sáng, Trưa, Tối, Snack.';
    } else if (hour < 14) {
      currentMealContext = 'Hiện tại là BUỔI TRƯA. Bữa sáng đã qua. Các bữa còn lại: Trưa, Tối, Snack.';
    } else if (hour < 17) {
      currentMealContext = 'Hiện tại là BUỔI CHIỀU. Bữa sáng và trưa đã qua. Các bữa còn lại: Snack, Tối.';
    } else {
      currentMealContext = 'Hiện tại là BUỔI TỐI. Bữa sáng, trưa, snack đã qua. Bữa còn lại: CHỈ CÒN BỮA TỐI.';
    }
    buffer.writeln(currentMealContext);

    buffer.writeln('''
QUY TẮC ĐIỀU CHỈNH THEO THỜI GIAN:
- Nếu user muốn thay đổi bữa CUỐI CÙNG trong ngày (không còn bữa sau): đề xuất bù trừ bằng TĂNG tập luyện hôm nay hoặc GIẢM calo NGÀY MAI. KHÔNG đề xuất đổi bữa đã qua.
- Nếu còn bữa sau: đề xuất giảm calo ở bữa sau để bù.
- Nếu user đã tập xong: đề xuất điều chỉnh bữa ăn (tăng protein phục hồi).
- KHÔNG BAO GIỜ đề xuất thay đổi bữa ĐÃ QUA (đã ăn rồi không thể đổi).
''');
    buffer.writeln('===========================');
    return buffer.toString();
  }

  String _historyText(List<ChatMessage> history) {
    if (history.isEmpty) return '(chưa có)';
    final recent = history.length > 8 ? history.sublist(history.length - 8) : history;
    return recent
        .map((m) => '${m.isUser ? "user" : "assistant"}: ${m.text.trim()}')
        .join('\n');
  }

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
      final text = await _callChatCompletions(
        system: 'Bạn là trợ lý phân tích sức khỏe.',
        prompt: prompt,
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

    const system = '''Bạn là CoreHealth — người bạn am hiểu sức khoẻ, dinh dưỡng và luyện tập, trò chuyện thân thiện với người dùng Việt Nam.
Đọc kỹ profile (cân nặng, chiều cao, tuổi, mục tiêu, bệnh án, dị ứng, kiêng ăn) trước khi trả lời.
Bạn không phải bác sĩ — nếu câu hỏi vượt ngoài dinh dưỡng/luyện tập, nhắc nhẹ nên gặp chuyên gia.

PHONG CÁCH — đây là quy tắc cứng, không được vi phạm:
1. KHÔNG viết mỗi ý một dòng ngắn rời rạc.
2. Viết thành câu đầy đủ, liền mạch như người đang giải thích cho bạn.
3. Giọng ấm, tự nhiên — như nhắn tin cho bạn bè.
4. KHÔNG liệt kê lại thông tin profile ở đầu câu trả lời.
5. Số liệu cụ thể chỉ nêu khi trực tiếp hữu ích.
6. CÁ NHÂN HOÁ: đọc kỹ dị ứng, kiêng ăn, bệnh lý — TUYỆT ĐỐI không gợi ý thực phẩm/bài tập gây hại cho người dùng.
7. Nếu người dùng có bệnh lý (tiểu đường, tim mạch, gout...), phải tránh thực phẩm/bài tập nguy hiểm cho bệnh đó.
Trả lời tiếng Việt, khoảng 2-4 câu hoặc 2-3 gạch đầu dòng đầy đủ — đủ ý, không lan man.

TRẠNG THÁI PLAN:
Profile có 2 cờ: hasMealPlan (true/false), hasWorkoutPlan (true/false).
- Nếu cờ tương ứng = false, NÓI RÕ user chưa có plan đó trước khi đề xuất bất cứ điều chỉnh nào, và mời họ bấm "Tạo bằng AI" ở trang Thực đơn / Lịch tập.
- Nếu cờ = true, được phép đề xuất swap/đổi bài tập/bữa ăn cụ thể, dùng JSON adjustment block.
- Người dùng có thể nói thẳng "đổi bài squat thành deadlift" — bạn PHẢI nhận diện ý đồ swap và emit workoutChanges = [{"exercise":"Deadlift 3x8"}] kèm reason giải thích lý do thay.

QUAN TRỌNG — PHÁT HIỆN ẢNH HƯỞNG ĐẾN PLAN:
Nếu tin nhắn của người dùng MÔ TẢ hành động ảnh hưởng đến lịch ăn/tập hôm nay (ví dụ: muốn ăn món ngoài plan, đã tập xong, bị đau, bỏ bữa, ăn thêm, đổi bài tập...), bạn PHẢI:
1. Phân tích impact (calo thừa/thiếu, cường độ thay đổi)
2. Đề xuất điều chỉnh CÁC BỮA/BÀI TẬP KHÁC (KHÔNG PHẢI món user muốn ăn) để bù trừ
3. GIỮ NGUYÊN món user muốn ăn — chỉ thay đổi các bữa/bài tập KHÁC trong ngày hoặc ngày mai

VÍ DỤ ĐÚNG:
- User: "Tôi muốn ăn gà rán bữa tối" → GIỮ gà rán bữa tối, đề xuất: tập thêm 20 phút cardio HOẶC giảm calo bữa sáng ngày mai
- User: "Tôi muốn ăn phở bữa sáng" → GIỮ phở bữa sáng, đề xuất: giảm carb bữa trưa để bù

VÍ DỤ SAI (KHÔNG ĐƯỢC LÀM):
- User: "Tôi muốn ăn gà rán bữa tối" → ĐỔI gà rán thành salad ← SAI! Phải giữ gà rán!

4. Kết thúc response bằng JSON block (sau dấu ---ADJUSTMENT---) chứa thay đổi cho CẢ ĂN UỐNG VÀ TẬP LUYỆN:
{"type":"both","mealChanges":[{"slot":"Sáng ngày mai","name":"Omelette rau nhẹ","kcal":300,"protein":25,"carbs":20,"fat":8,"details":"Trứng 2 quả + rau xào ít dầu"}],"workoutChanges":[{"exercise":"Cardio nhẹ 15 phút sau ăn tối"}],"reason":"Gà rán ~650 kcal, thừa 250 kcal. Bù: giảm sáng mai + thêm cardio tối nay."}

LƯU Ý FORMAT:
- type PHẢI là "both" (luôn đề xuất cả ăn lẫn tập)
- mealChanges: array các bữa ăn cần thay đổi (bữa KHÁC, không phải bữa user muốn ăn)
- workoutChanges: array bài tập thêm/đổi để bù calo
- Nếu không cần đổi meal thì mealChanges = [], tương tự workoutChanges
- reason: giải thích ngắn gọn

Nếu tin nhắn KHÔNG ảnh hưởng plan (hỏi kiến thức chung, hỏi về supplement...), trả lời bình thường KHÔNG có JSON block.''';

    final profileText = _buildProfileText(profile);
    final todayPlanContext = _buildTodayPlanContext(profile);
    String ragText = '';
    if (ragCtx.isNotEmpty) {
      ragText = '\n=== KIẾN THỨC THAM KHẢO ===\n$ragCtx\n===========================\n';
    }

    final prompt = '$profileText'
        '$todayPlanContext'
        '$ragText'
        '\nLoại coach: ${coachType.name}'
        '\nLịch sử gần đây:\n${_historyText(history)}'
        '\nCâu hỏi mới nhất: $userMessage';

    final historyMessages = <Map<String, String>>[];
    final recentHistory = history.length > 8 ? history.sublist(history.length - 8) : history;
    for (final m in recentHistory) {
      historyMessages.add({
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      });
    }

    try {
      return await _callChatCompletions(
        system: system,
        prompt: prompt,
        maxTokens: 1000,
        historyMessages: historyMessages,
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
      final text = await _callChatCompletions(
        system: 'Bạn là chuyên gia lập thực đơn dinh dưỡng cho người Việt.',
        prompt: prompt,
        maxTokens: 2500,
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
      final text = await _callChatCompletions(
        system: 'Bạn là huấn luyện viên thể thao chuyên nghiệp.',
        prompt: prompt,
        maxTokens: 2500,
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
