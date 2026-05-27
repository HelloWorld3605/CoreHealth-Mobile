import 'dart:convert';

import '../demo_data.dart';
import '../models.dart';

class AppStateSnapshot {
  const AppStateSnapshot({
    required this.stage,
    required this.currentTab,
    required this.aiMenuExpanded,
    required this.profile,
    required this.weightHistory,
    required this.todayMeals,
    required this.completedWorkoutDays,
    required this.cart,
    required this.orders,
  });

  factory AppStateSnapshot.seeded() {
    return AppStateSnapshot(
      stage: AppStage.welcome,
      currentTab: 0,
      aiMenuExpanded: false,
      profile: DemoData.initialProfile,
      weightHistory: DemoData.weightEntries,
      todayMeals: DemoData.todayMeals,
      completedWorkoutDays: const {2, 5, 6},
      cart: [DemoData.products[3], DemoData.products[7]],
      orders: DemoData.recentOrders,
    );
  }

  factory AppStateSnapshot.fromDatabaseRow(Map<String, Object?> row) {
    return AppStateSnapshot(
      stage: _enumByName(
        AppStage.values,
        row['stage'] as String?,
        fallback: AppStage.welcome,
      ),
      currentTab: row['current_tab'] as int? ?? 0,
      aiMenuExpanded: (row['ai_menu_expanded'] as int? ?? 0) == 1,
      profile: _decodeObject(
        row['profile_json'] as String?,
        _demoProfileFromJson,
        DemoData.initialProfile,
      ),
      weightHistory: _decodeList(
        row['weight_history_json'] as String?,
        _weightEntryFromJson,
        DemoData.weightEntries,
      ),
      todayMeals: _decodeList(
        row['today_meals_json'] as String?,
        _mealItemFromJson,
        DemoData.todayMeals,
      ),
      completedWorkoutDays: _decodeIntSet(
        row['completed_workout_days_json'] as String?,
        const {2, 5, 6},
      ),
      cart: _decodeList(
        row['cart_json'] as String?,
        _productFromJson,
        [DemoData.products[3], DemoData.products[7]],
      ),
      orders: _decodeList(
        row['orders_json'] as String?,
        _orderSummaryFromJson,
        DemoData.recentOrders,
      ),
    );
  }

  final AppStage stage;
  final int currentTab;
  final bool aiMenuExpanded;
  final DemoProfile profile;
  final List<WeightEntry> weightHistory;
  final List<MealItem> todayMeals;
  final Set<int> completedWorkoutDays;
  final List<Product> cart;
  final List<OrderSummary> orders;

  Map<String, Object?> toDatabaseRow() {
    return {
      'id': 1,
      'stage': stage.name,
      'current_tab': currentTab,
      'ai_menu_expanded': aiMenuExpanded ? 1 : 0,
      'profile_json': jsonEncode(_demoProfileToJson(profile)),
      'weight_history_json':
          jsonEncode(weightHistory.map(_weightEntryToJson).toList()),
      'today_meals_json': jsonEncode(todayMeals.map(_mealItemToJson).toList()),
      'completed_workout_days_json':
          jsonEncode(completedWorkoutDays.toList()..sort()),
      'cart_json': jsonEncode(cart.map(_productToJson).toList()),
      'orders_json': jsonEncode(orders.map(_orderSummaryToJson).toList()),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  AppStateSnapshot copyWith({
    AppStage? stage,
    int? currentTab,
    bool? aiMenuExpanded,
    DemoProfile? profile,
    List<WeightEntry>? weightHistory,
    List<MealItem>? todayMeals,
    Set<int>? completedWorkoutDays,
    List<Product>? cart,
    List<OrderSummary>? orders,
  }) {
    return AppStateSnapshot(
      stage: stage ?? this.stage,
      currentTab: currentTab ?? this.currentTab,
      aiMenuExpanded: aiMenuExpanded ?? this.aiMenuExpanded,
      profile: profile ?? this.profile,
      weightHistory: weightHistory ?? this.weightHistory,
      todayMeals: todayMeals ?? this.todayMeals,
      completedWorkoutDays: completedWorkoutDays ?? this.completedWorkoutDays,
      cart: cart ?? this.cart,
      orders: orders ?? this.orders,
    );
  }
}

T _enumByName<T extends Enum>(
  List<T> values,
  String? raw, {
  required T fallback,
}) {
  if (raw == null) {
    return fallback;
  }

  for (final value in values) {
    if (value.name == raw) {
      return value;
    }
  }

  return fallback;
}

Map<String, Object?> _demoProfileToJson(DemoProfile profile) {
  return {
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
    'subscriptionStartDate': profile.subscriptionStartDate?.toIso8601String(),
    'coreHealthMaxTrialExpiresAt':
        profile.coreHealthMaxTrialExpiresAt?.toIso8601String(),
  };
}

DemoProfile _demoProfileFromJson(Map<String, dynamic> json) {
  return DemoProfile(
    name: json['name'] as String? ?? DemoData.initialProfile.name,
    age: json['age'] as int? ?? DemoData.initialProfile.age,
    gender: _enumByName(
      Gender.values,
      json['gender'] as String?,
      fallback: DemoData.initialProfile.gender,
    ),
    heightCm: (json['heightCm'] as num?)?.toDouble() ??
        DemoData.initialProfile.heightCm,
    weightKg: (json['weightKg'] as num?)?.toDouble() ??
        DemoData.initialProfile.weightKg,
    targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ??
        DemoData.initialProfile.targetWeightKg,
    goal: _enumByName(
      GoalType.values,
      json['goal'] as String?,
      fallback: DemoData.initialProfile.goal,
    ),
    activityLevel: _enumByName(
      ActivityLevel.values,
      json['activityLevel'] as String?,
      fallback: DemoData.initialProfile.activityLevel,
    ),
    schedule: json['schedule'] as String? ?? DemoData.initialProfile.schedule,
    dietaryRestrictions:
        (json['dietaryRestrictions'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
    allergies: (json['allergies'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(),
    healthConditions: (json['healthConditions'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(),
    trainingFrequency: json['trainingFrequency'] as String? ?? '',
    focusAreas: (json['focusAreas'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(),
    preferredActivities:
        (json['preferredActivities'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
    mealBudget: json['mealBudget'] as String? ?? '',
    cookingTime: json['cookingTime'] as String? ?? '',
    nutritionPriorities:
        (json['nutritionPriorities'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
    plan: _enumByName(
      SubscriptionPlan.values,
      json['plan'] as String?,
      fallback: DemoData.initialProfile.plan,
    ),
    subscriptionMonths: json['subscriptionMonths'] as int? ??
        DemoData.initialProfile.subscriptionMonths,
    subscriptionStartDate: json['subscriptionStartDate'] == null
        ? null
        : DateTime.tryParse(json['subscriptionStartDate'] as String),
    coreHealthMaxTrialExpiresAt: json['coreHealthMaxTrialExpiresAt'] == null
        ? null
        : DateTime.tryParse(json['coreHealthMaxTrialExpiresAt'] as String),
  );
}

Map<String, Object?> _weightEntryToJson(WeightEntry entry) {
  return {
    'label': entry.label,
    'weight': entry.weight,
  };
}

WeightEntry _weightEntryFromJson(Map<String, dynamic> json) {
  return WeightEntry(
    label: json['label'] as String? ?? '',
    weight: (json['weight'] as num?)?.toDouble() ?? 0,
  );
}

Map<String, Object?> _mealItemToJson(MealItem meal) {
  return {
    'id': meal.id,
    'nameVi': meal.nameVi,
    'slotLabel': meal.slotLabel,
    'calories': meal.calories,
    'protein': meal.protein,
    'carbs': meal.carbs,
    'fat': meal.fat,
    'imageUrl': meal.imageUrl,
    'ingredients': meal.ingredients,
  };
}

MealItem _mealItemFromJson(Map<String, dynamic> json) {
  return MealItem(
    id: json['id'] as String? ?? '',
    nameVi: json['nameVi'] as String? ?? '',
    slotLabel: json['slotLabel'] as String? ?? '',
    calories: json['calories'] as int? ?? 0,
    protein: json['protein'] as int? ?? 0,
    carbs: json['carbs'] as int? ?? 0,
    fat: json['fat'] as int? ?? 0,
    imageUrl: json['imageUrl'] as String? ?? '',
    ingredients: (json['ingredients'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(),
  );
}

Map<String, Object?> _productToJson(Product product) {
  return {
    'id': product.id,
    'nameVi': product.nameVi,
    'categoryId': product.categoryId,
    'unit': product.unit,
    'priceK': product.priceK,
    'imageUrl': product.imageUrl,
    'hot': product.hot,
  };
}

Product _productFromJson(Map<String, dynamic> json) {
  return Product(
    id: json['id'] as String? ?? '',
    nameVi: json['nameVi'] as String? ?? '',
    categoryId: json['categoryId'] as String? ?? '',
    unit: json['unit'] as String? ?? '',
    priceK: json['priceK'] as int? ?? 0,
    imageUrl: json['imageUrl'] as String? ?? '',
    hot: json['hot'] as bool? ?? false,
  );
}

Map<String, Object?> _orderSummaryToJson(OrderSummary order) {
  return {
    'id': order.id,
    'dateLabel': order.dateLabel,
    'itemCount': order.itemCount,
    'totalK': order.totalK,
    'statusLabel': order.statusLabel,
  };
}

OrderSummary _orderSummaryFromJson(Map<String, dynamic> json) {
  return OrderSummary(
    id: json['id'] as String? ?? '',
    dateLabel: json['dateLabel'] as String? ?? '',
    itemCount: json['itemCount'] as int? ?? 0,
    totalK: json['totalK'] as int? ?? 0,
    statusLabel: json['statusLabel'] as String? ?? '',
  );
}

List<T> _decodeList<T>(
  String? raw,
  T Function(Map<String, dynamic> json) parser,
  List<T> fallback,
) {
  if (raw == null || raw.isEmpty) {
    return fallback;
  }

  try {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(parser)
        .toList(growable: false);
  } catch (_) {
    return fallback;
  }
}

T _decodeObject<T>(
  String? raw,
  T Function(Map<String, dynamic> json) parser,
  T fallback,
) {
  if (raw == null || raw.isEmpty) {
    return fallback;
  }

  try {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return parser(decoded);
  } catch (_) {
    return fallback;
  }
}

Set<int> _decodeIntSet(String? raw, Set<int> fallback) {
  if (raw == null || raw.isEmpty) {
    return fallback;
  }

  try {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) => item as int).toSet();
  } catch (_) {
    return fallback;
  }
}
