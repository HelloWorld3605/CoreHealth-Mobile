import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../demo_data.dart';
import '../models.dart';
import 'app_repository.dart';

class MemoryAppRepository implements AppRepository {
  final Map<String, _MemoryUserRecord> _usersById = {};
  final Map<String, String> _userIdByEmail = {};
  final Map<String, PersistedUserData> _dataByUserId = {};
  final Map<String, _PendingRegistration> _pendingRegistrations = {};
  final Map<String, _PendingPasswordReset> _pendingPasswordResets = {};
  final Map<String, List<MealLog>> _mealLogsByUser = {};
  final Map<String, List<ChatSession>> _chatSessionsByUser = {};
  final Map<String, List<TokenTransaction>> _tokenTransactionsByUser = {};
  String? _currentUserId;

  @override
  Future<AppBootstrapData> bootstrap() async {
    final userId = _currentUserId;
    if (userId == null) {
      return const AppBootstrapData();
    }

    final record = _usersById[userId];
    final data = _dataByUserId[userId];
    if (record == null || data == null) {
      _currentUserId = null;
      return const AppBootstrapData();
    }

    return AppBootstrapData(
      session: AppUserSession(
        userId: record.id,
        email: record.email,
        status: record.status,
      ),
      userData: data,
    );
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final userId = _userIdByEmail[normalizedEmail];
    if (userId == null) {
      throw const AppAuthException('Email hoặc mật khẩu không đúng.');
    }

    final record = _usersById[userId];
    if (record == null ||
        record.passwordHash !=
            _hashPasswordWithSalt(password, record.passwordSalt)) {
      throw const AppAuthException('Email hoặc mật khẩu không đúng.');
    }

    _currentUserId = userId;
    return AuthResult(
      session: AppUserSession(
        userId: record.id,
        email: record.email,
        status: record.status,
      ),
      userData: _dataByUserId[userId]!,
    );
  }

  @override
  Future<RegisterResponseData> register({
    required String displayName,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final normalizedName = displayName.trim();
    final normalizedEmail = _normalizeEmail(email);
    if (_userIdByEmail.containsKey(normalizedEmail)) {
      throw const AppAuthException('Email này đã được đăng ký.');
    }

    if (referralCode != null && referralCode.trim().isNotEmpty) {
      final refUpper = referralCode.trim().toUpperCase();
      String? foundReferrerId;
      for (final entry in _dataByUserId.entries) {
        if (entry.value.profile.referralCode.toUpperCase() == refUpper) {
          foundReferrerId = entry.key;
          break;
        }
      }
      if (foundReferrerId == null) {
        throw const AppAuthException('Mã giới thiệu không hợp lệ.');
      }
    }

    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();

    _pendingRegistrations[normalizedEmail] = _PendingRegistration(
      displayName: normalizedName,
      email: normalizedEmail,
      password: password,
      otp: otp,
      createdAt: DateTime.now(),
      referralCode: referralCode,
    );

    // Offline/debug repository: no real email — OTP is surfaced via devOtp.
    debugPrint('[offline] OTP for $normalizedEmail: $otp');

    return RegisterResponseData(
      success: true,
      email: normalizedEmail,
      devOtp: otp,
    );
  }

  @override
  Future<AuthResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final pending = _pendingRegistrations[normalizedEmail];
    if (pending == null) {
      throw const AppAuthException(
          'Không tìm thấy thông tin đăng ký cho email này. Vui lòng đăng ký lại.');
    }

    if (pending.otp != otp) {
      throw const AppAuthException('Mã xác thực không chính xác.');
    }

    if (DateTime.now().difference(pending.createdAt).inMinutes > 10) {
      _pendingRegistrations.remove(normalizedEmail);
      throw const AppAuthException(
          'Mã xác thực đã hết hạn. Vui lòng đăng ký lại.');
    }

    _pendingRegistrations.remove(normalizedEmail);

    final userId = _generateUserId();
    final myReferralCode = _generateReferralCode(pending.displayName);
    var signupTokens = 25;
    var referrerId = '';

    if (pending.referralCode != null &&
        pending.referralCode!.trim().isNotEmpty) {
      final refUpper = pending.referralCode!.trim().toUpperCase();
      String? foundReferrerId;
      for (final entry in _dataByUserId.entries) {
        if (entry.value.profile.referralCode.toUpperCase() == refUpper) {
          foundReferrerId = entry.key;
          break;
        }
      }
      if (foundReferrerId == null) {
        throw const AppAuthException('Mã giới thiệu không hợp lệ.');
      }
      if (foundReferrerId == userId) {
        throw const AppAuthException(
            'Không thể tự dùng mã giới thiệu của chính mình.');
      }

      signupTokens = 65;
      referrerId = foundReferrerId;

      int count = 0;
      for (final data in _dataByUserId.values) {
        if (data.profile.referredBy == referrerId) {
          count++;
        }
      }
      final nextCount = count + 1;
      if (nextCount > 0 && nextCount % 5 == 0) {
        final referrerData = _dataByUserId[referrerId];
        if (referrerData != null) {
          final bonus = TokenTransaction(
            id: 'txn_${DateTime.now().microsecondsSinceEpoch}_ref_bonus',
            amount: 20,
            priceK: 0,
            description: 'Thưởng mốc giới thiệu bạn bè',
            createdAt: DateTime.now(),
          );
          _addTokenTransactionInMemory(referrerId, bonus);
          _dataByUserId[referrerId] = referrerData.copyWith(
            profile: referrerData.profile.copyWith(
              tokenBalance: referrerData.profile.tokenBalance + 20,
              tokenEarned: referrerData.profile.tokenEarned + 20,
            ),
          );
        }
      }
    }

    final profile = DemoProfile(
      name: pending.displayName,
      age: 0,
      gender: Gender.other,
      heightCm: 0,
      weightKg: 0,
      targetWeightKg: 0,
      goal: GoalType.maintain,
      activityLevel: ActivityLevel.sedentary,
      schedule: '',
      dietaryRestrictions: const [],
      allergies: const [],
      healthConditions: const [],
      trainingFrequency: '',
      focusAreas: const [],
      preferredActivities: const [],
      mealBudget: '',
      cookingTime: '',
      nutritionPriorities: const [],
      plan: SubscriptionPlan.free,
      subscriptionMonths: 0,
      tokenBalance: signupTokens,
      tokenEarned: signupTokens,
      tokenSpent: 0,
      referralCode: myReferralCode,
      referredBy: referrerId,
    );

    final salt = _generateSalt();
    final record = _MemoryUserRecord(
      id: userId,
      email: normalizedEmail,
      passwordHash: _hashPasswordWithSalt(pending.password, salt),
      passwordSalt: salt,
      displayName: pending.displayName,
      status: UserStatus.pendingOnboarding,
    );
    _usersById[userId] = record;
    _userIdByEmail[normalizedEmail] = userId;
    _currentUserId = userId;
    _dataByUserId[userId] = PersistedUserData(
      profile: profile,
      weightHistory: const [],
      completedWorkoutDays: const {},
      completedMealDays: const {},
      cart: const [],
      orders: const [],
    );

    final signupTxn = TokenTransaction(
      id: 'txn_${DateTime.now().microsecondsSinceEpoch}_signup',
      amount: 25,
      priceK: 0,
      description: 'Quà tặng đăng ký mới',
      createdAt: DateTime.now(),
    );
    _addTokenTransactionInMemory(userId, signupTxn);

    if (pending.referralCode?.trim().isNotEmpty == true) {
      final refTxn = TokenTransaction(
        id: 'txn_${DateTime.now().microsecondsSinceEpoch}_ref_bonus_new',
        amount: 40,
        priceK: 0,
        description: 'Quà tặng đăng ký qua mã giới thiệu',
        createdAt: DateTime.now(),
      );
      _addTokenTransactionInMemory(userId, refTxn);
    }

    return AuthResult(
      session: AppUserSession(
        userId: record.id,
        email: record.email,
        status: UserStatus.pendingOnboarding,
      ),
      userData: _dataByUserId[userId]!,
    );
  }

  @override
  Future<RegisterResponseData> resendOtp({
    required String email,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final pending = _pendingRegistrations[normalizedEmail];
    if (pending == null) {
      throw const AppAuthException(
          'Không tìm thấy thông tin đăng ký cho email này. Vui lòng đăng ký lại.');
    }

    final now = DateTime.now();
    if (now.difference(pending.createdAt).inSeconds < 60) {
      throw const AppAuthException(
          'Vui lòng đợi 60 giây trước khi yêu cầu gửi lại mã.');
    }

    final random = Random();
    final newOtp = (100000 + random.nextInt(900000)).toString();

    _pendingRegistrations[normalizedEmail] = _PendingRegistration(
      displayName: pending.displayName,
      email: pending.email,
      password: pending.password,
      otp: newOtp,
      createdAt: now,
      referralCode: pending.referralCode,
    );

    debugPrint('[offline] Resent OTP for $normalizedEmail: $newOtp');

    return RegisterResponseData(
      success: true,
      email: normalizedEmail,
      devOtp: newOtp,
    );
  }

  @override
  Future<RegisterResponseData> requestPasswordReset({
    required String email,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final userId = _userIdByEmail[normalizedEmail];
    if (userId == null) {
      return RegisterResponseData(success: true, email: normalizedEmail);
    }

    final otp = (100000 + Random().nextInt(900000)).toString();
    _pendingPasswordResets[normalizedEmail] = _PendingPasswordReset(
      email: normalizedEmail,
      otp: otp,
      createdAt: DateTime.now(),
    );

    debugPrint('[offline] Password reset OTP for $normalizedEmail: $otp');

    return RegisterResponseData(
      success: true,
      email: normalizedEmail,
      devOtp: otp,
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final pending = _pendingPasswordResets[normalizedEmail];
    if (pending == null) {
      throw const AppAuthException(
          'Mã đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.');
    }
    if (DateTime.now().difference(pending.createdAt).inMinutes > 10) {
      _pendingPasswordResets.remove(normalizedEmail);
      throw const AppAuthException(
          'Mã đặt lại mật khẩu đã hết hạn. Vui lòng gửi lại mã.');
    }
    if (pending.otp != otp.trim()) {
      throw const AppAuthException('Mã OTP không chính xác.');
    }
    final userId = _userIdByEmail[normalizedEmail];
    final record = userId == null ? null : _usersById[userId];
    if (record == null) {
      throw const AppAuthException(
          'Mã đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.');
    }
    final salt = _generateSalt();
    _usersById[userId!] = record.copyWith(
      passwordHash: _hashPasswordWithSalt(newPassword, salt),
      passwordSalt: salt,
    );
    _pendingPasswordResets.remove(normalizedEmail);
  }

  @override
  Future<AuthResult> signInWithGoogle({required String idToken}) async {
    throw const AppAuthException(
        'Đăng nhập Google không được hỗ trợ ở chế độ giả lập.');
  }

  @override
  Future<PersistedUserData> saveOnboardingProfile({
    required String userId,
    required DemoProfile profile,
  }) async {
    final record = _usersById[userId];
    if (record != null) {
      _usersById[userId] = record.copyWith(status: UserStatus.active);
    }

    final updated = PersistedUserData(
      profile: profile,
      weightHistory: _seedWeightHistory(profile),
      completedWorkoutDays: const {},
      completedMealDays: const {},
      cart: _dataByUserId[userId]?.cart ?? const [],
      orders: _dataByUserId[userId]?.orders ?? const [],
      settings: _dataByUserId[userId]?.settings ?? const UserSettings(),
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  @override
  Future<PersistedUserData> updateTokenWallet({
    required String userId,
    required int tokenBalance,
    required int tokenEarned,
    required int tokenSpent,
  }) async {
    final current = _requireUserData(userId);
    final updated = current.copyWith(
      profile: current.profile.copyWith(
        tokenBalance: tokenBalance,
        tokenEarned: tokenEarned,
        tokenSpent: tokenSpent,
      ),
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  @override
  Future<PersistedUserData> updateUserSettings({
    required String userId,
    required UserSettings settings,
  }) async {
    final current = _requireUserData(userId);
    final updated = current.copyWith(settings: settings);
    _dataByUserId[userId] = updated;
    return updated;
  }

  @override
  Future<List<TokenTransaction>> getTokenTransactions({
    required String userId,
  }) async {
    return List<TokenTransaction>.unmodifiable(
      [...(_tokenTransactionsByUser[userId] ?? const <TokenTransaction>[])],
    );
  }

  @override
  Future<void> addTokenTransaction({
    required String userId,
    required TokenTransaction transaction,
  }) async {
    _addTokenTransactionInMemory(userId, transaction);
  }

  @override
  Future<PersistedUserData> updateSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required int months,
  }) async {
    final current = _requireUserData(userId);
    final updated = current.copyWith(
      profile: current.profile.copyWith(
        plan: plan,
        subscriptionMonths: months,
        subscriptionStartDate:
            plan == SubscriptionPlan.free ? null : DateTime.now(),
      ),
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  @override
  Future<PersistedUserData> updateWeight({
    required String userId,
    required double weight,
  }) async {
    final current = _requireUserData(userId);
    final updatedHistory = [
      ...current.weightHistory,
      WeightEntry(label: _formatDayMonth(DateTime.now()), weight: weight),
    ];
    while (updatedHistory.length > 8) {
      updatedHistory.removeAt(0);
    }

    final updated = current.copyWith(
      profile: current.profile.copyWith(weightKg: weight),
      weightHistory: updatedHistory,
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  @override
  Future<PersistedUserData> toggleWorkoutCompleted({
    required String userId,
    required int dayNumber,
  }) async {
    final current = _requireUserData(userId);
    final completedDays = {...current.completedWorkoutDays};
    if (!completedDays.add(dayNumber)) {
      completedDays.remove(dayNumber);
    }

    final updated = current.copyWith(
      completedWorkoutDays: completedDays,
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  @override
  Future<PersistedUserData> toggleMealCompleted({
    required String userId,
    required int dayNumber,
  }) async {
    final current = _requireUserData(userId);
    final completedDays = {...current.completedMealDays};
    if (!completedDays.add(dayNumber)) {
      completedDays.remove(dayNumber);
    }

    final updated = current.copyWith(
      completedMealDays: completedDays,
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  @override
  Future<PersistedUserData> addToCart({
    required String userId,
    required Product product,
  }) async {
    final current = _requireUserData(userId);
    if (current.cart.any((p) => p.id == product.id)) return current;
    final updated = current.copyWith(
      cart: [...current.cart, product],
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  @override
  Future<PersistedUserData> removeCartItem({
    required String userId,
    required String productId,
  }) async {
    final current = _requireUserData(userId);
    final cart = current.cart.where((p) => p.id != productId).toList();
    final updated = current.copyWith(
      cart: cart,
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  @override
  Future<PersistedUserData> clearCart({
    required String userId,
  }) async {
    final current = _requireUserData(userId);
    final updated = current.copyWith(
      cart: const [],
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  @override
  Future<PersistedUserData> placeOrder({
    required String userId,
  }) async {
    final current = _requireUserData(userId);
    if (current.cart.isEmpty) {
      return current;
    }

    final now = DateTime.now();
    final updated = current.copyWith(
      cart: const [],
      orders: [
        OrderSummary(
          id: 'ODR-${now.microsecondsSinceEpoch.toString().substring(9)}',
          dateLabel: _formatDate(now),
          itemCount: current.cart.length,
          totalK: current.cart.fold<int>(0, (sum, item) => sum + item.priceK),
          statusLabel: 'Đang xử lý',
        ),
        ...current.orders,
      ],
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  @override
  Future<PersistedUserData> placeOrderItems({
    required String userId,
    required Set<String> productIds,
  }) async {
    final current = _requireUserData(userId);
    if (productIds.isEmpty) {
      return current;
    }

    final selected = current.cart
        .where((product) => productIds.contains(product.id))
        .toList();
    if (selected.isEmpty) {
      return current;
    }

    final now = DateTime.now();
    final updated = current.copyWith(
      cart: current.cart
          .where((product) => !productIds.contains(product.id))
          .toList(growable: false),
      orders: [
        OrderSummary(
          id: 'ODR-${now.microsecondsSinceEpoch.toString().substring(9)}',
          dateLabel: _formatDate(now),
          itemCount: selected.length,
          totalK: selected.fold<int>(0, (sum, item) => sum + item.priceK),
          statusLabel: 'Đang xử lý',
        ),
        ...current.orders,
      ],
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  @override
  Future<void> signOut() async {
    _currentUserId = null;
  }

  @override
  Future<void> insertMealLog(
      {required String userId, required MealLog log}) async {
    final logs = _mealLogsByUser.putIfAbsent(userId, () => []);
    logs.removeWhere((l) => l.id == log.id);
    logs.add(log);
  }

  @override
  Future<List<MealLog>> getMealLogsForDate({
    required String userId,
    required String date,
  }) async {
    return (_mealLogsByUser[userId] ?? [])
        .where((l) => l.dateKey == date)
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  @override
  Future<void> deleteMealLog(
      {required String userId, required String logId}) async {
    _mealLogsByUser[userId]?.removeWhere((l) => l.id == logId);
  }

  @override
  Future<List<ChatSession>> getChatSessions({required String userId}) async {
    return _chatSessionsByUser[userId] ?? [];
  }

  @override
  Future<void> saveChatSession(
      {required String userId, required ChatSession session}) async {
    final list = _chatSessionsByUser.putIfAbsent(userId, () => []);
    list.removeWhere((s) => s.id == session.id);
    list.add(session);
    list.sort((a, b) => b.ts.compareTo(a.ts));
  }

  @override
  Future<void> deleteChatSession(
      {required String userId, required String sessionId}) async {
    _chatSessionsByUser[userId]?.removeWhere((s) => s.id == sessionId);
  }

  // Architecture V2: AI Synchronization Methods (In-memory stubs)

  @override
  Future<void> savePlanGeneration({required String userId, required PlanGeneration generation}) async {
    // Stub
  }

  @override
  Future<PlanGeneration?> getCurrentGeneration({required String userId}) async {
    return null; // Stub
  }

  @override
  Future<void> saveMealPlan({required String userId, required String generationId, required int dayIndex, required MealPlanDay plan}) async {
    // Stub
  }

  @override
  Future<MealPlanDay?> getMealPlan({required String userId, required int version, required int dayIndex}) async {
    return null; // Stub
  }

  @override
  Future<void> saveWorkoutPlan({required String userId, required String generationId, required int dayIndex, required WorkoutDay plan}) async {
    // Stub
  }

  @override
  Future<WorkoutDay?> getWorkoutPlan({required String userId, required int version, required int dayIndex}) async {
    return null; // Stub
  }

  @override
  Future<void> saveShoppingItems({required String userId, required List<ShoppingItem> items}) async {
    // Stub
  }

  @override
  Future<List<ShoppingItem>> getShoppingItems({required String userId}) async {
    return []; // Stub
  }

  @override
  Future<void> saveDailyProgress({required String userId, required DailyProgress progress}) async {
    // Stub
  }

  @override
  Future<DailyProgress?> getDailyProgress({required String userId, required String date}) async {
    return null; // Stub
  }

  @override
  Future<void> logAiEvent({required String userId, required AiEvent event}) async {
    // Stub
  }

  PersistedUserData _requireUserData(String userId) {
    final data = _dataByUserId[userId];
    if (data == null) {
      throw StateError('User data not found for $userId');
    }
    return data;
  }

  void _addTokenTransactionInMemory(
    String userId,
    TokenTransaction transaction,
  ) {
    final list = _tokenTransactionsByUser.putIfAbsent(userId, () => []);
    list.removeWhere((item) => item.id == transaction.id);
    list.add(transaction);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

class _MemoryUserRecord {
  const _MemoryUserRecord({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    required this.displayName,
    required this.status,
  });

  final String id;
  final String email;
  final String passwordHash;
  final String passwordSalt;
  final String displayName;
  final UserStatus status;

  _MemoryUserRecord copyWith({
    UserStatus? status,
    String? passwordHash,
    String? passwordSalt,
  }) {
    return _MemoryUserRecord(
      id: id,
      email: email,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      displayName: displayName,
      status: status ?? this.status,
    );
  }
}

class _PendingRegistration {
  const _PendingRegistration({
    required this.displayName,
    required this.email,
    required this.password,
    required this.otp,
    required this.createdAt,
    this.referralCode,
  });

  final String displayName;
  final String email;
  final String password;
  final String otp;
  final DateTime createdAt;
  final String? referralCode;
}

class _PendingPasswordReset {
  const _PendingPasswordReset({
    required this.email,
    required this.otp,
    required this.createdAt,
  });

  final String email;
  final String otp;
  final DateTime createdAt;
}

DemoProfile _defaultProfileFor(String displayName) {
  return DemoData.initialProfile.copyWith(
    name: displayName,
    plan: SubscriptionPlan.free,
    subscriptionMonths: 0,
    tokenBalance: 0,
    tokenEarned: 0,
    tokenSpent: 0,
  );
}

List<WeightEntry> _seedWeightHistory(DemoProfile profile) {
  final current = profile.weightKg;
  final values = [
    current + 2.1,
    current + 1.7,
    current + 1.2,
    current + 0.8,
    current + 0.4,
    current + 0.2,
    current,
  ];
  final today = DateTime.now();

  return List.generate(values.length, (index) {
    final date = today.subtract(Duration(days: values.length - index - 1));
    return WeightEntry(
      label: _formatDayMonth(date),
      weight: double.parse(values[index].toStringAsFixed(1)),
    );
  });
}

String _formatDayMonth(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String _formatDate(DateTime value) {
  return '${_formatDayMonth(value)}/${value.year}';
}

String _normalizeEmail(String value) => value.trim().toLowerCase();

String _generateReferralCode(String name) {
  final cleanName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  final prefix = cleanName.length > 8
      ? cleanName.substring(0, 8)
      : (cleanName.isEmpty ? 'CORE' : cleanName);
  final rng = Random();
  final suffix = rng.nextInt(900000) + 100000;
  return '$prefix-$suffix';
}

String _hashPasswordWithSalt(String value, String salt) =>
    sha256.convert(utf8.encode('$salt:$value')).toString();

String _generateSalt() {
  final random = Random.secure();
  return List<int>.generate(8, (_) => random.nextInt(256))
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}

String _generateUserId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return 'usr_${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
}
