enum AppStage { welcome, intro, auth, verifyOtp, onboarding, generatingPlan, home }

enum UserStatus {
  pendingOnboarding,
  generatingPlan,
  planFailed,
  active,
}

enum AuthMode { signIn, signUp }

enum SubscriptionPlan { free, meal, workout, max }

enum TokenPackId { starter, basic, plus, pro, max, power, elite, founder }

enum GoalType { loseWeight, maintain, gainMuscle }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

enum Gender { female, male, other }

enum CoachType { nutrition, workout, wellness }

class UserSettings {
  const UserSettings({
    this.waterReminderEnabled = true,
    this.workoutReminderEnabled = true,
    this.weeklyWeightReminderEnabled = false,
    this.language = 'Tiếng Việt',
  });

  final bool waterReminderEnabled;
  final bool workoutReminderEnabled;
  final bool weeklyWeightReminderEnabled;
  final String language;

  UserSettings copyWith({
    bool? waterReminderEnabled,
    bool? workoutReminderEnabled,
    bool? weeklyWeightReminderEnabled,
    String? language,
  }) {
    return UserSettings(
      waterReminderEnabled: waterReminderEnabled ?? this.waterReminderEnabled,
      workoutReminderEnabled:
          workoutReminderEnabled ?? this.workoutReminderEnabled,
      weeklyWeightReminderEnabled:
          weeklyWeightReminderEnabled ?? this.weeklyWeightReminderEnabled,
      language: language ?? this.language,
    );
  }
}

class AppUserSession {
  const AppUserSession({
    required this.userId,
    required this.email,
    required this.status,
  });

  final String userId;
  final String email;
  final UserStatus status;
}

/// Rich fitness-survey fields shared 1:1 with the web onboarding
/// (CoreHealth-FE buildProfilePayload). Same keys + value IDs so the BE AI
/// planner (AiController.planProfile) reads identical data from web or mobile.
class FitnessSurvey {
  const FitnessSurvey({
    this.bodyFatPercent,
    this.waistCm,
    this.weeklyChangeKg = 0.25,
    this.timelineWeeks = 12,
    this.priority = 'balanced',
    this.trainingExperience = 'beginner',
    this.workoutLocation = 'gym',
    this.equipment = const ['full-gym'],
    this.daysPerWeek = 4,
    this.sessionMinutes = 60,
    this.preferredWorkoutTime = 'evening',
    this.injuries = '',
    this.medicalNotes = '',
    this.dietType = 'high-protein',
    this.mealFrequency = '3 meals + 1 snack',
    this.cookingTimeMinutes = 30,
    this.budget = 'moderate',
    this.dislikedFoods = const [],
    this.preferredCuisines = const [],
    this.supplements = const [],
  });

  final double? bodyFatPercent;
  final double? waistCm;
  final double weeklyChangeKg;
  final int timelineWeeks;
  final String priority; // balanced | nutrition | training | health
  final String trainingExperience; // beginner | intermediate | advanced
  final String workoutLocation; // gym | home | outdoor
  final List<String> equipment;
  final int daysPerWeek;
  final int sessionMinutes;
  final String preferredWorkoutTime; // morning | afternoon | evening | flexible
  final String injuries;
  final String medicalNotes;
  final String dietType; // balanced | high-protein | mediterranean | low-carb | plant-forward | keto
  final String mealFrequency;
  final int cookingTimeMinutes;
  final String budget; // low | moderate | premium
  final List<String> dislikedFoods;
  final List<String> preferredCuisines;
  final List<String> supplements;

  Map<String, dynamic> toJson() => {
        'bodyFatPercent': bodyFatPercent,
        'waistCm': waistCm,
        'weeklyChangeKg': weeklyChangeKg,
        'timelineWeeks': timelineWeeks,
        'priority': priority,
        'trainingExperience': trainingExperience,
        'workoutLocation': workoutLocation,
        'equipment': equipment,
        'daysPerWeek': daysPerWeek,
        'sessionMinutes': sessionMinutes,
        'preferredWorkoutTime': preferredWorkoutTime,
        'injuries': injuries,
        'medicalNotes': medicalNotes,
        'dietType': dietType,
        'mealFrequency': mealFrequency,
        'cookingTimeMinutes': cookingTimeMinutes,
        'budget': budget,
        'dislikedFoods': dislikedFoods,
        'preferredCuisines': preferredCuisines,
        'supplements': supplements,
      };

  factory FitnessSurvey.fromJson(Map<String, dynamic> j) => FitnessSurvey(
        bodyFatPercent: (j['bodyFatPercent'] as num?)?.toDouble(),
        waistCm: (j['waistCm'] as num?)?.toDouble(),
        weeklyChangeKg: (j['weeklyChangeKg'] as num?)?.toDouble() ?? 0.25,
        timelineWeeks: (j['timelineWeeks'] as num?)?.toInt() ?? 12,
        priority: j['priority'] as String? ?? 'balanced',
        trainingExperience: j['trainingExperience'] as String? ?? 'beginner',
        workoutLocation: j['workoutLocation'] as String? ?? 'gym',
        equipment: _strList(j['equipment'], const ['full-gym']),
        daysPerWeek: (j['daysPerWeek'] as num?)?.toInt() ?? 4,
        sessionMinutes: (j['sessionMinutes'] as num?)?.toInt() ?? 60,
        preferredWorkoutTime: j['preferredWorkoutTime'] as String? ?? 'evening',
        injuries: j['injuries'] as String? ?? '',
        medicalNotes: j['medicalNotes'] as String? ?? '',
        dietType: j['dietType'] as String? ?? 'high-protein',
        mealFrequency: j['mealFrequency'] as String? ?? '3 meals + 1 snack',
        cookingTimeMinutes: (j['cookingTimeMinutes'] as num?)?.toInt() ?? 30,
        budget: j['budget'] as String? ?? 'moderate',
        dislikedFoods: _strList(j['dislikedFoods'], const []),
        preferredCuisines: _strList(j['preferredCuisines'], const []),
        supplements: _strList(j['supplements'], const []),
      );

  FitnessSurvey copyWith({
    double? bodyFatPercent,
    double? waistCm,
    double? weeklyChangeKg,
    int? timelineWeeks,
    String? priority,
    String? trainingExperience,
    String? workoutLocation,
    List<String>? equipment,
    int? daysPerWeek,
    int? sessionMinutes,
    String? preferredWorkoutTime,
    String? injuries,
    String? medicalNotes,
    String? dietType,
    String? mealFrequency,
    int? cookingTimeMinutes,
    String? budget,
    List<String>? dislikedFoods,
    List<String>? preferredCuisines,
    List<String>? supplements,
  }) =>
      FitnessSurvey(
        bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
        waistCm: waistCm ?? this.waistCm,
        weeklyChangeKg: weeklyChangeKg ?? this.weeklyChangeKg,
        timelineWeeks: timelineWeeks ?? this.timelineWeeks,
        priority: priority ?? this.priority,
        trainingExperience: trainingExperience ?? this.trainingExperience,
        workoutLocation: workoutLocation ?? this.workoutLocation,
        equipment: equipment ?? this.equipment,
        daysPerWeek: daysPerWeek ?? this.daysPerWeek,
        sessionMinutes: sessionMinutes ?? this.sessionMinutes,
        preferredWorkoutTime: preferredWorkoutTime ?? this.preferredWorkoutTime,
        injuries: injuries ?? this.injuries,
        medicalNotes: medicalNotes ?? this.medicalNotes,
        dietType: dietType ?? this.dietType,
        mealFrequency: mealFrequency ?? this.mealFrequency,
        cookingTimeMinutes: cookingTimeMinutes ?? this.cookingTimeMinutes,
        budget: budget ?? this.budget,
        dislikedFoods: dislikedFoods ?? this.dislikedFoods,
        preferredCuisines: preferredCuisines ?? this.preferredCuisines,
        supplements: supplements ?? this.supplements,
      );

  static List<String> _strList(Object? v, List<String> fallback) =>
      v is List ? v.map((e) => e.toString()).toList() : fallback;
}

class DemoProfile {
  const DemoProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    required this.goal,
    required this.activityLevel,
    required this.schedule,
    required this.dietaryRestrictions,
    required this.allergies,
    required this.healthConditions,
    this.trainingFrequency = '',
    this.focusAreas = const [],
    this.preferredActivities = const [],
    this.mealBudget = '',
    this.cookingTime = '',
    this.nutritionPriorities = const [],
    required this.plan,
    required this.subscriptionMonths,
    this.tokenBalance = 0,
    this.tokenEarned = 0,
    this.tokenSpent = 0,
    this.referralCode = '',
    this.referredBy = '',
    this.subscriptionStartDate,
    this.coreHealthMaxTrialExpiresAt,
    this.aiPlanVersion = 1,
    this.survey = const FitnessSurvey(),
  });

  final String name;
  final int age;
  final Gender gender;
  final double heightCm;
  final double weightKg;
  final double targetWeightKg;
  final GoalType goal;
  final ActivityLevel activityLevel;
  final String schedule;

  /// Dietary preferences the user voluntarily avoids (ăn chay, ít đường…)
  final List<String> dietaryRestrictions;

  /// Food allergies — medically significant, must never be ignored by AI (dị ứng)
  final List<String> allergies;

  /// Diagnosed health conditions affecting recommendations (bệnh án)
  final List<String> healthConditions;
  final String trainingFrequency;
  final List<String> focusAreas;
  final List<String> preferredActivities;
  final String mealBudget;
  final String cookingTime;
  final List<String> nutritionPriorities;
  final SubscriptionPlan plan;
  final int subscriptionMonths;
  final int tokenBalance;
  final int tokenEarned;
  final int tokenSpent;
  final String referralCode;
  final String referredBy;

  /// The exact moment this subscription was activated. Null = demo/free (no expiry check).
  final DateTime? subscriptionStartDate;

  /// New-user CoreHealth Max trial. This is tracked separately from paid plan
  /// expiry so a user can buy Meal/Workout while still keeping Max trial access.
  final DateTime? coreHealthMaxTrialExpiresAt;

  final int aiPlanVersion;

  /// Full fitness-survey payload shared 1:1 with the web onboarding.
  final FitnessSurvey survey;

  double get bmi {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final heightInMeters = heightCm / 100;
    return weightKg / (heightInMeters * heightInMeters);
  }

  /// Asian WHO standard (used in Vietnam): <18.5 / 18.5-22.9 / 23-24.9 / 25-29.9 / ≥30
  String get bmiCategory {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 23.0) return 'Bình thường';
    if (bmi < 25.0) return 'Thừa cân nhẹ';
    if (bmi < 30.0) return 'Béo phì độ I';
    return 'Béo phì độ II';
  }

  /// Ideal weight range for Asian BMI 18.5–22.9 at this height
  double get idealWeightMinKg {
    final h = heightCm / 100;
    return 18.5 * h * h;
  }

  double get idealWeightMaxKg {
    final h = heightCm / 100;
    return 22.9 * h * h;
  }

  /// kg to gain (positive) or lose (negative) to enter normal range; 0 if already normal
  double get weightDeltaKg {
    if (weightKg < idealWeightMinKg) return idealWeightMinKg - weightKg;
    if (weightKg > idealWeightMaxKg) return idealWeightMaxKg - weightKg;
    return 0;
  }

  /// BMR via Mifflin-St Jeor (kcal/day)
  double get bmr {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5.0 * age);
    return gender == Gender.male ? base + 5 : base - 161;
  }

  double get _activityMultiplier => switch (activityLevel) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.light => 1.375,
        ActivityLevel.moderate => 1.55,
        ActivityLevel.active => 1.725,
        ActivityLevel.veryActive => 1.9,
      };

  /// Total Daily Energy Expenditure (kcal/day)
  double get tdee => bmr * _activityMultiplier;

  /// Estimated body fat % via Deurenberg 1991 (validated for Asian adults)
  double get bodyFatPercent {
    final sexFactor = gender == Gender.male ? 1.0 : 0.0;
    return (1.20 * bmi) + (0.23 * age) - (10.8 * sexFactor) - 5.4;
  }

  /// Computed expiry date: subscriptionStartDate + subscriptionMonths.
  /// Null when plan is free or start date is unknown.
  DateTime? get subscriptionExpiresAt {
    if (plan == SubscriptionPlan.free || subscriptionStartDate == null) {
      return null;
    }
    final start = subscriptionStartDate!;
    final rawMonth = start.month + subscriptionMonths;
    final year = start.year + ((rawMonth - 1) ~/ 12);
    final month = ((rawMonth - 1) % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = start.day > lastDay ? lastDay : start.day;
    return DateTime(year, month, day, 23, 59, 59);
  }

  /// True when a paid plan has passed its expiry date.
  bool get isSubscriptionExpired {
    final expiry = subscriptionExpiresAt;
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  bool get hasActiveCoreHealthMaxTrial {
    final expiry = coreHealthMaxTrialExpiresAt;
    return expiry != null && DateTime.now().isBefore(expiry);
  }

  /// Remaining days before expiry. Null for free/unknown. Negative means expired.
  int? get daysUntilExpiry {
    final expiry = subscriptionExpiresAt;
    if (expiry == null) return null;
    return expiry.difference(DateTime.now()).inDays;
  }

  bool get hasMealPlan =>
      hasActiveCoreHealthMaxTrial || tokenBalance >= TokenCosts.fullDayMealPlan;

  bool get hasWorkoutPlan =>
      hasActiveCoreHealthMaxTrial ||
      tokenBalance >= TokenCosts.adaptiveWeeklyPlan;

  bool get hasAiCoach =>
      hasActiveCoreHealthMaxTrial || tokenBalance >= TokenCosts.basicAiChat;

  bool canAccessCoach(CoachType type) => switch (type) {
        CoachType.nutrition => hasMealPlan,
        CoachType.workout => hasWorkoutPlan,
        CoachType.wellness => hasAiCoach,
      };

  DemoProfile copyWith({
    String? name,
    int? age,
    Gender? gender,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    GoalType? goal,
    ActivityLevel? activityLevel,
    String? schedule,
    List<String>? dietaryRestrictions,
    List<String>? allergies,
    List<String>? healthConditions,
    String? trainingFrequency,
    List<String>? focusAreas,
    List<String>? preferredActivities,
    String? mealBudget,
    String? cookingTime,
    List<String>? nutritionPriorities,
    SubscriptionPlan? plan,
    int? subscriptionMonths,
    int? tokenBalance,
    int? tokenEarned,
    int? tokenSpent,
    String? referralCode,
    String? referredBy,
    int? aiPlanVersion,
    FitnessSurvey? survey,
    // Use Object? sentinel so callers can explicitly pass null to clear the date.
    Object? subscriptionStartDate = _keep,
    Object? coreHealthMaxTrialExpiresAt = _keep,
  }) {
    return DemoProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      schedule: schedule ?? this.schedule,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      allergies: allergies ?? this.allergies,
      healthConditions: healthConditions ?? this.healthConditions,
      trainingFrequency: trainingFrequency ?? this.trainingFrequency,
      focusAreas: focusAreas ?? this.focusAreas,
      preferredActivities: preferredActivities ?? this.preferredActivities,
      mealBudget: mealBudget ?? this.mealBudget,
      cookingTime: cookingTime ?? this.cookingTime,
      nutritionPriorities: nutritionPriorities ?? this.nutritionPriorities,
      plan: plan ?? this.plan,
      subscriptionMonths: subscriptionMonths ?? this.subscriptionMonths,
      tokenBalance: tokenBalance ?? this.tokenBalance,
      tokenEarned: tokenEarned ?? this.tokenEarned,
      tokenSpent: tokenSpent ?? this.tokenSpent,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      subscriptionStartDate: subscriptionStartDate == _keep
          ? this.subscriptionStartDate
          : subscriptionStartDate as DateTime?,
      coreHealthMaxTrialExpiresAt: coreHealthMaxTrialExpiresAt == _keep
          ? this.coreHealthMaxTrialExpiresAt
          : coreHealthMaxTrialExpiresAt as DateTime?,
      aiPlanVersion: aiPlanVersion ?? this.aiPlanVersion,
      survey: survey ?? this.survey,
    );
  }
}

class TokenPack {
  const TokenPack({
    required this.id,
    required this.title,
    required this.priceK,
    required this.tokens,
    required this.description,
    this.recommended = false,
  });

  final TokenPackId id;
  final String title;
  final int priceK;
  final int tokens;
  final String description;
  final bool recommended;

  String get idValue => id.name;
  int get pricePerToken => (priceK * 1000 / tokens).round();
}

class TokenTransaction {
  const TokenTransaction({
    required this.id,
    required this.amount,
    required this.priceK,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final int amount;
  final int priceK;
  final String description;
  final DateTime createdAt;

  bool get isCredit => amount >= 0;
}

class TokenCosts {
  const TokenCosts._();

  static const int basicAiChat = 1;
  static const int advancedCoachAnswer = 3;
  static const int fullDayMealPlan = 12;
  static const int foodScan = 3;
  static const int adaptiveWeeklyPlan = 20;
}

const tokenPacks = <TokenPack>[
  TokenPack(
    id: TokenPackId.starter,
    title: 'Starter',
    priceK: 49,
    tokens: 55,
    description: 'Nạp nhanh để thử AI plan và scan.',
  ),
  TokenPack(
    id: TokenPackId.basic,
    title: 'Basic',
    priceK: 99,
    tokens: 120,
    description: 'Mệnh giá phổ biến nhất cho user mới bắt đầu.',
    recommended: true,
  ),
  TokenPack(
    id: TokenPackId.plus,
    title: 'Plus',
    priceK: 149,
    tokens: 190,
    description: 'Thoải mái generate plan và refresh nhiều lần hơn.',
  ),
  TokenPack(
    id: TokenPackId.pro,
    title: 'Pro',
    priceK: 199,
    tokens: 260,
    description: 'Đủ cho nhiều lần generate plan và top-up chat.',
  ),
  TokenPack(
    id: TokenPackId.max,
    title: 'Max',
    priceK: 299,
    tokens: 420,
    description: 'Phù hợp user dùng AI đều mỗi tuần.',
  ),
  TokenPack(
    id: TokenPackId.power,
    title: 'Power',
    priceK: 499,
    tokens: 760,
    description: 'Dành cho người dùng AI liên tục và scan thường xuyên.',
  ),
  TokenPack(
    id: TokenPackId.elite,
    title: 'Elite',
    priceK: 799,
    tokens: 1280,
    description: 'Pack lớn cho usage cao, tiết kiệm hơn theo token.',
  ),
  TokenPack(
    id: TokenPackId.founder,
    title: 'Founder',
    priceK: 1000,
    tokens: 1650,
    description: 'Mệnh giá cao nhất để scale usage dài hạn.',
  ),
];

// Sentinel so copyWith can distinguish "not passed" from "explicitly null".
const Object _keep = Object();

class MealLog {
  const MealLog({
    required this.id,
    required this.slotLabel,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
  });

  final String id;
  final String slotLabel;
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime loggedAt;

  String get dateKey {
    final d = loggedAt;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class WeightEntry {
  const WeightEntry({required this.label, required this.weight});

  final String label;
  final double weight;
}

class InsightItem {
  const InsightItem({
    required this.title,
    required this.message,
    required this.accent,
  });

  final String title;
  final String message;
  final String accent;
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  ChatMessage copyWith({
    String? text,
    bool? isUser,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
    );
  }
}

class ChatSession {
  ChatSession({
    required this.id,
    required this.title,
    required this.history,
    required this.ts,
    this.category = 'General',
  });

  final String id;
  final String title;
  final List<ChatMessage> history;
  final int ts;
  final String category;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'history':
            history.map((m) => {'text': m.text, 'isUser': m.isUser}).toList(),
        'ts': ts,
        'category': category,
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final list = json['history'] as List? ?? [];
    final historyList = list.map((item) {
      final map = item as Map<String, dynamic>;
      return ChatMessage(
        text: map['text'] as String? ?? '',
        isUser: map['isUser'] as bool? ?? false,
      );
    }).toList();
    return ChatSession(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Cuộc trò chuyện mới',
      history: historyList,
      ts: json['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      category: json['category'] as String? ?? 'General',
    );
  }
}

class MealItem {
  const MealItem({
    required this.id,
    required this.nameVi,
    required this.slotLabel,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.imageUrl,
    required this.ingredients,
  });

  final String id;
  final String nameVi;
  final String slotLabel;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String imageUrl;
  final List<String> ingredients;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameVi': nameVi,
        'slotLabel': slotLabel,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'imageUrl': imageUrl,
        'ingredients': ingredients,
      };

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
        id: json['id'] as String? ?? '',
        nameVi: json['nameVi'] as String? ?? '',
        slotLabel: json['slotLabel'] as String? ?? '',
        calories: json['calories'] as int? ?? 0,
        protein: json['protein'] as int? ?? 0,
        carbs: json['carbs'] as int? ?? 0,
        fat: json['fat'] as int? ?? 0,
        imageUrl: json['imageUrl'] as String? ?? '',
        ingredients: (json['ingredients'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class MealPlanDay {
  const MealPlanDay({
    required this.dayNumber,
    required this.meals,
  });

  final int dayNumber;
  final List<MealItem> meals;

  int get totalCalories => meals.fold(0, (sum, meal) => sum + meal.calories);
  int get totalProtein => meals.fold(0, (sum, meal) => sum + meal.protein);
  int get totalCarbs => meals.fold(0, (sum, meal) => sum + meal.carbs);
  int get totalFat => meals.fold(0, (sum, meal) => sum + meal.fat);

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'meals': meals.map((m) => m.toJson()).toList(),
      };

  factory MealPlanDay.fromJson(Map<String, dynamic> json) => MealPlanDay(
        dayNumber: json['dayNumber'] as int? ?? 1,
        meals: (json['meals'] as List<dynamic>?)
                ?.map((e) => MealItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.nameVi,
    required this.description,
    this.sets,
    this.reps,
    this.durationMinutes,
    required this.caloriesBurned,
  });

  final String id;
  final String nameVi;
  final String description;
  final int? sets;
  final String? reps;
  final int? durationMinutes;
  final int caloriesBurned;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameVi': nameVi,
        'description': description,
        if (sets != null) 'sets': sets,
        if (reps != null) 'reps': reps,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
      };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        id: json['id'] as String? ?? '',
        nameVi: json['nameVi'] as String? ?? '',
        description: json['description'] as String? ?? '',
        sets: json['sets'] as int?,
        reps: json['reps'] as String?,
        durationMinutes: json['durationMinutes'] as int?,
        caloriesBurned: json['caloriesBurned'] as int? ?? 0,
      );
}

class WorkoutDay {
  const WorkoutDay({
    required this.dayNumber,
    required this.focusVi,
    required this.exercises,
  });

  final int dayNumber;
  final String focusVi;
  final List<WorkoutExercise> exercises;

  int get totalDuration => exercises.fold(
        0,
        (sum, item) => sum + (item.durationMinutes ?? ((item.sets ?? 1) * 3)),
      );

  int get totalCalories =>
      exercises.fold(0, (sum, item) => sum + item.caloriesBurned);

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'focusVi': focusVi,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) => WorkoutDay(
        dayNumber: json['dayNumber'] as int? ?? 1,
        focusVi: json['focusVi'] as String? ?? '',
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class Product {
  const Product({
    required this.id,
    required this.nameVi,
    required this.categoryId,
    required this.unit,
    required this.priceK,
    required this.imageUrl,
    required this.hot,
  });

  final String id;
  final String nameVi;
  final String categoryId;
  final String unit;
  final int priceK;
  final String imageUrl;
  final bool hot;
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.dateLabel,
    required this.itemCount,
    required this.totalK,
    required this.statusLabel,
  });

  final String id;
  final String dateLabel;
  final int itemCount;
  final int totalK;
  final String statusLabel;
}

extension GoalTypeLabel on GoalType {
  String get title {
    switch (this) {
      case GoalType.loseWeight:
        return 'Giảm cân';
      case GoalType.maintain:
        return 'Duy trì';
      case GoalType.gainMuscle:
        return 'Tăng cơ';
    }
  }
}

extension ActivityLevelLabel on ActivityLevel {
  String get title {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Ít vận động';
      case ActivityLevel.light:
        return 'Nhẹ';
      case ActivityLevel.moderate:
        return 'Trung bình';
      case ActivityLevel.active:
        return 'Cao';
      case ActivityLevel.veryActive:
        return 'Rất cao';
    }
  }

  String get subtitle {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Ngồi nhiều, ít di chuyển';
      case ActivityLevel.light:
        return 'Tập 1-2 ngày/tuần';
      case ActivityLevel.moderate:
        return 'Tập 3-5 ngày/tuần';
      case ActivityLevel.active:
        return 'Tập gần như mỗi ngày';
      case ActivityLevel.veryActive:
        return 'Cường độ cao và đều';
    }
  }
}

extension GenderLabel on Gender {
  String get title {
    switch (this) {
      case Gender.female:
        return 'Nữ';
      case Gender.male:
        return 'Nam';
      case Gender.other:
        return 'Khác';
    }
  }
}

extension SubscriptionPlanLabel on SubscriptionPlan {
  String get title {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Miễn phí';
      case SubscriptionPlan.meal:
        return 'CoreHealth Meal';
      case SubscriptionPlan.workout:
        return 'CoreHealth Workout';
      case SubscriptionPlan.max:
        return 'CoreHealth Max';
    }
  }

  String get subtitle {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Trải nghiệm cơ bản';
      case SubscriptionPlan.meal:
        return 'Tập trung dinh dưỡng';
      case SubscriptionPlan.workout:
        return 'Tập trung thể lực';
      case SubscriptionPlan.max:
        return 'Giải pháp toàn diện';
    }
  }
}

class RegisterResponseData {
  const RegisterResponseData({
    required this.success,
    required this.email,
    this.devOtp,
  });

  final bool success;
  final String email;
  final String? devOtp;
}

// ---------------------------------------------------------------------------
// Shipping & delivery
// ---------------------------------------------------------------------------

class ShippingAddress {
  final String name;
  final String phone;
  final String address;
  final int provinceId;
  final int districtId;
  final String wardCode;
  final String? provinceName;
  final String? districtName;
  final String? wardName;

  const ShippingAddress({
    required this.name,
    required this.phone,
    required this.address,
    required this.provinceId,
    required this.districtId,
    required this.wardCode,
    this.provinceName,
    this.districtName,
    this.wardName,
  });

  String get fullAddress {
    final parts = <String>[address];
    if (wardName != null) parts.add(wardName!);
    if (districtName != null) parts.add(districtName!);
    if (provinceName != null) parts.add(provinceName!);
    return parts.join(', ');
  }
}

class GhnOrderDetail {
  final String orderCode;
  final String status;
  final String statusLabel;
  final String toName;
  final String toPhone;
  final String toAddress;
  final int codAmount;
  final int weight;
  final String? leadtime;
  final String? orderDate;
  final String? finishDate;

  const GhnOrderDetail({
    required this.orderCode,
    required this.status,
    required this.statusLabel,
    required this.toName,
    required this.toPhone,
    required this.toAddress,
    required this.codAmount,
    required this.weight,
    this.leadtime,
    this.orderDate,
    this.finishDate,
  });
}

// ---------------------------------------------------------------------------
// Exercise videos
// ---------------------------------------------------------------------------

class ExerciseVideo {
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? videoHlsUrl;

  const ExerciseVideo({
    this.videoUrl,
    this.thumbnailUrl,
    this.videoHlsUrl,
  });

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
}

class OnboardingProgress {
  final int currentStep;
  final List<int> completedSteps;
  final bool isCompleted;

  const OnboardingProgress({
    this.currentStep = 0,
    this.completedSteps = const [],
    this.isCompleted = false,
  });
}

enum AiPlanType { meal, workout, max }
enum AiPlanStatus { generating, ready, failed }

class AiPlan {
  final String id;
  final String userId;
  final AiPlanType type;
  final AiPlanStatus status;
  final Map<String, dynamic> contentJson;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiPlan({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.contentJson,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });
}

// ---------------------------------------------------------------------------
// Architecture V2: AI Synchronization Models
// ---------------------------------------------------------------------------

enum ProgressStatus { not_started, partial, completed }

class DailyProgress {
  const DailyProgress({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealStatus,
    required this.workoutStatus,
    required this.caloriesConsumed,
    required this.weight,
    required this.waterIntake,
    required this.steps,
    required this.sleepHours,
    required this.completionScore,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String date;
  final ProgressStatus mealStatus;
  final ProgressStatus workoutStatus;
  final int caloriesConsumed;
  final double weight;
  final int waterIntake;
  final int steps;
  final double sleepHours;
  final int completionScore;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date,
        'meal_status': mealStatus.name,
        'workout_status': workoutStatus.name,
        'calories_consumed': caloriesConsumed,
        'weight': weight,
        'water_intake': waterIntake,
        'steps': steps,
        'sleep_hours': sleepHours,
        'completion_score': completionScore,
        'created_at': createdAt.toIso8601String(),
      };

  factory DailyProgress.fromJson(Map<String, dynamic> json) => DailyProgress(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        date: json['date'] as String? ?? '',
        mealStatus: ProgressStatus.values.firstWhere(
            (e) => e.name == json['meal_status'],
            orElse: () => ProgressStatus.not_started),
        workoutStatus: ProgressStatus.values.firstWhere(
            (e) => e.name == json['workout_status'],
            orElse: () => ProgressStatus.not_started),
        caloriesConsumed: json['calories_consumed'] as int? ?? 0,
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        waterIntake: json['water_intake'] as int? ?? 0,
        steps: json['steps'] as int? ?? 0,
        sleepHours: (json['sleep_hours'] as num?)?.toDouble() ?? 0.0,
        completionScore: json['completion_score'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );
}

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.isChecked,
    required this.sourceDay,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String itemName;
  final double quantity;
  final String unit;
  final bool isChecked;
  final int sourceDay;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'item_name': itemName,
        'quantity': quantity,
        'unit': unit,
        'is_checked': isChecked ? 1 : 0,
        'source_day': sourceDay,
        'created_at': createdAt.toIso8601String(),
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        itemName: json['item_name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? '',
        isChecked: (json['is_checked'] == 1 || json['is_checked'] == true),
        sourceDay: json['source_day'] as int? ?? 1,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );
}

class PlanGeneration {
  const PlanGeneration({
    required this.id,
    required this.userId,
    required this.version,
    required this.goalSnapshot,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final int version;
  final String goalSnapshot;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'version': version,
        'goal_snapshot': goalSnapshot,
        'created_at': createdAt.toIso8601String(),
      };

  factory PlanGeneration.fromJson(Map<String, dynamic> json) => PlanGeneration(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        version: json['version'] as int? ?? 1,
        goalSnapshot: json['goal_snapshot'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );
}

class AiEvent {
  const AiEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String eventType;
  final String payload;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'event_type': eventType,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
      };

  factory AiEvent.fromJson(Map<String, dynamic> json) => AiEvent(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        eventType: json['event_type'] as String? ?? '',
        payload: json['payload'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );
}
