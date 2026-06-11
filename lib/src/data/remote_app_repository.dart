import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models.dart';
import 'app_repository.dart';

class RemoteAppRepository implements AppRepository {
  RemoteAppRepository({required String baseUrl, http.Client? client})
      : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  String? _token;

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'corehealth_jwt';
  static const _planDayCount = 30;

  // Shared key that tells the backend to skip the web Turnstile CAPTCHA for this
  // native client (BE: X-Mobile-Captcha-Bypass). Injected at build time via
  // --dart-define=COREHEALTH_MOBILE_CAPTCHA_KEY=... ; empty = header not sent.
  static const _mobileCaptchaKey =
      String.fromEnvironment('COREHEALTH_MOBILE_CAPTCHA_KEY');

  /// Must be called once after construction to load persisted JWT.
  Future<void> init() async {
    _token = await _storage.read(key: _tokenKey);
  }

  @override
  Future<AppBootstrapData> bootstrap() async {
    if (_token == null || _token!.isEmpty) return const AppBootstrapData();
    final json = await _request('GET', '/me/bootstrap');
    final userDataJson = json['userData'] as Map<String, dynamic>;
    final session = _session(json['session'] as Map<String, dynamic>?);
    if (session != null) {
      await _hydrateAiPlansFromBootstrap(
        userId: session.userId,
        aiPlans: userDataJson['aiPlans'],
        profile: userDataJson['profile'],
      );
    }
    return AppBootstrapData(
      session: session,
      userData: _userData(userDataJson),
    );
  }

  @override
  Future<AuthResult> signIn({required String email, required String password}) {
    return _auth('/auth/login', {'email': email, 'password': password});
  }

  @override
  Future<RegisterResponseData> register({
    required String displayName,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final json = await _request(
        'POST',
        '/auth/register',
        {
          'displayName': displayName,
          'email': email,
          'password': password,
          if (referralCode != null && referralCode.isNotEmpty)
            'referralCode': referralCode,
        },
        false);
    return RegisterResponseData(
      success: json['needsVerification'] as bool? ??
          json['success'] as bool? ??
          false,
      email: json['email'] as String? ?? email,
      devOtp: json['devOtp'] as String?,
    );
  }

  @override
  Future<AuthResult> verifyOtp({
    required String email,
    required String otp,
  }) {
    return _auth('/auth/verify-otp', {
      'email': email,
      'otp': otp,
    });
  }

  @override
  Future<RegisterResponseData> resendOtp({
    required String email,
  }) async {
    final json = await _request(
        'POST',
        '/auth/resend-otp',
        {
          'email': email,
        },
        false);
    return RegisterResponseData(
      success: json['sent'] as bool? ?? false,
      email: email,
      devOtp: json['devOtp'] as String?,
    );
  }

  @override
  Future<RegisterResponseData> requestPasswordReset({
    required String email,
  }) async {
    final json = await _request(
      'POST',
      '/auth/forgot-password',
      {'email': email},
      false,
    );
    return RegisterResponseData(
      success: json['sent'] as bool? ?? json['success'] as bool? ?? true,
      email: json['email'] as String? ?? email,
      devOtp: json['devOtp'] as String?,
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _request(
      'POST',
      '/auth/reset-password',
      {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      },
      false,
    );
  }

  @override
  Future<AuthResult> signInWithGoogle({required String idToken}) {
    return _auth('/auth/google', {'credential': idToken});
  }

  @override
  Future<PersistedUserData> saveOnboardingProfile({
    required String userId,
    required DemoProfile profile,
  }) async {
    final json = await _request('PUT', '/me/profile', {
      'profile': _profileToJson(profile),
    });
    return _userData(json);
  }

  @override
  Future<PersistedUserData> updateSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required int months,
  }) async {
    // BE has no /me/subscription route — `plan` is a profile field persisted via
    // PUT /me/profile and surfaced through bootstrap. Read the current profile,
    // apply the new plan/duration, and persist it through the proven path.
    final current = (await bootstrap()).userData;
    if (current == null) {
      throw const AppAuthException('Phiên đăng nhập đã hết hạn.');
    }
    final updated = current.profile.copyWith(
      plan: plan,
      subscriptionMonths: months,
    );
    final json = await _request('PUT', '/me/profile', {
      'profile': _profileToJson(updated),
    });
    return _userData(json);
  }

  @override
  Future<PersistedUserData> updateTokenWallet({
    required String userId,
    required int tokenBalance,
    required int tokenEarned,
    required int tokenSpent,
  }) async {
    // The wallet is authoritative server-side (charges, refunds, purchases,
    // bonuses). The client cannot write it, so reconcile against bootstrap.
    final userData = (await bootstrap()).userData;
    if (userData == null) {
      throw const AppAuthException('Phiên đăng nhập đã hết hạn.');
    }
    return userData;
  }

  @override
  Future<PersistedUserData> updateUserSettings({
    required String userId,
    required UserSettings settings,
  }) async {
    // BE preferences use a different shape ({notifications, units}) and return a
    // preferences map, NOT userData — parsing it as userData would clobber state.
    // Persist the notification toggles best-effort, then reflect the chosen
    // settings on top of fresh user data. `language` stays client-side.
    try {
      await _request('PUT', '/me/preferences', {
        'notifications': {
          'waterReminders': settings.waterReminderEnabled,
          'workoutReminders': settings.workoutReminderEnabled,
          'weeklyWeightReminders': settings.weeklyWeightReminderEnabled,
        },
      });
    } on AppAuthException {
      // Best-effort persistence — fall through to reflect settings locally.
    }
    final userData = (await bootstrap()).userData;
    if (userData == null) {
      throw const AppAuthException('Phiên đăng nhập đã hết hạn.');
    }
    return userData.copyWith(settings: settings);
  }

  @override
  Future<List<TokenTransaction>> getTokenTransactions({
    required String userId,
  }) async {
    // Token ledger lives under the wallet overview (recentTransactions, 20).
    final data = await _request('GET', '/me/wallet');
    final list = data is Map<String, dynamic>
        ? _list(data['recentTransactions'])
        : const <dynamic>[];
    return list.map(_tokenTransaction).toList(growable: false);
  }

  @override
  Future<void> addTokenTransaction({
    required String userId,
    required TokenTransaction transaction,
  }) async {
    // No-op: the ledger is written server-side when the wallet is charged,
    // refunded, or topped up. The client must not author ledger entries.
  }

  @override
  Future<PersistedUserData> updateWeight({
    required String userId,
    required double weight,
  }) async {
    final json = await _request('POST', '/me/weight', {'weight': weight});
    return _userData(json);
  }

  @override
  Future<PersistedUserData> toggleWorkoutCompleted({
    required String userId,
    required int dayNumber,
  }) async {
    final json = await _request('POST', '/me/workouts/toggle', {
      'dayNumber': dayNumber,
    });
    return _userData(json);
  }

  @override
  Future<PersistedUserData> toggleMealCompleted({
    required String userId,
    required int dayNumber,
  }) async {
    final json = await _request('POST', '/me/meals/toggle', {
      'dayNumber': dayNumber,
    });
    return _userData(json);
  }

  @override
  Future<PersistedUserData> addToCart({
    required String userId,
    required Product product,
  }) async {
    final json = await _request('POST', '/cart/items', {
      'product': _productToJson(product),
    });
    return _userData(json);
  }

  @override
  Future<PersistedUserData> removeCartItem({
    required String userId,
    required String productId,
  }) async {
    final json = await _request('DELETE', '/cart/items/$productId');
    return _userData(json);
  }

  @override
  Future<PersistedUserData> clearCart({required String userId}) async {
    final json = await _request('DELETE', '/cart');
    return _userData(json);
  }

  @override
  Future<PersistedUserData> placeOrder({required String userId}) async {
    final json = await _request('POST', '/orders');
    return _userData(json);
  }

  @override
  Future<PersistedUserData> placeOrderItems({
    required String userId,
    required Set<String> productIds,
  }) async {
    final json = await _request('POST', '/orders', {
      'productIds': productIds.toList(growable: false),
    });
    return _userData(json);
  }

  @override
  Future<PaymentOrder> createShopPaymentOrder({
    required String userId,
    required List<Product> items,
    required String deliveryName,
    required String deliveryPhone,
    required String deliveryAddress,
    String? deliveryEmail,
    String? wardCode,
    int? districtId,
    String? voucherCode,
  }) async {
    final itemCounts = <String, int>{};
    for (final item in items) {
      itemCounts[item.id] = (itemCounts[item.id] ?? 0) + 1;
    }
    final amountVnd =
        items.fold<int>(0, (sum, item) => sum + (item.priceK * 1000));
    final json = await _request('POST', '/payments/create-order', {
      'deliveryName': deliveryName,
      'deliveryPhone': deliveryPhone,
      'deliveryAddress': deliveryAddress,
      'wardCode': wardCode ?? '',
      'districtId': districtId,
      'deliveryEmail': deliveryEmail ?? '',
      'voucherCode': voucherCode,
      'discountVnd': 0,
      'amountVnd': amountVnd,
      'shippingFee': 0,
      'items': itemCounts.entries
          .map((entry) => {'id': entry.key, 'qty': entry.value})
          .toList(growable: false),
    });
    return PaymentOrder.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<PaymentOrder> createTokenTopupOrder({
    required String userId,
    required TokenPack pack,
  }) async {
    final json = await _request(
      'POST',
      '/billing/token-packs/${pack.idValue}/sepay',
    );
    return PaymentOrder.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> insertMealLog({required String userId, required MealLog log}) {
    return _request('POST', '/me/meal-logs', {
      'id': log.id,
      'slotLabel': log.slotLabel,
      'foodName': log.foodName,
      'calories': log.calories,
      'protein': log.protein,
      'carbs': log.carbs,
      'fat': log.fat,
      'loggedAt': log.loggedAt.toIso8601String(),
    }).then((_) {});
  }

  @override
  Future<List<MealLog>> getMealLogsForDate({
    required String userId,
    required String date,
  }) async {
    final data = await _request('GET', '/me/meal-logs?date=$date');
    return (data as List<dynamic>)
        .map((item) => _mealLog(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteMealLog({required String userId, required String logId}) {
    return _request('DELETE', '/me/meal-logs/$logId').then((_) {});
  }

  @override
  Future<void> signOut() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  // --- Chat sessions: server-synced via /me/chat-sessions + bootstrap ---

  @override
  Future<List<ChatSession>> getChatSessions({required String userId}) async {
    final data = await _request('GET', '/me/chat-sessions');
    return _list(data)
        .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveChatSession({
    required String userId,
    required ChatSession session,
  }) async {
    // BE persists the full session list; upsert by id then send the whole set.
    final existing = await getChatSessions(userId: userId);
    final next = <ChatSession>[
      session,
      ...existing.where((s) => s.id != session.id),
    ];
    await _request('POST', '/me/chat-sessions', {
      'sessions': next.map((s) => s.toJson()).toList(),
    });
  }

  @override
  Future<void> deleteChatSession({
    required String userId,
    required String sessionId,
  }) async {
    final existing = await getChatSessions(userId: userId);
    await _request('POST', '/me/chat-sessions', {
      'sessions': existing
          .where((s) => s.id != sessionId)
          .map((s) => s.toJson())
          .toList(),
    });
  }

  // --- AI plans / shopping / progress: device-local (secure storage) ---
  // BE stores plans as a single blob without version/dayIndex granularity, so
  // per-day reads are cached locally. Plans are still GENERATED server-side via
  // /api/ai/generate-plan (no client AI keys); only the per-day cache is local.
  // Keyed by (userId, dayIndex|date) — the app always renders the current plan.

  Future<void> _writeLocal(String key, Object? value) =>
      _storage.write(key: key, value: jsonEncode(value));

  Future<Map<String, dynamic>?> _readLocalMap(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<List<dynamic>> _readLocalList(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    return decoded is List ? decoded : const [];
  }

  @override
  Future<void> savePlanGeneration({
    required String userId,
    required PlanGeneration generation,
  }) =>
      _writeLocal('chg_gen_$userId', generation.toJson());

  @override
  Future<PlanGeneration?> getCurrentGeneration({required String userId}) async {
    final map = await _readLocalMap('chg_gen_$userId');
    return map == null ? null : PlanGeneration.fromJson(map);
  }

  @override
  Future<void> saveMealPlan({
    required String userId,
    required String generationId,
    required int dayIndex,
    required MealPlanDay plan,
  }) async {
    await _writeLocal('chg_meal_${userId}_$dayIndex', plan.toJson());
    if (dayIndex >= _planDayCount) {
      await _syncAiPlans(userId);
    }
  }

  @override
  Future<MealPlanDay?> getMealPlan({
    required String userId,
    required int version,
    required int dayIndex,
  }) async {
    final map = await _readLocalMap('chg_meal_${userId}_$dayIndex');
    return map == null ? null : MealPlanDay.fromJson(map);
  }

  @override
  Future<void> saveWorkoutPlan({
    required String userId,
    required String generationId,
    required int dayIndex,
    required WorkoutDay plan,
  }) async {
    await _writeLocal('chg_wk_${userId}_$dayIndex', plan.toJson());
    if (dayIndex >= _planDayCount) {
      await _syncAiPlans(userId);
    }
  }

  @override
  Future<WorkoutDay?> getWorkoutPlan({
    required String userId,
    required int version,
    required int dayIndex,
  }) async {
    final map = await _readLocalMap('chg_wk_${userId}_$dayIndex');
    return map == null ? null : WorkoutDay.fromJson(map);
  }

  @override
  Future<void> saveShoppingItems({
    required String userId,
    required List<ShoppingItem> items,
  }) =>
      _writeLocal('chg_shop_$userId', items.map((e) => e.toJson()).toList());

  @override
  Future<List<ShoppingItem>> getShoppingItems({required String userId}) async {
    final list = await _readLocalList('chg_shop_$userId');
    return list
        .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveDailyProgress({
    required String userId,
    required DailyProgress progress,
  }) =>
      _writeLocal('chg_prog_${userId}_${progress.date}', progress.toJson());

  @override
  Future<DailyProgress?> getDailyProgress({
    required String userId,
    required String date,
  }) async {
    final map = await _readLocalMap('chg_prog_${userId}_$date');
    return map == null ? null : DailyProgress.fromJson(map);
  }

  @override
  Future<void> logAiEvent(
      {required String userId, required AiEvent event}) async {
    // No-op: AI usage is audited server-side on each /api/ai/* call.
  }

  Future<void> _hydrateAiPlansFromBootstrap({
    required String userId,
    required Object? aiPlans,
    required Object? profile,
  }) async {
    if (aiPlans is! Map<String, dynamic>) {
      await _clearLocalPlans(userId);
      return;
    }

    final mealPlans = _parseMealPlanList(aiPlans['mealPlan']);
    final workoutPlans = _parseWorkoutPlanList(aiPlans['workoutPlan']);
    if (mealPlans.isEmpty && workoutPlans.isEmpty) {
      await _clearLocalPlans(userId);
      return;
    }

    final version = profile is Map<String, dynamic>
        ? _readInt(profile, 'aiPlanVersion', 1)
        : 1;
    await _writeLocal(
      'chg_gen_$userId',
      PlanGeneration(
        id: 'be_${userId}_$version',
        userId: userId,
        version: version,
        goalSnapshot: 'Backend aiPlans',
        createdAt: DateTime.now(),
      ).toJson(),
    );
    for (final plan in mealPlans) {
      await _writeLocal('chg_meal_${userId}_${plan.dayNumber}', plan.toJson());
    }
    for (final plan in workoutPlans) {
      await _writeLocal('chg_wk_${userId}_${plan.dayNumber}', plan.toJson());
    }
  }

  Future<void> _clearLocalPlans(String userId) async {
    await _storage.delete(key: 'chg_gen_$userId');
    for (var day = 1; day <= _planDayCount; day += 1) {
      await _storage.delete(key: 'chg_meal_${userId}_$day');
      await _storage.delete(key: 'chg_wk_${userId}_$day');
    }
  }

  Future<void> _syncAiPlans(String userId) async {
    final mealPlans = <Map<String, dynamic>>[];
    final workoutPlans = <Map<String, dynamic>>[];
    for (var day = 1; day <= _planDayCount; day += 1) {
      final meal = await getMealPlan(userId: userId, version: 1, dayIndex: day);
      if (meal != null) mealPlans.add(meal.toJson());
      final workout =
          await getWorkoutPlan(userId: userId, version: 1, dayIndex: day);
      if (workout != null) workoutPlans.add(workout.toJson());
    }

    final json = await _request('POST', '/me/ai-plans', {
      'mealPlan': mealPlans.isEmpty ? null : mealPlans,
      'workoutPlan': workoutPlans.isEmpty ? null : workoutPlans,
      'mealPlanStartDate': null,
      'workoutPlanStartDate': null,
    });
    await _hydrateAiPlansFromBootstrap(
      userId: userId,
      aiPlans: json is Map<String, dynamic> ? json['aiPlans'] : null,
      profile: json is Map<String, dynamic> ? json['profile'] : null,
    );
  }

  List<MealPlanDay> _parseMealPlanList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(_mealPlanDayFromAiPlan)
        .toList(growable: false);
  }

  MealPlanDay _mealPlanDayFromAiPlan(Map<String, dynamic> json) {
    final meals = _list(json['meals'])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    return MealPlanDay(
      dayNumber: _readInt(json, 'dayNumber', _readInt(json, 'day', 1)),
      meals: meals
          .asMap()
          .entries
          .map((entry) => _mealItemFromAiPlan(entry.key, entry.value))
          .toList(growable: false),
    );
  }

  MealItem _mealItemFromAiPlan(int index, Map<String, dynamic> json) {
    return MealItem(
      id: json['id'] as String? ?? 'meal-${index + 1}',
      nameVi: json['nameVi'] as String? ??
          json['name'] as String? ??
          json['title'] as String? ??
          '',
      slotLabel: json['slotLabel'] as String? ?? json['slot'] as String? ?? '',
      calories: _readInt(json, 'calories', _readInt(json, 'kcal', 0)),
      protein: _readInt(json, 'protein', 0),
      carbs: _readInt(json, 'carbs', 0),
      fat: _readInt(json, 'fat', 0),
      imageUrl: json['imageUrl'] as String? ?? '',
      ingredients: _stringList(json['ingredients']).isNotEmpty
          ? _stringList(json['ingredients'])
          : _stringList(json['details']),
    );
  }

  List<WorkoutDay> _parseWorkoutPlanList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(_workoutDayFromAiPlan)
        .toList(growable: false);
  }

  WorkoutDay _workoutDayFromAiPlan(Map<String, dynamic> json) {
    final exercises = _list(json['exercises']);
    return WorkoutDay(
      dayNumber: _readInt(json, 'dayNumber', _readInt(json, 'day', 1)),
      focusVi: json['focusVi'] as String? ??
          json['focus'] as String? ??
          json['title'] as String? ??
          '',
      exercises: exercises
          .asMap()
          .entries
          .map((entry) => _workoutExerciseFromAiPlan(entry.key, entry.value))
          .toList(growable: false),
    );
  }

  WorkoutExercise _workoutExerciseFromAiPlan(int index, Object raw) {
    if (raw is Map<String, dynamic>) {
      return WorkoutExercise(
        id: raw['id'] as String? ?? 'workout-${index + 1}',
        nameVi: raw['nameVi'] as String? ??
            raw['name'] as String? ??
            raw['title'] as String? ??
            '',
        description: raw['description'] as String? ?? '',
        sets: (raw['sets'] as num?)?.toInt(),
        reps: raw['reps']?.toString(),
        durationMinutes: (raw['durationMinutes'] as num?)?.toInt(),
        caloriesBurned: _readInt(raw, 'caloriesBurned',
            _readInt(raw, 'calories', _readInt(raw, 'caloriesEst', 0))),
      );
    }
    return WorkoutExercise(
      id: 'workout-${index + 1}',
      nameVi: raw.toString(),
      description: '',
      caloriesBurned: 0,
    );
  }

  Future<AuthResult> _auth(String path, Map<String, Object?> body) async {
    final json = await _request('POST', path, body, false);
    _token = json['token'] as String?;
    if (_token != null) {
      await _storage.write(key: _tokenKey, value: _token);
    }
    return AuthResult(
      session: _session(json['session'] as Map<String, dynamic>?)!,
      userData: _userData(json['userData'] as Map<String, dynamic>),
    );
  }

  Future<dynamic> _request(
    String method,
    String path, [
    Object? body,
    bool authenticated = true,
  ]) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_mobileCaptchaKey.isNotEmpty) {
      headers['X-Mobile-Captcha-Bypass'] = _mobileCaptchaKey;
    }
    if (authenticated && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    final request = http.Request(method, uri)
      ..headers.addAll(headers)
      ..body = body == null ? '' : jsonEncode(body);
    final streamed =
        await _client.send(request).timeout(const Duration(seconds: 15));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final decoded = _tryDecode(res.body);
      throw AppAuthException(
        decoded is Map && decoded['message'] != null
            ? decoded['message'].toString()
            : 'Máy chủ CoreHealth đang bận.',
      );
    }
    if (res.body.isEmpty) return <String, Object?>{};
    return jsonDecode(res.body);
  }

  AppUserSession? _session(Map<String, dynamic>? json) {
    if (json == null) return null;
    UserStatus status = UserStatus.pendingOnboarding;
    final statusStr = json['status'] as String?;
    if (statusStr != null) {
      status = UserStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => UserStatus.pendingOnboarding,
      );
    } else if (json['onboardingCompleted'] == true) {
      status = UserStatus.active;
    }
    return AppUserSession(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: status,
    );
  }

  PersistedUserData _userData(Map<String, dynamic> json) {
    return PersistedUserData(
      profile: _profile(json['profile'] as Map<String, dynamic>),
      weightHistory: _list(json['weightHistory']).map(_weightEntry).toList(),
      completedWorkoutDays: _list(json['completedWorkoutDays'])
          .map((item) => (item as num).toInt())
          .toSet(),
      completedMealDays: _list(json['completedMealDays'])
          .map((item) => (item as num).toInt())
          .toSet(),
      cart: _list(json['cart']).map(_product).toList(),
      orders: _list(json['orders']).map(_order).toList(),
      settings: _settings(json['settings']),
    );
  }

  UserSettings _settings(Object? value) {
    if (value is! Map<String, dynamic>) return const UserSettings();
    return UserSettings(
      waterReminderEnabled: value['waterReminderEnabled'] as bool? ?? true,
      workoutReminderEnabled: value['workoutReminderEnabled'] as bool? ?? true,
      weeklyWeightReminderEnabled:
          value['weeklyWeightReminderEnabled'] as bool? ?? false,
      language: value['language'] as String? ?? 'Tiếng Việt',
    );
  }

  DemoProfile _profile(Map<String, dynamic> json) {
    final walletTokens = _readInt(json, 'walletTokens',
        _readInt(json, 'walletBalance', _readInt(json, 'tokenBalance', 0)));
    return DemoProfile(
      name: json['name'] as String? ?? 'CoreHealth User',
      age: (json['age'] as num?)?.toInt() ?? 28,
      gender: _enum(Gender.values, json['gender'], Gender.other),
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 168,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 65,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 62,
      goal: _enum(GoalType.values, json['goal'], GoalType.maintain),
      activityLevel: _enum(
          ActivityLevel.values, json['activityLevel'], ActivityLevel.moderate),
      schedule: json['schedule'] as String? ?? '',
      dietaryRestrictions: _stringList(json['dietaryRestrictions']),
      allergies: _stringList(json['allergies']),
      healthConditions: _stringList(json['healthConditions']),
      trainingFrequency: json['trainingFrequency'] as String? ?? '',
      focusAreas: _stringList(json['focusAreas']),
      preferredActivities: _stringList(json['preferredActivities']),
      mealBudget: json['mealBudget'] as String? ?? '',
      cookingTime: json['cookingTime'] as String? ?? '',
      nutritionPriorities: _stringList(json['nutritionPriorities']),
      plan: _enum(SubscriptionPlan.values, json['plan'], SubscriptionPlan.free),
      subscriptionMonths: (json['subscriptionMonths'] as num?)?.toInt() ?? 1,
      tokenBalance: walletTokens,
      tokenEarned: _readInt(json, 'tokenEarned', walletTokens),
      tokenSpent: (json['tokenSpent'] as num?)?.toInt() ?? 0,
      referralCode: json['referralCode'] as String? ?? '',
      referredBy: json['referredBy'] as String? ?? '',
      subscriptionStartDate: json['subscriptionStartDate'] == null
          ? null
          : DateTime.tryParse(json['subscriptionStartDate'].toString()),
      coreHealthMaxTrialExpiresAt: json['coreHealthMaxTrialExpiresAt'] == null
          ? null
          : DateTime.tryParse(
              json['coreHealthMaxTrialExpiresAt'].toString(),
            ),
      survey: FitnessSurvey.fromJson(json),
    );
  }

  Map<String, Object?> _profileToJson(DemoProfile profile) => {
        'name': profile.name,
        'age': profile.age,
        'gender': profile.gender.name,
        'heightCm': profile.heightCm,
        'weightKg': profile.weightKg,
        'targetWeightKg': profile.targetWeightKg,
        'goal': profile.goal.name,
        'activityLevel': profile.activityLevel.name,
        'schedule': profile.schedule,
        'dietaryRestrictions': profile.dietaryRestrictions,
        'allergies': profile.allergies,
        'healthConditions': profile.healthConditions,
        'trainingFrequency': profile.trainingFrequency,
        'focusAreas': profile.focusAreas,
        'preferredActivities': profile.preferredActivities,
        'mealBudget': profile.mealBudget,
        'cookingTime': profile.cookingTime,
        'nutritionPriorities': profile.nutritionPriorities,
        'plan': profile.plan.name,
        'subscriptionMonths': profile.subscriptionMonths,
        'tokenBalance': profile.tokenBalance,
        'tokenEarned': profile.tokenEarned,
        'tokenSpent': profile.tokenSpent,
        'referralCode': profile.referralCode,
        'referredBy': profile.referredBy,
        'subscriptionStartDate':
            profile.subscriptionStartDate?.toIso8601String(),
        'coreHealthMaxTrialExpiresAt':
            profile.coreHealthMaxTrialExpiresAt?.toIso8601String(),
        // Full web-aligned survey schema (same keys/value IDs as CoreHealth-FE)
        // so the BE AI planner reads identical data from web or mobile.
        ...profile.survey.toJson(),
        'onboardingCompletedAt': DateTime.now().toIso8601String(),
      };

  WeightEntry _weightEntry(dynamic item) {
    final json = item as Map<String, dynamic>;
    return WeightEntry(
      label: json['label'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
    );
  }

  Product _product(dynamic item) {
    final json = item as Map<String, dynamic>;
    return Product(
      id: json['id'] as String? ?? '',
      nameVi: json['nameVi'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      priceK: (json['priceK'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      hot: json['hot'] as bool? ?? false,
    );
  }

  Map<String, Object?> _productToJson(Product product) => {
        'id': product.id,
        'nameVi': product.nameVi,
        'categoryId': product.categoryId,
        'unit': product.unit,
        'priceK': product.priceK,
        'imageUrl': product.imageUrl,
        'hot': product.hot,
      };

  OrderSummary _order(dynamic item) {
    final json = item as Map<String, dynamic>;
    return OrderSummary(
      id: json['id'] as String? ?? '',
      dateLabel: json['dateLabel'] as String? ?? '',
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      totalK: (json['totalK'] as num?)?.toInt() ?? 0,
      statusLabel: json['statusLabel'] as String? ?? '',
    );
  }

  MealLog _mealLog(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'] as String? ?? '',
      slotLabel: json['slotLabel'] as String? ?? '',
      foodName: json['foodName'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      loggedAt:
          DateTime.tryParse(json['loggedAt'].toString()) ?? DateTime.now(),
    );
  }

  TokenTransaction _tokenTransaction(dynamic item) {
    final json = item as Map<String, dynamic>;
    return TokenTransaction(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      priceK: _readInt(json, 'priceK', _readInt(json, 'price_k', 0)),
      description:
          json['description'] as String? ?? json['note'] as String? ?? '',
      createdAt: DateTime.tryParse(
            (json['createdAt'] ?? json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  List<dynamic> _list(Object? value) =>
      value is List<dynamic> ? value : const [];

  List<String> _stringList(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return _list(value).map((e) => e.toString()).toList();
  }

  int _readInt(Map<String, dynamic> json, String key, int fallback) {
    final value = json[key];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Object? _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}
