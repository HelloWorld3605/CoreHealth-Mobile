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

  /// Must be called once after construction to load persisted JWT.
  Future<void> init() async {
    _token = await _storage.read(key: _tokenKey);
  }

  @override
  Future<AppBootstrapData> bootstrap() async {
    if (_token == null || _token!.isEmpty) return const AppBootstrapData();
    final json = await _request('GET', '/me/bootstrap');
    return AppBootstrapData(
      session: _session(json['session'] as Map<String, dynamic>?),
      userData: _userData(json['userData'] as Map<String, dynamic>),
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
    final json = await _request('POST', '/me/subscription', {
      'plan': plan.name,
      'months': months,
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
    try {
      final json = await _request('POST', '/me/token-wallet', {
        'tokenBalance': tokenBalance,
        'tokenEarned': tokenEarned,
        'tokenSpent': tokenSpent,
      });
      return _userData(json);
    } on AppAuthException {
      final bootstrap = await this.bootstrap();
      final userData = bootstrap.userData;
      if (userData == null) rethrow;
      return userData;
    }
  }

  @override
  Future<PersistedUserData> updateUserSettings({
    required String userId,
    required UserSettings settings,
  }) async {
    try {
      final json = await _request('POST', '/me/settings', {
        'settings': _settingsToJson(settings),
      });
      return _userData(json).copyWith(settings: settings);
    } on AppAuthException {
      final bootstrap = await this.bootstrap();
      final userData = bootstrap.userData;
      if (userData == null) rethrow;
      return userData.copyWith(settings: settings);
    }
  }

  @override
  Future<List<TokenTransaction>> getTokenTransactions({
    required String userId,
  }) async {
    final data = await _request('GET', '/me/token-transactions');
    return _list(data).map(_tokenTransaction).toList(growable: false);
  }

  @override
  Future<void> addTokenTransaction({
    required String userId,
    required TokenTransaction transaction,
  }) async {
    await _request('POST', '/me/token-transactions', {
      'id': transaction.id,
      'amount': transaction.amount,
      'priceK': transaction.priceK,
      'description': transaction.description,
      'createdAt': transaction.createdAt.toIso8601String(),
    });
  }

  Future<PersistedUserData> purchaseTokenPack({
    required TokenPack pack,
  }) async {
    final json = await _request(
      'POST',
      '/billing/token-packs/${pack.idValue}/purchase',
    );
    final walletBalance = _readInt(json, 'walletBalance', pack.tokens);
    final bootstrap = await this.bootstrap();
    final current = bootstrap.userData;
    if (current == null) {
      return PersistedUserData(
        profile: DemoProfile(
          name: 'CoreHealth User',
          age: 28,
          gender: Gender.other,
          heightCm: 168,
          weightKg: 65,
          targetWeightKg: 62,
          goal: GoalType.maintain,
          activityLevel: ActivityLevel.moderate,
          schedule: '',
          dietaryRestrictions: const [],
          allergies: const [],
          healthConditions: const [],
          plan: SubscriptionPlan.free,
          subscriptionMonths: 0,
          tokenBalance: walletBalance,
          tokenEarned: walletBalance,
        ),
        weightHistory: const [],
        completedWorkoutDays: const {},
        completedMealDays: const {},
        cart: const [],
        orders: const [],
      );
    }
    return current.copyWith(
      profile: current.profile.copyWith(
        tokenBalance: walletBalance,
        tokenEarned: current.profile.tokenEarned + pack.tokens,
      ),
    );
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

  @override
  Future<List<ChatSession>> getChatSessions({required String userId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveChatSession(
      {required String userId, required ChatSession session}) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteChatSession(
      {required String userId, required String sessionId}) {
    throw UnimplementedError();
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

  Map<String, Object?> _settingsToJson(UserSettings settings) => {
        'waterReminderEnabled': settings.waterReminderEnabled,
        'workoutReminderEnabled': settings.workoutReminderEnabled,
        'weeklyWeightReminderEnabled': settings.weeklyWeightReminderEnabled,
        'language': settings.language,
      };

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
      description: json['description'] as String? ?? '',
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

  List<String> _stringList(Object? value) =>
      _list(value).map((e) => e.toString()).toList();

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
