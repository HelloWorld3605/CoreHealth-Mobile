import '../models.dart';

/// Derives a shopping list from generated meal-plan days by collecting the
/// unique ingredients across every meal. Pure client-side derivation — the
/// backend does not store shopping items.
class ShoppingListGenerator {
  const ShoppingListGenerator._();

  static List<ShoppingItem> generate(String userId, List<MealPlanDay> allDays) {
    final now = DateTime.now();
    final seen = <String>{};
    final items = <ShoppingItem>[];
    for (final day in allDays) {
      for (final meal in day.meals) {
        for (final ingredient in meal.ingredients) {
          final name = ingredient.trim();
          if (name.isEmpty) continue;
          final key = name.toLowerCase();
          if (!seen.add(key)) continue;
          items.add(ShoppingItem(
            id: 'shop_${day.dayNumber}_${items.length}',
            userId: userId,
            itemName: name,
            quantity: 1,
            unit: '',
            isChecked: false,
            sourceDay: day.dayNumber,
            createdAt: now,
          ));
        }
      }
    }
    return items;
  }
}
