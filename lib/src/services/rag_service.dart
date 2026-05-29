import '../models.dart';
import 'fitness_knowledge.dart';

class RagService {
  static const _maxChunks = 4;
  static const _minScore = 0.05;

  /// Returns coach persona + relevant knowledge chunks.
  /// Always includes persona so injection into user message enforces identity
  /// even when the model ignores the system prompt.
  String buildContext({
    required String userQuery,
    required DemoProfile profile,
    required CoachType coachType,
  }) {
    final preferTopics = _topicsForCoach(coachType, profile);
    final results = FitnessKnowledge.search(
      userQuery,
      preferTopics: preferTopics,
    );

    final relevant = results
        .where((r) => r.$2 >= _minScore)
        .take(_maxChunks)
        .map((r) => r.$1)
        .toList();

    final buffer = StringBuffer();
    if (relevant.isNotEmpty) {
      for (var i = 0; i < relevant.length; i++) {
        buffer.write(relevant[i].content.trim());
        if (i < relevant.length - 1) {
          buffer.write('\n---\n');
        }
      }
    }
    return buffer.toString().trim();
  }

  List<String> _topicsForCoach(CoachType coachType, DemoProfile profile) {
    final base = <String>[
      ...switch (coachType) {
        CoachType.nutrition => ['nutrition', 'vi_food', 'hydration'],
        CoachType.workout => ['workout', 'recovery'],
        CoachType.wellness => ['recovery', 'hydration', 'nutrition'],
      }
    ];

    if (profile.goal == GoalType.loseWeight) {
      base.add('weightloss');
    } else if (profile.goal == GoalType.gainMuscle) {
      base.add('musclegain');
    }
    // Boost nutrition topic when health conditions are present
    if (profile.healthConditions.isNotEmpty && !base.contains('nutrition')) {
      base.add('nutrition');
    }
    return base;
  }
}
