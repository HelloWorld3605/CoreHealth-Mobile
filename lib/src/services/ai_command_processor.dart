import '../data/app_repository.dart';
import '../models.dart';

/// Applies an AI coach "---ADJUSTMENT---" payload to the user's current-day
/// plan. The adjustment map follows the schema emitted by the chat prompt:
/// {type, mealChanges:[{slot,name,kcal,protein,carbs,fat,details}],
///  workoutChanges:[{exercise}], reason}
class AiCommandProcessor {
  const AiCommandProcessor._();

  static Future<void> processCommand({
    required String userId,
    required Map<String, dynamic> adjustment,
    required PlanGeneration currentGeneration,
    required AppRepository repository,
    required int currentDayIndex,
  }) async {
    final version = currentGeneration.version;
    final reason = adjustment['reason'] as String? ?? '';

    final mealChanges = (adjustment['mealChanges'] as List?) ?? const [];
    if (mealChanges.isNotEmpty) {
      final existing = await repository.getMealPlan(
        userId: userId,
        version: version,
        dayIndex: currentDayIndex,
      );
      final meals = <MealItem>[...?existing?.meals];
      for (var i = 0; i < mealChanges.length; i++) {
        final m = mealChanges[i] as Map<String, dynamic>;
        final details = m['details'] as String? ?? '';
        meals.add(MealItem(
          id: 'adj_meal_${currentDayIndex}_$i',
          nameVi: m['name'] as String? ?? '',
          slotLabel: m['slot'] as String? ?? '',
          calories: (m['kcal'] as num? ?? 0).toInt(),
          protein: (m['protein'] as num? ?? 0).toInt(),
          carbs: (m['carbs'] as num? ?? 0).toInt(),
          fat: (m['fat'] as num? ?? 0).toInt(),
          imageUrl: '',
          ingredients: details.isEmpty ? const [] : [details],
        ));
      }
      await repository.saveMealPlan(
        userId: userId,
        generationId: currentGeneration.id,
        dayIndex: currentDayIndex,
        plan: MealPlanDay(dayNumber: currentDayIndex, meals: meals),
      );
    }

    final workoutChanges = (adjustment['workoutChanges'] as List?) ?? const [];
    if (workoutChanges.isNotEmpty) {
      final existing = await repository.getWorkoutPlan(
        userId: userId,
        version: version,
        dayIndex: currentDayIndex,
      );
      final exercises = <WorkoutExercise>[...?existing?.exercises];
      for (var i = 0; i < workoutChanges.length; i++) {
        final w = workoutChanges[i] as Map<String, dynamic>;
        exercises.add(WorkoutExercise(
          id: 'adj_wk_${currentDayIndex}_$i',
          nameVi: w['exercise'] as String? ?? '',
          description: reason,
          caloriesBurned: 50,
        ));
      }
      await repository.saveWorkoutPlan(
        userId: userId,
        generationId: currentGeneration.id,
        dayIndex: currentDayIndex,
        plan: WorkoutDay(
          dayNumber: currentDayIndex,
          focusVi: existing?.focusVi ?? 'Điều chỉnh',
          exercises: exercises,
        ),
      );
    }
  }
}
