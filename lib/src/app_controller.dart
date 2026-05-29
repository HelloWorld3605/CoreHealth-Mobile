import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'data/app_repository.dart';
import 'demo_data.dart';
import 'models.dart';
import 'services/ai_service.dart';
import 'services/food_scan_service.dart';
import 'services/notification_service.dart';
import 'services/shopping_list_generator.dart';
import 'services/ai_command_processor.dart';

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
  OnboardingProgress _onboardingProgress = const OnboardingProgress();
  DemoProfile _profile = DemoData.initialProfile;
  List<WeightEntry> _weightHistory = DemoData.weightEntries;
  Set<int> _completedWorkoutDays = const {};
  Set<int> _completedMealDays = const {};
  List<Product> _cart = const [];
  List<OrderSummary> _orders = const [];
  List<TokenTransaction> _tokenTransactions = const [];
  UserSettings _settings = const UserSettings();
  String? _pendingVerificationEmail;
  String? _devOtp;
  String? _pendingPasswordResetEmail;
  String? _devPasswordResetOtp;

  List<InsightItem> _insights = DemoData.dashboardInsights;
  bool _insightsLoading = false;
  final _chatHistories = <CoachType, List<ChatMessage>>{};
  final _chatLoading = <CoachType, bool>{};
  List<ChatSession> _chatSessions = const [];
  String? _activeChatSessionId;

  PlanGeneration? _currentGeneration;
  MealPlanDay? _currentMealPlan;
  WorkoutDay? _currentWorkoutPlan;
  List<MealPlanDay> _generationMealPlans = const [];
  List<WorkoutDay> _generationWorkoutPlans = const [];
  List<ShoppingItem> _shoppingItems = const [];
  DailyProgress? _todayProgress;
  int _currentDayIndex = 1;

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
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  String? get devOtp => _devOtp;
  String? get pendingPasswordResetEmail => _pendingPasswordResetEmail;
  String? get devPasswordResetOtp => _devPasswordResetOtp;
  OnboardingProgress get onboardingProgress => _onboardingProgress;
  DemoProfile get profile => _profile;
  List<WeightEntry> get weightHistory => List.unmodifiable(_weightHistory);
  List<MealItem> get todayMeals => _currentMealPlan?.meals ?? DemoData.todayMeals;
  List<OrderSummary> get orders => List.unmodifiable(_orders);
  List<Product> get cart => List.unmodifiable(_cart);
  List<TokenTransaction> get tokenTransactions =>
      List.unmodifiable(_tokenTransactions);
  UserSettings get settings => _settings;
  int get cartCount => _cart.length;
  int get cartTotalK => _cart.fold(0, (sum, item) => sum + item.priceK);
  int get streakCount => _completedWorkoutDays.length;
  int get totalPlanDays => 30;
  int get tokenBalance => _profile.tokenBalance;
  DateTime? get subscriptionExpiresAt => profile.subscriptionExpiresAt;
  int? get daysUntilExpiry => profile.daysUntilExpiry;

  List<InsightItem> get insights => List.unmodifiable(_insights);
  bool get insightsLoading => _insightsLoading;
  bool get isMealPlanGenerating => _mealPlanGenerating;
  bool get isWorkoutPlanGenerating => _workoutPlanGenerating;
  
  PlanGeneration? get currentGeneration => _currentGeneration;
  MealPlanDay? get currentMealPlan => _currentMealPlan;
  WorkoutDay? get currentWorkoutPlan => _currentWorkoutPlan;
  List<ShoppingItem> get shoppingItems => List.unmodifiable(_shoppingItems);
  DailyProgress? get todayProgress => _todayProgress;
  int get currentDayIndex => _currentDayIndex;

  bool get hasMealAiPlan => _currentMealPlan != null;
  bool get hasWorkoutAiPlan => _currentWorkoutPlan != null;

  List<ChatSession> get chatSessions => _chatSessions;
  String? get activeChatSessionId => _activeChatSessionId;
  bool get isWellnessChatLoading => _chatLoading[CoachType.wellness] == true;

  ChatSession? get activeChatSession {
    if (_activeChatSessionId == null) return null;
    try {
      return _chatSessions.firstWhere((s) => s.id == _activeChatSessionId);
    } catch (_) {
      return null;
    }
  }

  List<MealLog> get todayMealLogs => List.unmodifiable(_todayMealLogs);

  int get todayEatenCalories =>
      _todayMealLogs.fold(0, (sum, l) => sum + l.calories);

  /// Returns today's planned meals with calories adjusted for remaining slots.
  /// Slots already logged are marked as eaten; remaining ones get redistributed budget.
  List<({MealItem meal, MealLog? log})> get todayMealsWithLogs {
    final planned = _currentMealPlan?.meals ?? <MealItem>[];
    final logsBySlot = {for (final l in _todayMealLogs) l.slotLabel: l};
    return planned
        .map((meal) => (meal: meal, log: logsBySlot[meal.slotLabel]))
        .toList();
  }

  /// Adjusted calories for remaining meals. Returns the same MealItem list
  /// but with calories redistributed based on what has already been eaten today.
  List<MealItem> get adjustedRemainingMeals {
    final planned = _currentMealPlan?.meals ?? <MealItem>[];
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
    if (_generationMealPlans.isNotEmpty) return _generationMealPlans;
    return DemoData.mealPlan(totalDays: totalPlanDays.clamp(30, 180));
  }

  List<WorkoutDay> get workoutPlan {
    if (_generationWorkoutPlans.isNotEmpty) return _generationWorkoutPlans;
    return DemoData.workoutPlan(totalDays: totalPlanDays.clamp(30, 180));
  }

  Future<void> initialize() async {
    final bootstrap = await _repository.bootstrap();
    if (bootstrap.session != null && bootstrap.userData != null) {
      _session = bootstrap.session;
      _applyUserData(bootstrap.userData!, notify: false);
      switch (bootstrap.session!.status) {
        case UserStatus.active:
        case UserStatus.pendingOnboarding:
          _stage = AppStage.home;
          break;
        case UserStatus.generatingPlan:
        case UserStatus.planFailed:
          _stage = AppStage.generatingPlan;
          break;
      }
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
      _refreshInsightsBackground();
      await Future.wait([
        _loadTodayLogs(),
        _loadTokenTransactions(),
        _loadSyncData(),
      ]);
      unawaited(_initializeHomeNotifications());
    }
  }

  Future<void> _loadSyncData() async {
    final userId = _session?.userId;
    if (userId == null) return;

    final startDate = _profile.subscriptionStartDate ?? DateTime.now();
    final diff = DateTime.now().difference(startDate).inDays;
    _currentDayIndex = diff >= 0 ? diff + 1 : 1;

    _currentGeneration = await _repository.getCurrentGeneration(userId: userId);
    if (_currentGeneration != null) {
      final genVersion = _currentGeneration!.version;
      
      final meals = <MealPlanDay>[];
      final workouts = <WorkoutDay>[];
      for (int i = 1; i <= 30; i++) {
        final m = await _repository.getMealPlan(userId: userId, version: genVersion, dayIndex: i);
        if (m != null) meals.add(m);
        final w = await _repository.getWorkoutPlan(userId: userId, version: genVersion, dayIndex: i);
        if (w != null) workouts.add(w);
      }
      _generationMealPlans = meals;
      _generationWorkoutPlans = workouts;
      
      _currentMealPlan = await _repository.getMealPlan(
          userId: userId, version: genVersion, dayIndex: _currentDayIndex);
      _currentWorkoutPlan = await _repository.getWorkoutPlan(
          userId: userId, version: genVersion, dayIndex: _currentDayIndex);
      _shoppingItems = await _repository.getShoppingItems(userId: userId);
    }
    
    final dateStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    _todayProgress = await _repository.getDailyProgress(userId: userId, date: dateStr);
    
    notifyListeners();
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
    String? referralCode,
  }) async {
    if (password.length < 8) {
      return 'Mật khẩu cần ít nhất 8 ký tự.';
    }

    try {
      final response = await _repository.register(
        displayName: displayName,
        email: email,
        password: password,
        referralCode: referralCode,
      );
      if (response.success) {
        _pendingVerificationEmail = response.email;
        _devOtp = response.devOtp;
        _stage = AppStage.verifyOtp;
        notifyListeners();
        return null;
      } else {
        return 'Đăng ký không thành công. Vui lòng thử lại.';
      }
    } on AppAuthException catch (error) {
      return error.message;
    } catch (e, st) {
      debugPrint('register error: $e\n$st');
      return 'Không thể tạo tài khoản lúc này.';
    }
  }

  Future<String?> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final result = await _repository.verifyOtp(
        email: email,
        otp: otp,
      );
      _pendingVerificationEmail = null;
      _devOtp = null;
      _applyAuthentication(result);
      _refreshInsightsBackground();
      return null;
    } on AppAuthException catch (error) {
      return error.message;
    } catch (e, st) {
      debugPrint('verifyOtp error: $e\n$st');
      return 'Không thể xác thực OTP lúc này.';
    }
  }

  Future<String?> resendOtp({
    required String email,
  }) async {
    try {
      final response = await _repository.resendOtp(
        email: email,
      );
      if (response.success) {
        _devOtp = response.devOtp;
        notifyListeners();
        return null;
      } else {
        return 'Gửi lại mã OTP thất bại.';
      }
    } on AppAuthException catch (error) {
      return error.message;
    } catch (e, st) {
      debugPrint('resendOtp error: $e\n$st');
      return 'Không thể gửi lại mã OTP lúc này.';
    }
  }

  Future<String?> requestPasswordReset({required String email}) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return 'Vui lòng nhập email đã đăng ký.';
    }

    try {
      final response =
          await _repository.requestPasswordReset(email: normalizedEmail);
      if (!response.success) {
        return 'Không thể gửi mã đặt lại mật khẩu lúc này.';
      }
      _pendingPasswordResetEmail = response.email;
      _devPasswordResetOtp = response.devOtp;
      notifyListeners();
      return null;
    } on AppAuthException catch (error) {
      return error.message;
    } catch (e, st) {
      debugPrint('requestPasswordReset error: $e\n$st');
      return 'Không thể gửi mã đặt lại mật khẩu lúc này.';
    }
  }

  Future<String?> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (otp.trim().length < 6) {
      return 'Vui lòng nhập đầy đủ mã OTP 6 chữ số.';
    }
    if (newPassword.length < 8) {
      return 'Mật khẩu mới cần ít nhất 8 ký tự.';
    }

    try {
      await _repository.resetPassword(
        email: email.trim(),
        otp: otp.trim(),
        newPassword: newPassword,
      );
      _pendingPasswordResetEmail = null;
      _devPasswordResetOtp = null;
      notifyListeners();
      return null;
    } on AppAuthException catch (error) {
      return error.message;
    } catch (e, st) {
      debugPrint('resetPassword error: $e\n$st');
      return 'Không thể đặt lại mật khẩu lúc này.';
    }
  }

  void cancelVerification() {
    _pendingVerificationEmail = null;
    _devOtp = null;
    _pendingPasswordResetEmail = null;
    _devPasswordResetOtp = null;
    _stage = AppStage.auth;
    notifyListeners();
  }

  Future<String?> finishOnboarding(DemoProfile profile) async {
    final session = _session;
    if (session == null) {
      return 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.';
    }

    try {
      final onboardingProfile = _preserveAccountFields(profile);
      final userData = await _repository.saveOnboardingProfile(
        userId: session.userId,
        profile: _withStarterTokens(onboardingProfile),
      );
      final tokenDelta =
          userData.profile.tokenEarned - onboardingProfile.tokenEarned;
      if (tokenDelta > 0) {
        await _recordTokenTransaction(
          amount: tokenDelta,
          priceK: 0,
          description: userData.profile.referredBy.isEmpty
              ? 'Quà tặng đăng ký mới'
              : 'Quà tặng đăng ký qua mã giới thiệu',
        );
      }
      _session = AppUserSession(
        userId: session.userId,
        email: session.email,
        status: UserStatus.generatingPlan,
      );
      _applyUserData(userData, notify: false);
      _currentTab = 0;
      _showPostOnboardingOffer = false;
      _stage = AppStage.generatingPlan;
      notifyListeners();
      _refreshInsightsBackground();
      
      // Simulate plan generation in background
      unawaited(_simulatePlanGeneration());
      return null;
    } catch (e, st) {
      debugPrint('finishOnboarding error: $e\n$st');
      return 'Không thể lưu hồ sơ của bạn lúc này.';
    }
  }

  Future<void> _simulatePlanGeneration() async {
    await Future.delayed(const Duration(seconds: 4)); // mock AI generation time
    final session = _session;
    if (session == null) return;
    
    // Once plan is generated, user status becomes active
    _session = AppUserSession(
      userId: session.userId,
      email: session.email,
      status: UserStatus.active,
    );
    _stage = AppStage.home;
    _showPostOnboardingOffer = true;
    notifyListeners();
  }

  Future<void> saveOnboardingStep(int step, Map<String, dynamic> data) async {
    // Mock API call to save onboarding step
    await Future.delayed(const Duration(milliseconds: 300));
    _onboardingProgress = OnboardingProgress(
      currentStep: step,
      completedSteps: <int>{..._onboardingProgress.completedSteps, step}.toList(),
      isCompleted: false,
    );
    notifyListeners();
  }

  Future<bool> generateAiMealPlan() async {
    final userId = _session?.userId;
    if (userId == null) return false;
    if (_mealPlanGenerating || !profile.hasMealPlan) return false;
    _mealPlanGenerating = true;
    notifyListeners();
    
    final tpl = await _aiService.generateMealPlan(profile);
    if (tpl.isNotEmpty) {
      final version = (_currentGeneration?.version ?? 0) + 1;
      final gen = PlanGeneration(
        id: 'gen_${userId}_$version',
        userId: userId,
        version: version,
        goalSnapshot: 'Goal: ${profile.goal.name}',
        createdAt: DateTime.now(),
      );
      await _repository.savePlanGeneration(userId: userId, generation: gen);
      
      final allDays = <MealPlanDay>[];
      for (int i = 0; i < 30; i++) {
        final dayPlan = MealPlanDay(dayNumber: i + 1, meals: tpl[i % tpl.length].meals);
        allDays.add(dayPlan);
        await _repository.saveMealPlan(userId: userId, generationId: gen.id, dayIndex: i + 1, plan: dayPlan);
      }
      
      if (_currentGeneration != null) {
        for (int i = 0; i < 30; i++) {
          final w = await _repository.getWorkoutPlan(userId: userId, version: _currentGeneration!.version, dayIndex: i + 1);
          if (w != null) {
            await _repository.saveWorkoutPlan(userId: userId, generationId: gen.id, dayIndex: i + 1, plan: w);
          }
        }
      }
      
      _currentGeneration = gen;
      _generationMealPlans = allDays;
      if (_currentDayIndex >= 1 && _currentDayIndex <= 30) {
        _currentMealPlan = allDays[_currentDayIndex - 1];
        _currentWorkoutPlan = await _repository.getWorkoutPlan(userId: userId, version: gen.version, dayIndex: _currentDayIndex);
      }
      
      final items = ShoppingListGenerator.generate(userId, allDays);
      await _repository.saveShoppingItems(userId: userId, items: items);
      _shoppingItems = items;
      
      _spendTokens(TokenCosts.fullDayMealPlan);
    }
    _mealPlanGenerating = false;
    notifyListeners();
    return tpl.isNotEmpty;
  }

  Future<bool> generateAiWorkoutPlan() async {
    final userId = _session?.userId;
    if (userId == null) return false;
    if (_workoutPlanGenerating || !profile.hasWorkoutPlan) return false;
    _workoutPlanGenerating = true;
    notifyListeners();
    
    final tpl = await _aiService.generateWorkoutPlan(profile);
    if (tpl.isNotEmpty) {
      final version = (_currentGeneration?.version ?? 0) + 1;
      final gen = PlanGeneration(
        id: 'gen_${userId}_$version',
        userId: userId,
        version: version,
        goalSnapshot: 'Goal: ${profile.goal.name}',
        createdAt: DateTime.now(),
      );
      await _repository.savePlanGeneration(userId: userId, generation: gen);
      
      for (int i = 0; i < 30; i++) {
        final dayPlan = WorkoutDay(
          dayNumber: i + 1, 
          focusVi: tpl[i % tpl.length].focusVi, 
          exercises: tpl[i % tpl.length].exercises
        );
        await _repository.saveWorkoutPlan(userId: userId, generationId: gen.id, dayIndex: i + 1, plan: dayPlan);
      }
      
      if (_currentGeneration != null) {
        for (int i = 0; i < 30; i++) {
          final m = await _repository.getMealPlan(userId: userId, version: _currentGeneration!.version, dayIndex: i + 1);
          if (m != null) {
            await _repository.saveMealPlan(userId: userId, generationId: gen.id, dayIndex: i + 1, plan: m);
          }
        }
      }
      
      _currentGeneration = gen;
      
      // Load into lists
      final workouts = <WorkoutDay>[];
      for (int i = 1; i <= 30; i++) {
        final w = await _repository.getWorkoutPlan(userId: userId, version: gen.version, dayIndex: i);
        if (w != null) workouts.add(w);
      }
      _generationWorkoutPlans = workouts;
      
      if (_currentDayIndex >= 1 && _currentDayIndex <= 30) {
        _currentWorkoutPlan = await _repository.getWorkoutPlan(userId: userId, version: gen.version, dayIndex: _currentDayIndex);
        _currentMealPlan = await _repository.getMealPlan(userId: userId, version: gen.version, dayIndex: _currentDayIndex);
      }
      
      _spendTokens(TokenCosts.adaptiveWeeklyPlan);
    }
    _workoutPlanGenerating = false;
    notifyListeners();
    return tpl.isNotEmpty;
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
      _spendTokens(type == CoachType.wellness
          ? TokenCosts.basicAiChat
          : TokenCosts.advancedCoachAnswer);

      String displayReply = reply;
      if (reply.contains('---ADJUSTMENT---')) {
        final parts = reply.split('---ADJUSTMENT---');
        displayReply = parts[0].trim();
        try {
          final jsonStr = parts[1].trim();
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final reason = data['reason'] as String?;
          if (reason != null && reason.isNotEmpty) {
            await NotificationService.showMealAdjusted('AI: $reason');
          }
        } catch (e) {
          debugPrint('Failed to parse adjustment: $e');
        }
      }

      _chatHistories[type] = [
        ..._chatHistories[type]!,
        ChatMessage(text: displayReply, isUser: false),
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
      final goalChanged = _profile.goal != updatedProfile.goal ||
                          _profile.weightKg != updatedProfile.weightKg ||
                          _profile.heightCm != updatedProfile.heightCm ||
                          _profile.activityLevel != updatedProfile.activityLevel;
      
      final userData = await _repository.saveOnboardingProfile(
        userId: session.userId,
        profile: updatedProfile,
      );
      _applyUserData(userData, notify: true);
      
      if (goalChanged) {
        _session = AppUserSession(
          userId: session.userId,
          email: session.email,
          status: UserStatus.generatingPlan,
        );
        _stage = AppStage.generatingPlan;
        notifyListeners();
        unawaited(_simulatePlanGeneration());
      }
      
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

  void activateTokenPack(TokenPack pack) {
    final transaction = TokenTransaction(
      id: _generateTransactionId('pack'),
      amount: pack.tokens,
      priceK: pack.priceK,
      description: 'Nạp gói ${pack.title}',
      createdAt: DateTime.now(),
    );
    final updatedProfile = _profile.copyWith(
      tokenBalance: _profile.tokenBalance + pack.tokens,
      tokenEarned: _profile.tokenEarned + pack.tokens,
      plan: SubscriptionPlan.free,
      subscriptionMonths: 0,
      subscriptionStartDate: null,
    );
    _profile = updatedProfile;
    _tokenTransactions = [transaction, ..._tokenTransactions];
    notifyListeners();
    _enqueueMutation((userId) {
      return _repository.updateTokenWallet(
        userId: userId,
        tokenBalance: updatedProfile.tokenBalance,
        tokenEarned: updatedProfile.tokenEarned,
        tokenSpent: updatedProfile.tokenSpent,
      );
    });
    unawaited(_persistTokenTransaction(transaction));
  }

  Future<String?> claimCoreHealthMaxTrial() async {
    final session = _session;
    if (session == null) {
      return 'Phiên đăng nhập không hợp lệ.';
    }

    final previousEarned = _profile.tokenEarned;
    final trialProfile = _withStarterTokens(_profile);

    try {
      final userData = await _repository.saveOnboardingProfile(
        userId: session.userId,
        profile: trialProfile,
      );
      _showPostOnboardingOffer = false;
      _applyUserData(userData, notify: false);
      final tokenDelta = userData.profile.tokenEarned - previousEarned;
      if (tokenDelta > 0) {
        await _recordTokenTransaction(
          amount: tokenDelta,
          priceK: 0,
          description: 'Quà tặng đăng ký mới',
        );
      }
      notifyListeners();
      _refreshInsightsBackground();
      return null;
    } catch (e, st) {
      debugPrint('claimCoreHealthMaxTrial error: $e\n$st');
      return 'Không thể kích hoạt token miễn phí lúc này.';
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

  void updateSettings(UserSettings settings) {
    _settings = settings;
    notifyListeners();
    _enqueueMutation((userId) {
      return _repository.updateUserSettings(
        userId: userId,
        settings: settings,
      );
    });
  }

  void toggleWorkoutCompleted(int dayNumber) {
    final wasCompleted = _completedWorkoutDays.contains(dayNumber);
    _enqueueMutation((userId) async {
      final data = await _repository.toggleWorkoutCompleted(
        userId: userId,
        dayNumber: dayNumber,
      );
      if (!wasCompleted) {
        await NotificationService.showWorkoutCompleted(
            data.completedWorkoutDays.length);
      }
      return data;
    });
    
    if (dayNumber == _currentDayIndex) {
      logDailyProgress();
    }
  }

  void toggleMealCompleted(int dayNumber) {
    _enqueueMutation((userId) {
      return _repository.toggleMealCompleted(
        userId: userId,
        dayNumber: dayNumber,
      );
    });
    
    if (dayNumber == _currentDayIndex) {
      logDailyProgress();
    }
  }

  Future<void> logDailyProgress() async {
    final userId = _session?.userId;
    if (userId == null) return;
    
    final dateStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    
    final hasLoggedMeals = _todayMealLogs.isNotEmpty;
    final mealStatus = hasLoggedMeals ? ProgressStatus.completed : ProgressStatus.not_started;
    
    final isWorkoutCompleted = _completedWorkoutDays.contains(_currentDayIndex);
    final workoutStatus = isWorkoutCompleted ? ProgressStatus.completed : ProgressStatus.not_started;
    
    int eatenCal = 0;
    for (final m in _todayMealLogs) {
      eatenCal += m.calories;
    }
    
    final progress = DailyProgress(
      id: 'prog_${userId}_$dateStr',
      userId: userId,
      date: dateStr,
      mealStatus: mealStatus,
      workoutStatus: workoutStatus,
      caloriesConsumed: eatenCal,
      weight: profile.weightKg,
      waterIntake: _todayProgress?.waterIntake ?? 0,
      steps: _todayProgress?.steps ?? 0,
      sleepHours: _todayProgress?.sleepHours ?? 0,
      completionScore: (mealStatus == ProgressStatus.completed && workoutStatus == ProgressStatus.completed) ? 100 : 50,
      createdAt: DateTime.now(),
    );
    
    await _repository.saveDailyProgress(userId: userId, progress: progress);
    _todayProgress = progress;
    notifyListeners();
  }

  void _refreshInsightsBackground() {
    if (!_profile.hasAiCoach) return;
    refreshInsights().ignore();
  }

  void _applyAuthentication(AuthResult result) {
    _session = result.session;
    _applyUserData(result.userData, notify: false);
    _currentTab = 0;
    switch (result.session.status) {
      case UserStatus.active:
      case UserStatus.pendingOnboarding:
        _stage = AppStage.home;
        break;
      case UserStatus.generatingPlan:
      case UserStatus.planFailed:
        _stage = AppStage.generatingPlan;
        break;
    }
    notifyListeners();
    unawaited(_loadTokenTransactions());
  }

  void _applyUserData(PersistedUserData data, {required bool notify}) {
    final oldProfile = _profile;
    _profile = data.profile;
    _weightHistory = data.weightHistory;
    _completedWorkoutDays = data.completedWorkoutDays;
    _completedMealDays = data.completedMealDays;
    _cart = data.cart;
    _orders = data.orders;
    _settings = data.settings;
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
      _currentGeneration = null;
      _currentMealPlan = null;
      _currentWorkoutPlan = null;
      _generationMealPlans = const [];
      _generationWorkoutPlans = const [];
      _aiService.invalidateAllPlanCaches();
    }
    _loadChatSessions();
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
    _tokenTransactions = const [];
    _settings = const UserSettings();
    _showPostOnboardingOffer = false;
    _insights = DemoData.dashboardInsights;
    _chatHistories.clear();
    _chatLoading.clear();
    _chatSessions = const [];
    _activeChatSessionId = null;
    _pendingPasswordResetEmail = null;
    _devPasswordResetOtp = null;
    _currentGeneration = null;
    _currentMealPlan = null;
    _currentWorkoutPlan = null;
    _generationMealPlans = const [];
    _generationWorkoutPlans = const [];
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

  void _spendTokens(int amount) {
    if (amount <= 0 || _profile.hasActiveCoreHealthMaxTrial) return;
    final updatedProfile = _profile.copyWith(
      tokenBalance: (_profile.tokenBalance - amount).clamp(0, 1 << 31).toInt(),
      tokenSpent: _profile.tokenSpent + amount,
    );
    _profile = updatedProfile;
    _enqueueMutation((userId) {
      return _repository.updateTokenWallet(
        userId: userId,
        tokenBalance: updatedProfile.tokenBalance,
        tokenEarned: updatedProfile.tokenEarned,
        tokenSpent: updatedProfile.tokenSpent,
      );
    });
  }

  Future<void> _loadTokenTransactions() async {
    final userId = _session?.userId;
    if (userId == null) return;
    try {
      _tokenTransactions =
          await _repository.getTokenTransactions(userId: userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading token transactions: $e');
    }
  }

  Future<void> _recordTokenTransaction({
    required int amount,
    required int priceK,
    required String description,
  }) async {
    final transaction = TokenTransaction(
      id: _generateTransactionId('token'),
      amount: amount,
      priceK: priceK,
      description: description,
      createdAt: DateTime.now(),
    );
    _tokenTransactions = [transaction, ..._tokenTransactions];
    await _persistTokenTransaction(transaction);
  }

  Future<void> _persistTokenTransaction(TokenTransaction transaction) async {
    final userId = _session?.userId;
    if (userId == null) return;
    try {
      await _repository.addTokenTransaction(
        userId: userId,
        transaction: transaction,
      );
    } catch (e) {
      debugPrint('Error saving token transaction: $e');
    }
  }

  String _generateTransactionId(String prefix) {
    return 'txn_${prefix}_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(9000) + 1000}';
  }

  DemoProfile _withStarterTokens(DemoProfile profile) {
    if (profile.coreHealthMaxTrialExpiresAt != null) {
      return profile;
    }
    if (profile.tokenBalance > 0) {
      return profile.copyWith(
        coreHealthMaxTrialExpiresAt:
            DateTime.now().add(const Duration(days: 7)),
      );
    }
    const starterTokens = 25;
    return profile.copyWith(
      plan: SubscriptionPlan.free,
      subscriptionMonths: 0,
      subscriptionStartDate: null,
      tokenBalance: profile.tokenBalance + starterTokens,
      tokenEarned: profile.tokenEarned + starterTokens,
      coreHealthMaxTrialExpiresAt: DateTime.now().add(const Duration(days: 7)),
    );
  }

  DemoProfile _preserveAccountFields(DemoProfile profile) {
    return profile.copyWith(
      tokenBalance: _profile.tokenBalance,
      tokenEarned: _profile.tokenEarned,
      tokenSpent: _profile.tokenSpent,
      referralCode: _profile.referralCode,
      referredBy: _profile.referredBy,
      subscriptionStartDate: _profile.subscriptionStartDate,
      coreHealthMaxTrialExpiresAt: _profile.coreHealthMaxTrialExpiresAt,
    );
  }

  Future<void> _loadChatSessions() async {
    final userId = _session?.userId;
    if (userId == null) return;
    try {
      final sessions = await _repository.getChatSessions(userId: userId);
      _chatSessions = sessions;
      if (_activeChatSessionId == null && _chatSessions.isNotEmpty) {
        _activeChatSessionId = _chatSessions.first.id;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chat sessions: $e');
    }
  }

  void selectChatSession(String? sessionId) {
    _activeChatSessionId = sessionId;
    notifyListeners();
  }

  void startNewChatSession() {
    _activeChatSessionId = null;
    notifyListeners();
  }

  Future<void> deleteChatSession(String sessionId) async {
    final userId = _session?.userId;
    if (userId == null) return;
    try {
      await _repository.deleteChatSession(userId: userId, sessionId: sessionId);
      _chatSessions = _chatSessions.where((s) => s.id != sessionId).toList();
      if (_activeChatSessionId == sessionId) {
        _activeChatSessionId =
            _chatSessions.isNotEmpty ? _chatSessions.first.id : null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting chat session: $e');
    }
  }

  Future<void> sendSessionChatMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userId = _session?.userId;
    if (userId == null) return;
    if (_chatLoading[CoachType.wellness] == true) return;

    final sessionId = _activeChatSessionId ?? _generateUuid();
    ChatSession? existingSession;
    final existingIndex = _chatSessions.indexWhere((s) => s.id == sessionId);
    if (existingIndex != -1) {
      existingSession = _chatSessions[existingIndex];
    }

    final title = existingSession != null
        ? existingSession.title
        : (text.trim().length > 30
            ? '${text.trim().substring(0, 30)}...'
            : text.trim());

    final category = existingSession != null
        ? existingSession.category
        : _classifyCategory(text.trim());

    final oldHistory =
        existingSession != null ? existingSession.history : <ChatMessage>[];
    final updatedHistory = [
      ...oldHistory,
      ChatMessage(text: text.trim(), isUser: true),
    ];

    final tempSession = ChatSession(
      id: sessionId,
      title: title,
      ts: DateTime.now().millisecondsSinceEpoch,
      history: updatedHistory,
      category: category,
    );

    _chatLoading[CoachType.wellness] = true;
    _activeChatSessionId = sessionId;
    _chatSessions = [
      tempSession,
      ..._chatSessions.where((s) => s.id != sessionId),
    ];
    notifyListeners();

    try {
      await _repository.saveChatSession(userId: userId, session: tempSession);

      final reply = await _aiService.chat(
        userMessage: text.trim(),
        profile: _profile,
        history: oldHistory,
        coachType: CoachType.wellness,
      );

      _spendTokens(TokenCosts.basicAiChat);

      final finalHistory = [
        ...updatedHistory,
        ChatMessage(text: reply, isUser: false),
      ];

      final finalSession = ChatSession(
        id: sessionId,
        title: title,
        ts: DateTime.now().millisecondsSinceEpoch,
        history: finalHistory,
        category: category,
      );

      _chatSessions = [
        finalSession,
        ..._chatSessions.where((s) => s.id != sessionId),
      ];
      await _repository.saveChatSession(userId: userId, session: finalSession);
    } catch (e) {
      final errorHistory = [
        ...updatedHistory,
        const ChatMessage(
            text: 'Xin lỗi, có lỗi kết nối xảy ra.', isUser: false),
      ];
      final errorSession = ChatSession(
        id: sessionId,
        title: title,
        ts: DateTime.now().millisecondsSinceEpoch,
        history: errorHistory,
        category: category,
      );
      _chatSessions = [
        errorSession,
        ..._chatSessions.where((s) => s.id != sessionId),
      ];
    } finally {
      _chatLoading[CoachType.wellness] = false;
      notifyListeners();
    }
  }

  void declineAiAdjustment(String sessionId, int msgIndex) {
    final existingIndex = _chatSessions.indexWhere((s) => s.id == sessionId);
    if (existingIndex == -1) return;
    
    final session = _chatSessions[existingIndex];
    if (msgIndex < 0 || msgIndex >= session.history.length) return;
    
    final oldMsg = session.history[msgIndex];
    final parts = oldMsg.text.split('---ADJUSTMENT---');
    if (parts.length < 2) return;
    
    final newText = '${parts[0].trim()}\n\n💼 Đã giữ nguyên kế hoạch hiện tại.';
    
    final newHistory = List<ChatMessage>.from(session.history);
    newHistory[msgIndex] = oldMsg.copyWith(text: newText);
    
    final newSession = ChatSession(
      id: session.id,
      title: session.title,
      ts: session.ts,
      history: newHistory,
      category: session.category,
    );
    
    _chatSessions = [
      ..._chatSessions.sublist(0, existingIndex),
      newSession,
      ..._chatSessions.sublist(existingIndex + 1),
    ];
    notifyListeners();
    final userId = _session?.userId;
    if (userId != null) {
      _repository.saveChatSession(userId: userId, session: newSession).ignore();
    }
  }

  Future<void> applyAiAdjustment(String sessionId, int msgIndex, Map<String, dynamic> adjustment) async {
    final existingIndex = _chatSessions.indexWhere((s) => s.id == sessionId);
    if (existingIndex == -1) return;
    
    final session = _chatSessions[existingIndex];
    if (msgIndex < 0 || msgIndex >= session.history.length) return;
    
    final oldMsg = session.history[msgIndex];
    final parts = oldMsg.text.split('---ADJUSTMENT---');
    if (parts.length < 2) return;
    
    final userId = _session?.userId;
    if (userId != null && _currentGeneration != null) {
      await AiCommandProcessor.processCommand(
        userId: userId,
        adjustment: adjustment,
        currentGeneration: _currentGeneration!,
        repository: _repository,
        currentDayIndex: _currentDayIndex,
      );
      
      // Reload everything
      await _loadSyncData();
    }
    
    final newText = '${parts[0].trim()}\n\n✅ Đã áp dụng thay đổi vào kế hoạch của bạn.';
    
    final newHistory = List<ChatMessage>.from(session.history);
    newHistory[msgIndex] = oldMsg.copyWith(text: newText);
    
    final newSession = ChatSession(
      id: session.id,
      title: session.title,
      ts: session.ts,
      history: newHistory,
      category: session.category,
    );
    
    _chatSessions = [
      ..._chatSessions.sublist(0, existingIndex),
      newSession,
      ..._chatSessions.sublist(existingIndex + 1),
    ];
    notifyListeners();
    if (userId != null) {
      _repository.saveChatSession(userId: userId, session: newSession).ignore();
    }
  }

  String _classifyCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('tập') ||
        lower.contains('cardio') ||
        lower.contains('gym') ||
        lower.contains('chạy') ||
        lower.contains('cơ') ||
        lower.contains('lịch tập') ||
        lower.contains('workout') ||
        lower.contains('tập luyện')) {
      return 'Workout';
    }
    if (lower.contains('ăn') ||
        lower.contains('calo') ||
        lower.contains('macro') ||
        lower.contains('dinh dưỡng') ||
        lower.contains('thực đơn') ||
        lower.contains('protein') ||
        lower.contains('chay') ||
        lower.contains('nutrition') ||
        lower.contains('bữa ăn')) {
      return 'Nutrition';
    }
    if (lower.contains('form') ||
        lower.contains('tư thế') ||
        lower.contains('động tác') ||
        lower.contains('đúng cách') ||
        lower.contains('kỹ thuật') ||
        lower.contains('knee') ||
        lower.contains('squat')) {
      return 'Form';
    }
    return 'General';
  }

  String _generateUuid() {
    final random = math.Random();
    return List.generate(
            16, (i) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
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
