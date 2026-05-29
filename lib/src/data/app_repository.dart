import '../models.dart';

abstract class AppRepository {
  Future<AppBootstrapData> bootstrap();
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });
  Future<RegisterResponseData> register({
    required String displayName,
    required String email,
    required String password,
    String? referralCode,
  });
  Future<AuthResult> verifyOtp({
    required String email,
    required String otp,
  });
  Future<RegisterResponseData> resendOtp({
    required String email,
  });
  Future<RegisterResponseData> requestPasswordReset({
    required String email,
  });
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
  Future<AuthResult> signInWithGoogle({required String idToken});
  Future<PersistedUserData> saveOnboardingProfile({
    required String userId,
    required DemoProfile profile,
  });
  Future<PersistedUserData> updateSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required int months,
  });
  Future<PersistedUserData> updateTokenWallet({
    required String userId,
    required int tokenBalance,
    required int tokenEarned,
    required int tokenSpent,
  });
  Future<PersistedUserData> updateUserSettings({
    required String userId,
    required UserSettings settings,
  });
  Future<List<TokenTransaction>> getTokenTransactions({required String userId});
  Future<void> addTokenTransaction({
    required String userId,
    required TokenTransaction transaction,
  });
  Future<PersistedUserData> updateWeight({
    required String userId,
    required double weight,
  });
  Future<PersistedUserData> toggleWorkoutCompleted({
    required String userId,
    required int dayNumber,
  });
  Future<PersistedUserData> toggleMealCompleted({
    required String userId,
    required int dayNumber,
  });
  Future<PersistedUserData> addToCart({
    required String userId,
    required Product product,
  });
  Future<PersistedUserData> removeCartItem({
    required String userId,
    required String productId,
  });
  Future<PersistedUserData> clearCart({
    required String userId,
  });
  Future<PersistedUserData> placeOrder({
    required String userId,
  });
  Future<PersistedUserData> placeOrderItems({
    required String userId,
    required Set<String> productIds,
  });
  Future<void> signOut();
  Future<void> insertMealLog({required String userId, required MealLog log});
  Future<List<MealLog>> getMealLogsForDate(
      {required String userId, required String date});
  Future<void> deleteMealLog({required String userId, required String logId});
  Future<List<ChatSession>> getChatSessions({required String userId});
  Future<void> saveChatSession(
      {required String userId, required ChatSession session});
  Future<void> deleteChatSession(
      {required String userId, required String sessionId});

  // Architecture V2: AI Synchronization
  Future<void> savePlanGeneration({required String userId, required PlanGeneration generation});
  Future<PlanGeneration?> getCurrentGeneration({required String userId});
  
  Future<void> saveMealPlan({required String userId, required String generationId, required int dayIndex, required MealPlanDay plan});
  Future<MealPlanDay?> getMealPlan({required String userId, required int version, required int dayIndex});
  
  Future<void> saveWorkoutPlan({required String userId, required String generationId, required int dayIndex, required WorkoutDay plan});
  Future<WorkoutDay?> getWorkoutPlan({required String userId, required int version, required int dayIndex});

  Future<void> saveShoppingItems({required String userId, required List<ShoppingItem> items});
  Future<List<ShoppingItem>> getShoppingItems({required String userId});

  Future<void> saveDailyProgress({required String userId, required DailyProgress progress});
  Future<DailyProgress?> getDailyProgress({required String userId, required String date});

  Future<void> logAiEvent({required String userId, required AiEvent event});
}

class AppBootstrapData {
  const AppBootstrapData({
    this.session,
    this.userData,
  });

  final AppUserSession? session;
  final PersistedUserData? userData;
}

class AuthResult {
  const AuthResult({
    required this.session,
    required this.userData,
  });

  final AppUserSession session;
  final PersistedUserData userData;
}

class PersistedUserData {
  const PersistedUserData({
    required this.profile,
    required this.weightHistory,
    required this.completedWorkoutDays,
    required this.completedMealDays,
    required this.cart,
    required this.orders,
    this.settings = const UserSettings(),
  });

  final DemoProfile profile;
  final List<WeightEntry> weightHistory;
  final Set<int> completedWorkoutDays;
  final Set<int> completedMealDays;
  final List<Product> cart;
  final List<OrderSummary> orders;
  final UserSettings settings;

  PersistedUserData copyWith({
    DemoProfile? profile,
    List<WeightEntry>? weightHistory,
    Set<int>? completedWorkoutDays,
    Set<int>? completedMealDays,
    List<Product>? cart,
    List<OrderSummary>? orders,
    UserSettings? settings,
  }) {
    return PersistedUserData(
      profile: profile ?? this.profile,
      weightHistory: weightHistory ?? this.weightHistory,
      completedWorkoutDays: completedWorkoutDays ?? this.completedWorkoutDays,
      completedMealDays: completedMealDays ?? this.completedMealDays,
      cart: cart ?? this.cart,
      orders: orders ?? this.orders,
      settings: settings ?? this.settings,
    );
  }
}

class AppAuthException implements Exception {
  const AppAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
