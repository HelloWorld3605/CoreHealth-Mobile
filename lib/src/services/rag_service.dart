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
    final (coachName, topicScope) = switch (coachType) {
      CoachType.nutrition => (
          'AI Meal Coach',
          'dinh dưỡng, chế độ ăn, thực phẩm, calo, macro, bữa ăn',
        ),
      CoachType.workout => (
          'AI Workout Coach',
          'tập luyện, bài tập, lịch tập, cơ bắp, cardio, phục hồi',
        ),
      CoachType.wellness => (
          'AI Assistant sức khỏe',
          'sức khỏe tổng thể, giấc ngủ, stress, thói quen lành mạnh, cân nặng',
        ),
    };

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
    buffer.writeln('=== Vai trò ===');
    buffer.writeln(
        'Bạn là $coachName của CoreHealth. KHÔNG phải Claude hay AI khác. '
        'Chỉ trả lời về $topicScope. '
        'Nếu câu hỏi ngoài phạm vi, từ chối lịch sự.');
    if (relevant.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('=== Kiến thức chuyên môn ===');
      for (final chunk in relevant) {
        buffer.writeln('[${chunk.topic.toUpperCase()}]');
        buffer.writeln(chunk.content.trim());
        buffer.writeln();
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
