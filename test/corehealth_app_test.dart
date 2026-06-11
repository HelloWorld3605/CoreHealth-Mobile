import 'package:corehealth_flutter/main.dart';
import 'package:corehealth_flutter/src/app_controller.dart';
import 'package:corehealth_flutter/src/data/app_repository.dart';
import 'package:corehealth_flutter/src/demo_data.dart';
import 'package:corehealth_flutter/src/models.dart';
import 'package:corehealth_flutter/src/services/ai_service.dart';
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
      aiService: _FakeAiService(),
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

  test('finishOnboarding generates and persists initial AI plans', () async {
    final repository = _MemoryRepository();
    final controller = AppController(
      repository: repository,
      aiService: _FakeAiService(),
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

    final error = await controller.finishOnboarding(DemoData.initialProfile);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(error, isNull);
    expect(repository.savedMealDays, contains(30));
    expect(repository.savedWorkoutDays, contains(30));
    expect(controller.stage, equals(AppStage.home));
  });

  test('empty AI generation does not expose demo meal or workout plans',
      () async {
    final repository = _MemoryRepository();
    final controller = AppController(
      repository: repository,
      aiService: _EmptyAiService(),
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

    final error = await controller.finishOnboarding(DemoData.initialProfile);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(error, isNull);
    expect(repository.savedMealDays, isEmpty);
    expect(repository.savedWorkoutDays, isEmpty);
    expect(controller.todayMeals, isEmpty);
    expect(controller.mealPlan, isEmpty);
    expect(controller.workoutPlan, isEmpty);
  });

  test('token top-up uses server order and refreshes wallet from backend',
      () async {
    final repository = _MemoryRepository();
    final controller = AppController(
      repository: repository,
      aiService: _FakeAiService(),
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

    final order = await controller.createTokenTopupOrder(tokenPacks.first);

    expect(repository.createdTopupPackIds, equals(['starter']));
    expect(order?.reference, equals('CHTOPUP'));
    expect(controller.profile.tokenBalance, equals(65));

    repository.bootstrapData = AppBootstrapData(
      session: const AppUserSession(
        userId: 'user-1',
        email: 'demo@corehealth.app',
        status: UserStatus.active,
      ),
      userData: repository.userData.copyWith(
        profile: repository.userData.profile.copyWith(
          tokenBalance: 120,
          tokenEarned: 120,
        ),
      ),
    );

    await controller.refreshAccountFromBackend();

    expect(controller.profile.tokenBalance, equals(120));
    expect(controller.profile.tokenEarned, equals(120));
  });
}

class _MemoryRepository implements AppRepository {
  final savedMealDays = <int>[];
  final savedWorkoutDays = <int>[];
  final createdTopupPackIds = <String>[];
  AppBootstrapData bootstrapData = const AppBootstrapData();

  PersistedUserData _userData = const PersistedUserData(
    profile: DemoData.initialProfile,
    weightHistory: DemoData.weightEntries,
    completedWorkoutDays: {},
    completedMealDays: {},
    cart: [],
    orders: [],
  );

  PersistedUserData get userData => _userData;

  @override
  Future<AppBootstrapData> bootstrap() async => bootstrapData;

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
        status: UserStatus.pendingOnboarding,
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
        status: UserStatus.active,
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
        status: UserStatus.active,
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
    return PaymentOrder(
      orderId: 'ord-test',
      reference: 'CHTEST',
      qrUrl: '',
      bankName: 'MB Bank',
      accountNumber: '123456',
      accountOwner: 'COREHEALTH',
      expiresAt:
          DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      amountVnd: items.fold<int>(0, (sum, item) => sum + item.priceK * 1000),
    );
  }

  @override
  Future<PaymentOrder> createTokenTopupOrder({
    required String userId,
    required TokenPack pack,
  }) async {
    createdTopupPackIds.add(pack.idValue);
    return PaymentOrder(
      orderId: 'topup-test',
      reference: 'CHTOPUP',
      qrUrl: '',
      bankName: 'MB Bank',
      accountNumber: '123456',
      accountOwner: 'COREHEALTH',
      expiresAt:
          DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      amountVnd: pack.priceK * 1000,
      packId: pack.idValue,
      tokenAmount: pack.tokens,
    );
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

  @override
  Future<void> savePlanGeneration(
      {required String userId, required PlanGeneration generation}) async {}

  @override
  Future<PlanGeneration?> getCurrentGeneration(
          {required String userId}) async =>
      null;

  @override
  Future<void> saveMealPlan(
      {required String userId,
      required String generationId,
      required int dayIndex,
      required MealPlanDay plan}) async {
    savedMealDays.add(dayIndex);
  }

  @override
  Future<MealPlanDay?> getMealPlan(
          {required String userId,
          required int version,
          required int dayIndex}) async =>
      null;

  @override
  Future<void> saveWorkoutPlan(
      {required String userId,
      required String generationId,
      required int dayIndex,
      required WorkoutDay plan}) async {
    savedWorkoutDays.add(dayIndex);
  }

  @override
  Future<WorkoutDay?> getWorkoutPlan(
          {required String userId,
          required int version,
          required int dayIndex}) async =>
      null;

  @override
  Future<void> saveShoppingItems(
      {required String userId, required List<ShoppingItem> items}) async {}

  @override
  Future<List<ShoppingItem>> getShoppingItems({required String userId}) async =>
      const [];

  @override
  Future<void> saveDailyProgress(
      {required String userId, required DailyProgress progress}) async {}

  @override
  Future<DailyProgress?> getDailyProgress(
          {required String userId, required String date}) async =>
      null;

  @override
  Future<void> logAiEvent(
      {required String userId, required AiEvent event}) async {}
}

class _FakeAiService extends AiService {
  @override
  Future<List<InsightItem>> generateInsights(DemoProfile profile) async {
    return const [];
  }

  @override
  Future<List<MealPlanDay>> generateMealPlan(DemoProfile profile) async {
    return const [
      MealPlanDay(
        dayNumber: 1,
        meals: [
          MealItem(
            id: 'meal-1',
            nameVi: 'Meal 1',
            slotLabel: 'Sang',
            calories: 400,
            protein: 25,
            carbs: 45,
            fat: 12,
            imageUrl: '',
            ingredients: ['Rice'],
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<WorkoutDay>> generateWorkoutPlan(DemoProfile profile) async {
    return const [
      WorkoutDay(
        dayNumber: 1,
        focusVi: 'Workout focus',
        exercises: [
          WorkoutExercise(
            id: 'workout-1',
            nameVi: 'Workout 1',
            description: '',
            sets: 3,
            reps: '10',
            caloriesBurned: 120,
          ),
        ],
      ),
    ];
  }
}

class _EmptyAiService extends AiService {
  @override
  Future<List<InsightItem>> generateInsights(DemoProfile profile) async {
    return const [];
  }

  @override
  Future<List<MealPlanDay>> generateMealPlan(DemoProfile profile) async {
    return const [];
  }

  @override
  Future<List<WorkoutDay>> generateWorkoutPlan(DemoProfile profile) async {
    return const [];
  }
}
