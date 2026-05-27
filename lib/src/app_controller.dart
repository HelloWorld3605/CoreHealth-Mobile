import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'data/local_app_repository.dart';
import 'demo_data.dart';
import 'models.dart';
import 'services/ai_service.dart';
import 'services/food_scan_service.dart';
import 'services/notification_service.dart';

class AppController extends ChangeNotifier {
  AppController({required AppRepository repository})
      : _repository = repository,
        _aiService = AiService();

  static const _showIntroOnLaunch = bool.fromEnvironment(
    'COREHEALTH_SHOW_INTRO_ON_LAUNCH',
    defaultValue: true,
  );

  final AppRepository _repository;
  final AiService _aiService;
  Future<void> _writeQueue = Future<void>.value();

  bool _isReady = false;
  AppStage _stage = AppStage.intro;
  AuthMode _authMode = AuthMode.signIn;
  int _currentTab = 0;
  bool _showPostOnboardingOffer = false;
  AppUserSession? _session;
  DemoProfile _profile = DemoData.initialProfile;
  List<WeightEntry> _weightHistory = DemoData.weightEntries;
  Set<int> _completedWorkoutDays = const {};
  Set<int> _completedMealDays = const {};
  List<Product> _cart = const [];
  List<OrderSummary> _orders = const [];

  List<InsightItem> _insights = DemoData.dashboardInsights;
  bool _insightsLoading = false;
  final _chatHistories = <CoachType, List<ChatMessage>>{};
  final _chatLoading = <CoachType, bool>{};

  List<MealPlanDay>? _aiMealTemplate; // 7-day AI rotation
  List<WorkoutDay>? _aiWorkoutTemplate; // 7-day AI rotation
  bool _mealPlanGenerating = false;
  bool _workoutPlanGenerating = false;

  List<MealLog> _todayMealLogs = const [];

  bool get isReady => _isReady;
  AppStage get stage => _stage;
  AuthMode get authMode => _authMode;
  int get currentTab => _currentTab;
  bool get showPostOnboardingOffer => _showPostOnboardingOffer;
  String? get userEmail => _session?.email;
  bool get isAuthenticated => _session != null;
  DemoProfile get profile => _profile;
  List<WeightEntry> get weightHistory => List.unmodifiable(_weightHistory);
  List<MealItem> get todayMeals =>
      mealPlan.isNotEmpty ? mealPlan.first.meals : DemoData.todayMeals;
  List<OrderSummary> get orders => List.unmodifiable(_orders);
  List<Product> get cart => List.unmodifiable(_cart);
  int get cartCount => _cart.length;
  int get cartTotalK => _cart.fold(0, (sum, item) => sum + item.priceK);
  int get streakCount => _completedWorkoutDays.length;
  int get totalPlanDays => profile.subscriptionMonths * 30;
  DateTime? get subscriptionExpiresAt => profile.subscriptionExpiresAt;
  int? get daysUntilExpiry => profile.daysUntilExpiry;

  List<InsightItem> get insights => List.unmodifiable(_insights);
  bool get insightsLoading => _insightsLoading;
  bool get isMealPlanGenerating => _mealPlanGenerating;
  bool get isWorkoutPlanGenerating => _workoutPlanGenerating;
  bool get hasMealAiPlan => _aiMealTemplate != null;
  bool get hasWorkoutAiPlan => _aiWorkoutTemplate != null;

  List<MealLog> get todayMealLogs => List.unmodifiable(_todayMealLogs);

  int get todayEatenCalories =>
      _todayMealLogs.fold(0, (sum, l) => sum + l.calories);

  /// Returns today's planned meals with calories adjusted for remaining slots.
  /// Slots already logged are marked as eaten; remaining ones get redistributed budget.
  List<({MealItem meal, MealLog? log})> get todayMealsWithLogs {
    final planned = mealPlan.isNotEmpty ? mealPlan.first.meals : <MealItem>[];
    final logsBySlot = {for (final l in _todayMealLogs) l.slotLabel: l};
    return planned
        .map((meal) => (meal: meal, log: logsBySlot[meal.slotLabel]))
        .toList();
  }

  /// Adjusted calories for remaining meals. Returns the same MealItem list
  /// but with calories redistributed based on what has already been eaten today.
  List<MealItem> get adjustedRemainingMeals {
    final planned = mealPlan.isNotEmpty ? mealPlan.first.meals : <MealItem>[];
    final loggedSlots = _todayMealLogs.map((l) => l.slotLabel).toSet();
    final remaining =
        planned.where((m) => !loggedSlots.contains(m.slotLabel)).toList();
    if (remaining.isEmpty) return const [];

    final targetCalories = profile.tdee.round();
    final remainingBudget =
        (targetCalories - todayEatenCalories).clamp(0, targetCalories);
    final plannedRemaining = remaining.fold(0, (sum, m) => sum + m.calories);
    if (plannedRemaining == 0) return remaining;

    final ratio = remainingBudget / plannedRemaining;
    return remaining
        .map((m) => MealItem(
              id: m.id,
              nameVi: m.nameVi,
              slotLabel: m.slotLabel,
              calories: (m.calories * ratio).round(),
              protein: (m.protein * ratio).round(),
              carbs: (m.carbs * ratio).round(),
              fat: (m.fat * ratio).round(),
              imageUrl: m.imageUrl,
              ingredients: m.ingredients,
            ))
        .toList();
  }

  List<ChatMessage> chatHistory(CoachType type) =>
      List.unmodifiable(_chatHistories[type] ?? const []);

  bool isChatLoading(CoachType type) => _chatLoading[type] ?? false;

  List<MealPlanDay> get mealPlan {
    final days = totalPlanDays.clamp(30, 180);
    final tpl = _aiMealTemplate;
    if (tpl != null && tpl.isNotEmpty) {
      return List.generate(
        days,
        (i) => MealPlanDay(dayNumber: i + 1, meals: tpl[i % tpl.length].meals),
      );
    }
    return DemoData.mealPlan(totalDays: days);
  }

  List<WorkoutDay> get workoutPlan {
    final days = totalPlanDays.clamp(30, 180);
    final tpl = _aiWorkoutTemplate;
    if (tpl != null && tpl.isNotEmpty) {
      return List.generate(
        days,
        (i) => WorkoutDay(
          dayNumber: i + 1,
          focusVi: tpl[i % tpl.length].focusVi,
          exercises: tpl[i % tpl.length].exercises,
        ),
      );
    }
    return DemoData.workoutPlan(totalDays: days);
  }

  Future<void> initialize() async {
    final bootstrap = await _repository.bootstrap();
    if (bootstrap.session != null && bootstrap.userData != null) {
      _session = bootstrap.session;
      _applyUserData(bootstrap.userData!, notify: false);
      _stage = bootstrap.session!.onboardingCompleted
          ? AppStage.home
          : AppStage.onboarding;
    } else {
      _resetUserState();
      _stage = AppStage.intro;
    }

    if (_showIntroOnLaunch) {
      _stage = AppStage.intro;
    }

    _isReady = true;
    notifyListeners();

    if (_stage == AppStage.home) {
      // Auto-upgrade to max for testing
      if (_session?.email == 'tuanhai362005t@gmail.com' &&
          _profile.plan != SubscriptionPlan.max) {
        updateSubscription(SubscriptionPlan.max, months: 12);
      }
      await _checkAndExpireSubscription();
      _refreshInsightsBackground();
      await _loadTodayLogs();
      unawaited(_initializeHomeNotifications());
    }
  }

  Future<void> _initializeHomeNotifications() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    try {
      await NotificationService.initialize();
      await NotificationService.scheduleDailyMealReminders();
      await NotificationService.scheduleSmartNotifications(_profile);
    } catch (e, st) {
      debugPrint('Notification startup error: $e\n$st');
    }
  }

  Future<void> _loadTodayLogs() async {
    final userId = _session?.userId;
    if (userId == null) return;
    final today = _todayDateKey();
    _todayMealLogs =
        await _repository.getMealLogsForDate(userId: userId, date: today);
    notifyListeners();
  }

  Future<void> logMealFromScan(FoodScanResult result, String slotLabel) async {
    final userId = _session?.userId;
    if (userId == null) return;

    final log = MealLog(
      id: 'log_${DateTime.now().microsecondsSinceEpoch}',
      slotLabel: slotLabel,
      foodName: result.name,
      calories: result.calories,
      protein: result.protein,
      carbs: result.carbs,
      fat: result.fat,
      loggedAt: DateTime.now(),
    );

    await _repository.insertMealLog(userId: userId, log: log);
    _todayMealLogs = [
      ..._todayMealLogs.where((l) => l.slotLabel != slotLabel),
      log
    ];
    notifyListeners();

    // Show adjustment notification for remaining meals.
    final remaining = adjustedRemainingMeals;
    if (remaining.isNotEmpty) {
      final remainingCal = remaining.fold(0, (sum, m) => sum + m.calories);
      await NotificationService.showMealAdjusted(
        'Bạn đã ăn ${result.calories} kcal. '
        'Còn ${remaining.length} bữa, ngân sách còn lại: $remainingCal kcal.',
      );
    }
  }

  Future<void> deleteMealLog(String logId) async {
    final userId = _session?.userId;
    if (userId == null) return;
    await _repository.deleteMealLog(userId: userId, logId: logId);
    _todayMealLogs = _todayMealLogs.where((l) => l.id != logId).toList();
    notifyListeners();
  }

  String _todayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Downgrade to free if the subscription has expired. Called on every app start.
  Future<void> _checkAndExpireSubscription() async {
    if (!_profile.isSubscriptionExpired) return;
    final downgraded = _profile.copyWith(
      plan: SubscriptionPlan.free,
      subscriptionMonths: 0,
      subscriptionStartDate: null,
    );
    _profile = downgraded;
    notifyListeners();
    // Persist the downgrade so it survives restarts.
    _enqueueMutation((userId) => _repository.updateSubscription(
          userId: userId,
          plan: SubscriptionPlan.free,
          months: 0,
        ));
  }

  bool isWorkoutCompleted(int dayNumber) {
    return _completedWorkoutDays.contains(dayNumber);
  }

  bool isMealCompleted(int dayNumber) {
    return _completedMealDays.contains(dayNumber);
  }

  void beginOnboarding() {
    openAuth(AuthMode.signUp);
  }

  void openIntro() {
    _stage = AppStage.intro;
    notifyListeners();
  }

  void openAuth(AuthMode mode) {
    _authMode = mode;
    _stage = AppStage.auth;
    notifyListeners();
  }

  void switchAuthMode(AuthMode mode) {
    if (_authMode == mode) {
      return;
    }

    _authMode = mode;
    notifyListeners();
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _repository.signIn(email: email, password: password);
      _applyAuthentication(result);
      _refreshInsightsBackground();
      return null;
    } on AppAuthException catch (error) {
      return error.message;
    } catch (e, st) {
      debugPrint('signIn error: $e\n$st');
      return 'Không thể đăng nhập lúc này.';
    }
  }

  Future<String?> signInWithGoogle({String? serverClientId}) async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: serverClientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        return 'Đã hủy đăng nhập Google.';
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        return 'Không lấy được ID token từ Google.';
      }
      final result = await _repository.signInWithGoogle(idToken: idToken);
      _applyAuthentication(result);
      _refreshInsightsBackground();
      return null;
    } on AppAuthException catch (error) {
      return error.message;
    } catch (e, st) {
      debugPrint('signInWithGoogle error: $e\n$st');
      return 'Không thể đăng nhập Google lúc này.';
    }
  }

  Future<String?> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    if (password.length < 8) {
      return 'Mật khẩu cần ít nhất 8 ký tự.';
    }

    try {
      final result = await _repository.register(
        displayName: displayName,
        email: email,
        password: password,
      );
      _applyAuthentication(result);
      return null;
    } on AppAuthException catch (error) {
      return error.message;
    } catch (e, st) {
      debugPrint('register error: $e\n$st');
      return 'Không thể tạo tài khoản lúc này.';
    }
  }

  Future<String?> finishOnboarding(DemoProfile profile) async {
    final session = _session;
    if (session == null) {
      return 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.';
    }

    try {
      final userData = await _repository.saveOnboardingProfile(
        userId: session.userId,
        profile: _withCoreHealthMaxTrial(profile),
      );
      _session = AppUserSession(
        userId: session.userId,
        email: session.email,
        onboardingCompleted: true,
      );
      _applyUserData(userData, notify: false);
      _currentTab = 0;
      _showPostOnboardingOffer = true;
      _stage = AppStage.home;
      notifyListeners();
      _refreshInsightsBackground();
      return null;
    } catch (e, st) {
      debugPrint('finishOnboarding error: $e\n$st');
      return 'Không thể lưu hồ sơ của bạn lúc này.';
    }
  }

  Future<void> generateAiMealPlan() async {
    if (_mealPlanGenerating || !profile.hasMealPlan) return;
    _mealPlanGenerating = true;
    notifyListeners();
    final tpl = await _aiService.generateMealPlan(profile);
    if (tpl.isNotEmpty) _aiMealTemplate = tpl;
    _mealPlanGenerating = false;
    notifyListeners();
  }

  Future<void> generateAiWorkoutPlan() async {
    if (_workoutPlanGenerating || !profile.hasWorkoutPlan) return;
    _workoutPlanGenerating = true;
    notifyListeners();
    final tpl = await _aiService.generateWorkoutPlan(profile);
    if (tpl.isNotEmpty) _aiWorkoutTemplate = tpl;
    _workoutPlanGenerating = false;
    notifyListeners();
  }

  Future<void> refreshInsights() async {
    if (_insightsLoading) return;
    _insightsLoading = true;
    notifyListeners();

    try {
      _insights = await _aiService.generateInsights(_profile);
    } finally {
      _insightsLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendChatMessage(CoachType type, String text) async {
    if (text.trim().isEmpty) return;
    if (_chatLoading[type] == true) return;

    final history = _chatHistories[type] ?? [];
    _chatHistories[type] = [
      ...history,
      ChatMessage(text: text.trim(), isUser: true),
    ];
    _chatLoading[type] = true;
    notifyListeners();

    try {
      final reply = await _aiService.chat(
        userMessage: text.trim(),
        profile: _profile,
        history: history,
        coachType: type,
      );
      _chatHistories[type] = [
        ..._chatHistories[type]!,
        ChatMessage(text: reply, isUser: false),
      ];
    } catch (_) {
      _chatHistories[type] = [
        ..._chatHistories[type]!,
        const ChatMessage(text: 'Xin lỗi, có lỗi xảy ra.', isUser: false),
      ];
    } finally {
      _chatLoading[type] = false;
      notifyListeners();
    }
  }

  void clearChatHistory(CoachType type) {
    _chatHistories.remove(type);
    notifyListeners();
  }

  void goToWelcome() {
    _stage = AppStage.welcome;
    notifyListeners();
  }

  void selectTab(int index) {
    if (_currentTab == index) {
      return;
    }

    _currentTab = index;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _resetUserState();
    _stage = AppStage.intro;
    _authMode = AuthMode.signIn;
    _currentTab = 0;
    notifyListeners();
  }

  Future<String?> updateProfile(DemoProfile updatedProfile) async {
    final session = _session;
    if (session == null) return 'Phiên đăng nhập không hợp lệ.';
    try {
      final userData = await _repository.saveOnboardingProfile(
        userId: session.userId,
        profile: updatedProfile,
      );
      _applyUserData(userData, notify: true);
      return null;
    } catch (e) {
      return 'Không thể lưu thông tin.';
    }
  }

  void addToCart(Product product) {
    _enqueueMutation((userId) {
      return _repository.addToCart(userId: userId, product: product);
    });
  }

  void removeCartItem(String productId) {
    _enqueueMutation((userId) {
      return _repository.removeCartItem(userId: userId, productId: productId);
    });
  }

  void clearCart() {
    _enqueueMutation((userId) {
      return _repository.clearCart(userId: userId);
    });
  }

  void placeOrder() {
    _enqueueMutation((userId) {
      return _repository.placeOrder(userId: userId);
    });
  }

  void placeOrderItems(Set<String> productIds) {
    if (productIds.isEmpty) {
      return;
    }

    _enqueueMutation((userId) {
      return _repository.placeOrderItems(
        userId: userId,
        productIds: productIds,
      );
    });
  }

  void updateSubscription(SubscriptionPlan plan, {required int months}) {
    _enqueueMutation((userId) {
      return _repository.updateSubscription(
        userId: userId,
        plan: plan,
        months: months,
      );
    });
  }

  void activatePaidSubscription(SubscriptionPlan plan, {required int months}) {
    if (plan == SubscriptionPlan.free) {
      updateSubscription(plan, months: months);
      return;
    }

    final trialCredit = _remainingCoreHealthMaxTrial();
    final paidProfile = _profile.copyWith(
      plan: plan,
      subscriptionMonths: months,
      subscriptionStartDate: DateTime.now().add(trialCredit),
    );

    _enqueueMutation((userId) {
      return _repository.saveOnboardingProfile(
        userId: userId,
        profile: paidProfile,
      );
    });
  }

  Future<String?> claimCoreHealthMaxTrial() async {
    final session = _session;
    if (session == null) {
      return 'Phiên đăng nhập không hợp lệ.';
    }

    final trialProfile = _withCoreHealthMaxTrial(_profile);

    try {
      final userData = await _repository.saveOnboardingProfile(
        userId: session.userId,
        profile: trialProfile,
      );
      _showPostOnboardingOffer = false;
      _applyUserData(userData, notify: false);
      notifyListeners();
      _refreshInsightsBackground();
      return null;
    } catch (e, st) {
      debugPrint('claimCoreHealthMaxTrial error: $e\n$st');
      return 'Không thể kích hoạt CoreHealth Max lúc này.';
    }
  }

  void dismissPostOnboardingOffer() {
    if (!_showPostOnboardingOffer) {
      return;
    }
    _showPostOnboardingOffer = false;
    notifyListeners();
  }

  void updateWeight(double weight) {
    if (weight <= 0) {
      return;
    }
    _profile = _profile.copyWith(weightKg: weight);
    notifyListeners();
    _enqueueMutation((userId) {
      return _repository.updateWeight(userId: userId, weight: weight);
    });
  }

  void toggleWorkoutCompleted(int dayNumber) {
    final wasCompleted = _completedWorkoutDays.contains(dayNumber);
    _enqueueMutation((userId) async {
      final data = await _repository.toggleWorkoutCompleted(
        userId: userId,
        dayNumber: dayNumber,
      );
      // Show streak congratulation only when marking as done (not undoing).
      if (!wasCompleted) {
        await NotificationService.showWorkoutCompleted(
            data.completedWorkoutDays.length);
      }
      return data;
    });
  }

  void toggleMealCompleted(int dayNumber) {
    _enqueueMutation((userId) {
      return _repository.toggleMealCompleted(
        userId: userId,
        dayNumber: dayNumber,
      );
    });
  }

  void _refreshInsightsBackground() {
    if (_profile.plan == SubscriptionPlan.free) return;
    refreshInsights().ignore();
  }

  void _applyAuthentication(AuthResult result) {
    _session = result.session;
    _applyUserData(result.userData, notify: false);
    _currentTab = 0;
    _stage = result.session.onboardingCompleted
        ? AppStage.home
        : AppStage.onboarding;
    notifyListeners();

    // Auto-upgrade to max for testing
    if (result.session.email == 'tuanhai362005t@gmail.com' &&
        _profile.plan != SubscriptionPlan.max) {
      updateSubscription(SubscriptionPlan.max, months: 12);
    }
  }

  void _applyUserData(PersistedUserData data, {required bool notify}) {
    final oldProfile = _profile;
    _profile = data.profile;
    _weightHistory = data.weightHistory;
    _completedWorkoutDays = data.completedWorkoutDays;
    _completedMealDays = data.completedMealDays;
    _cart = data.cart;
    _orders = data.orders;
    // Xóa AI plan cache nếu goal/allergies/activityLevel thay đổi
    if (oldProfile.goal != _profile.goal ||
        oldProfile.activityLevel != _profile.activityLevel ||
        oldProfile.allergies.join() != _profile.allergies.join() ||
        oldProfile.dietaryRestrictions.join() !=
            _profile.dietaryRestrictions.join() ||
        oldProfile.focusAreas.join() != _profile.focusAreas.join() ||
        oldProfile.preferredActivities.join() !=
            _profile.preferredActivities.join() ||
        oldProfile.nutritionPriorities.join() !=
            _profile.nutritionPriorities.join() ||
        oldProfile.mealBudget != _profile.mealBudget ||
        oldProfile.cookingTime != _profile.cookingTime ||
        oldProfile.trainingFrequency != _profile.trainingFrequency) {
      _aiMealTemplate = null;
      _aiWorkoutTemplate = null;
      _aiService.invalidateAllPlanCaches();
    }
    if (notify) {
      notifyListeners();
    }
  }

  void _resetUserState() {
    _session = null;
    _profile = DemoData.initialProfile;
    _weightHistory = DemoData.weightEntries;
    _completedWorkoutDays = const {};
    _completedMealDays = const {};
    _cart = const [];
    _orders = const [];
    _showPostOnboardingOffer = false;
    _insights = DemoData.dashboardInsights;
    _chatHistories.clear();
    _chatLoading.clear();
    _aiMealTemplate = null;
    _aiWorkoutTemplate = null;
    _todayMealLogs = const [];
  }

  void _enqueueMutation(
    Future<PersistedUserData> Function(String userId) mutation,
  ) {
    final userId = _session?.userId;
    if (userId == null) {
      return;
    }

    _writeQueue = _writeQueue.then((_) async {
      final data = await mutation(userId);
      _applyUserData(data, notify: true);
    }).catchError((Object error, StackTrace stackTrace) {
      debugPrint('Persistence error: $error');
    });
    unawaited(_writeQueue);
  }

  DateTime _subscriptionStartForRemainingDays(int days) {
    final targetExpiry = DateTime.now().add(Duration(days: days));
    final year =
        targetExpiry.month == 1 ? targetExpiry.year - 1 : targetExpiry.year;
    final month = targetExpiry.month == 1 ? 12 : targetExpiry.month - 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = targetExpiry.day > lastDay ? lastDay : targetExpiry.day;
    return DateTime(
      year,
      month,
      day,
      targetExpiry.hour,
      targetExpiry.minute,
      targetExpiry.second,
    );
  }

  Duration _remainingCoreHealthMaxTrial() {
    final expiresAt = _profile.coreHealthMaxTrialExpiresAt;
    if (expiresAt == null) {
      return Duration.zero;
    }
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  DemoProfile _withCoreHealthMaxTrial(DemoProfile profile) {
    if (profile.hasActiveCoreHealthMaxTrial) {
      return profile;
    }
    final trialExpiresAt = DateTime.now().add(const Duration(days: 7));
    return profile.copyWith(
      plan: SubscriptionPlan.max,
      subscriptionMonths: 1,
      subscriptionStartDate: _subscriptionStartForRemainingDays(7),
      coreHealthMaxTrialExpiresAt: trialExpiresAt,
    );
  }
}

class CoreHealthScope extends InheritedNotifier<AppController> {
  const CoreHealthScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CoreHealthScope>();
    assert(scope != null, 'CoreHealthScope not found in widget tree.');
    return scope!.notifier!;
  }
}
