import 'package:corehealth_flutter/main.dart';
import 'package:corehealth_flutter/src/app_controller.dart';
import 'package:corehealth_flutter/src/data/app_repository.dart';
import 'package:corehealth_flutter/src/demo_data.dart';
import 'package:corehealth_flutter/src/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders intro before welcome after bootstrap', (tester) async {
    final controller = AppController(
      repository: _MemoryRepository(),
    );
    await controller.initialize();

    await tester.pumpWidget(CoreHealthApp(controller: controller));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('CoreHealth'), findsOneWidget);
    expect(find.text('Kéo để bắt đầu'), findsOneWidget);
    expect(find.text('Bắt đầu miễn phí'), findsNothing);

    await tester.drag(
      find.byIcon(Icons.keyboard_double_arrow_right_rounded),
      const Offset(700, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bắt đầu miễn phí'), findsOneWidget);
  });

  test('finishOnboarding preserves referral and token fields from signup',
      () async {
    final controller = AppController(
      repository: _MemoryRepository(),
    );

    await controller.register(
      displayName: 'Demo User',
      email: 'demo@corehealth.app',
      password: 'password123',
    );
    await controller.verifyOtp(
      email: 'demo@corehealth.app',
      otp: '123456',
    );

    final onboardingProfile = DemoData.initialProfile.copyWith(
      name: 'Updated Name',
      tokenBalance: 0,
      tokenEarned: 0,
      referralCode: '',
      referredBy: '',
    );
    final error = await controller.finishOnboarding(onboardingProfile);

    expect(error, isNull);
    expect(controller.profile.name, equals('Updated Name'));
    expect(controller.profile.tokenBalance, equals(65));
    expect(controller.profile.tokenEarned, equals(65));
    expect(controller.profile.referralCode, equals('DEMO-123456'));
    expect(controller.profile.referredBy, equals('referrer-1'));
  });
}

class _MemoryRepository implements AppRepository {
  PersistedUserData _userData = const PersistedUserData(
    profile: DemoData.initialProfile,
    weightHistory: DemoData.weightEntries,
    completedWorkoutDays: {},
    completedMealDays: {},
    cart: [],
    orders: [],
  );

  @override
  Future<AppBootstrapData> bootstrap() async => const AppBootstrapData();

  @override
  Future<RegisterResponseData> register({
    required String displayName,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    return RegisterResponseData(
      success: true,
      email: email,
      devOtp: '123456',
    );
  }

  @override
  Future<AuthResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _userData = PersistedUserData(
      profile: DemoData.initialProfile.copyWith(
        name: 'Demo User',
        tokenBalance: 65,
        tokenEarned: 65,
        referralCode: 'DEMO-123456',
        referredBy: 'referrer-1',
      ),
      weightHistory: DemoData.weightEntries,
      completedWorkoutDays: const {},
      completedMealDays: const {},
      cart: const [],
      orders: const [],
    );
    return AuthResult(
      session: const AppUserSession(
        userId: 'user-1',
        email: 'demo@corehealth.app',
        onboardingCompleted: false,
      ),
      userData: _userData,
    );
  }

  @override
  Future<RegisterResponseData> resendOtp({
    required String email,
  }) async {
    return RegisterResponseData(
      success: true,
      email: email,
      devOtp: '123456',
    );
  }

  @override
  Future<RegisterResponseData> requestPasswordReset({
    required String email,
  }) async {
    return RegisterResponseData(
      success: true,
      email: email,
      devOtp: '123456',
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {}

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    return AuthResult(
      session: const AppUserSession(
        userId: 'user-1',
        email: 'demo@corehealth.app',
        onboardingCompleted: true,
      ),
      userData: _userData,
    );
  }

  @override
  Future<AuthResult> signInWithGoogle({required String idToken}) async {
    return AuthResult(
      session: const AppUserSession(
        userId: 'user-1',
        email: 'demo@corehealth.app',
        onboardingCompleted: true,
      ),
      userData: _userData,
    );
  }

  @override
  Future<PersistedUserData> saveOnboardingProfile({
    required String userId,
    required DemoProfile profile,
  }) async {
    _userData = PersistedUserData(
      profile: profile,
      weightHistory: DemoData.weightEntries,
      completedWorkoutDays: const {},
      completedMealDays: const {},
      cart: _userData.cart,
      orders: _userData.orders,
    );
    return _userData;
  }

  @override
  Future<PersistedUserData> updateSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required int months,
  }) async {
    _userData = PersistedUserData(
      profile: _userData.profile.copyWith(
        plan: plan,
        subscriptionMonths: months,
      ),
      weightHistory: _userData.weightHistory,
      completedWorkoutDays: _userData.completedWorkoutDays,
      completedMealDays: _userData.completedMealDays,
      cart: _userData.cart,
      orders: _userData.orders,
    );
    return _userData;
  }

  @override
  Future<PersistedUserData> updateTokenWallet({
    required String userId,
    required int tokenBalance,
    required int tokenEarned,
    required int tokenSpent,
  }) async {
    _userData = PersistedUserData(
      profile: _userData.profile.copyWith(
        tokenBalance: tokenBalance,
        tokenEarned: tokenEarned,
        tokenSpent: tokenSpent,
      ),
      weightHistory: _userData.weightHistory,
      completedWorkoutDays: _userData.completedWorkoutDays,
      completedMealDays: _userData.completedMealDays,
      cart: _userData.cart,
      orders: _userData.orders,
    );
    return _userData;
  }

  @override
  Future<PersistedUserData> updateUserSettings({
    required String userId,
    required UserSettings settings,
  }) async {
    _userData = _userData.copyWith(settings: settings);
    return _userData;
  }

  @override
  Future<List<TokenTransaction>> getTokenTransactions({
    required String userId,
  }) async =>
      const [];

  @override
  Future<void> addTokenTransaction({
    required String userId,
    required TokenTransaction transaction,
  }) async {}

  @override
  Future<PersistedUserData> updateWeight({
    required String userId,
    required double weight,
  }) async {
    _userData = PersistedUserData(
      profile: _userData.profile.copyWith(weightKg: weight),
      weightHistory: [
        ..._userData.weightHistory,
        WeightEntry(label: '02/04', weight: weight),
      ],
      completedWorkoutDays: _userData.completedWorkoutDays,
      completedMealDays: _userData.completedMealDays,
      cart: _userData.cart,
      orders: _userData.orders,
    );
    return _userData;
  }

  @override
  Future<PersistedUserData> toggleWorkoutCompleted({
    required String userId,
    required int dayNumber,
  }) async {
    final completed = {..._userData.completedWorkoutDays};
    if (!completed.add(dayNumber)) {
      completed.remove(dayNumber);
    }
    _userData = PersistedUserData(
      profile: _userData.profile,
      weightHistory: _userData.weightHistory,
      completedWorkoutDays: completed,
      completedMealDays: _userData.completedMealDays,
      cart: _userData.cart,
      orders: _userData.orders,
    );
    return _userData;
  }

  @override
  Future<PersistedUserData> toggleMealCompleted({
    required String userId,
    required int dayNumber,
  }) async {
    final completed = {..._userData.completedMealDays};
    if (!completed.add(dayNumber)) {
      completed.remove(dayNumber);
    }
    _userData = PersistedUserData(
      profile: _userData.profile,
      weightHistory: _userData.weightHistory,
      completedWorkoutDays: _userData.completedWorkoutDays,
      completedMealDays: completed,
      cart: _userData.cart,
      orders: _userData.orders,
    );
    return _userData;
  }

  @override
  Future<PersistedUserData> addToCart({
    required String userId,
    required Product product,
  }) async {
    _userData = PersistedUserData(
      profile: _userData.profile,
      weightHistory: _userData.weightHistory,
      completedWorkoutDays: _userData.completedWorkoutDays,
      completedMealDays: _userData.completedMealDays,
      cart: [..._userData.cart, product],
      orders: _userData.orders,
    );
    return _userData;
  }

  @override
  Future<PersistedUserData> removeCartItem({
    required String userId,
    required String productId,
  }) async {
    final cart = _userData.cart.where((p) => p.id != productId).toList();
    _userData = PersistedUserData(
      profile: _userData.profile,
      weightHistory: _userData.weightHistory,
      completedWorkoutDays: _userData.completedWorkoutDays,
      completedMealDays: _userData.completedMealDays,
      cart: cart,
      orders: _userData.orders,
    );
    return _userData;
  }

  @override
  Future<PersistedUserData> clearCart({
    required String userId,
  }) async {
    _userData = PersistedUserData(
      profile: _userData.profile,
      weightHistory: _userData.weightHistory,
      completedWorkoutDays: _userData.completedWorkoutDays,
      completedMealDays: _userData.completedMealDays,
      cart: const [],
      orders: _userData.orders,
    );
    return _userData;
  }

  @override
  Future<PersistedUserData> placeOrder({
    required String userId,
  }) async {
    _userData = PersistedUserData(
      profile: _userData.profile,
      weightHistory: _userData.weightHistory,
      completedWorkoutDays: _userData.completedWorkoutDays,
      completedMealDays: _userData.completedMealDays,
      cart: const [],
      orders: _userData.orders,
    );
    return _userData;
  }

  @override
  Future<PersistedUserData> placeOrderItems({
    required String userId,
    required Set<String> productIds,
  }) async {
    _userData = PersistedUserData(
      profile: _userData.profile,
      weightHistory: _userData.weightHistory,
      completedWorkoutDays: _userData.completedWorkoutDays,
      completedMealDays: _userData.completedMealDays,
      cart: _userData.cart
          .where((product) => !productIds.contains(product.id))
          .toList(growable: false),
      orders: _userData.orders,
    );
    return _userData;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> insertMealLog(
      {required String userId, required MealLog log}) async {}

  @override
  Future<List<MealLog>> getMealLogsForDate(
          {required String userId, required String date}) async =>
      const [];

  @override
  Future<void> deleteMealLog(
      {required String userId, required String logId}) async {}

  @override
  Future<List<ChatSession>> getChatSessions({required String userId}) async =>
      const [];

  @override
  Future<void> saveChatSession(
      {required String userId, required ChatSession session}) async {}

  @override
  Future<void> deleteChatSession(
      {required String userId, required String sessionId}) async {}
}
