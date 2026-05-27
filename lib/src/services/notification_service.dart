import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models.dart';

// Notification ID ranges:
//   10–13  meal reminders (breakfast/lunch/snack/dinner)
//   14     morning workout wake-up
//   20     meal-adjusted (immediate)
//   30–35  hydration reminders
//   40     streak guard (evening)
//   41     evening nutrition check-in

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Channel definitions
  static const _mealChannelId = 'corehealth_meals';
  static const _mealChannelName = 'Nhắc nhở bữa ăn';
  static const _workoutChannelId = 'corehealth_workout';
  static const _workoutChannelName = 'Nhắc nhở tập luyện';
  static const _wellnessChannelId = 'corehealth_wellness';
  static const _wellnessChannelName = 'Sức khoẻ & thói quen';

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ─── Meal reminders ──────────────────────────────────────────────────────

  static Future<void> scheduleDailyMealReminders() async {
    if (!_initialized || kIsWeb) return;

    for (var id = 10; id <= 13; id++) {
      await _plugin.cancel(id);
    }

    final reminders = [
      (id: 10, hour: 7, minute: 30, label: 'Bữa sáng'),
      (id: 11, hour: 11, minute: 30, label: 'Bữa trưa'),
      (id: 12, hour: 15, minute: 0, label: 'Bữa xế'),
      (id: 13, hour: 18, minute: 30, label: 'Bữa tối'),
    ];

    for (final r in reminders) {
      await _schedule(
        id: r.id,
        title: 'Đến giờ ${r.label} rồi! 🍽',
        body: 'Hãy ghi lại bữa ăn để theo dõi dinh dưỡng hôm nay.',
        hour: r.hour,
        minute: r.minute,
        channelId: _mealChannelId,
        channelName: _mealChannelName,
        importance: Importance.defaultImportance,
      );
    }
  }

  // ─── Smart notifications (workout, hydration, streak) ────────────────────

  /// Call once after initialize(). Pass profile to personalise messages.
  static Future<void> scheduleSmartNotifications(DemoProfile profile) async {
    if (!_initialized || kIsWeb) return;

    await _scheduleMorningWorkout(profile);
    await _scheduleHydrationReminders();
    await _scheduleStreakGuard(profile);
    await _scheduleEveningCheckIn();
  }

  // 6:00 AM — morning workout wake-up
  static Future<void> _scheduleMorningWorkout(DemoProfile profile) async {
    await _plugin.cancel(14);

    final goal = switch (profile.goal) {
      GoalType.loseWeight => 'đốt mỡ',
      GoalType.gainMuscle => 'tăng cơ',
      GoalType.maintain => 'duy trì vóc dáng',
    };

    await _schedule(
      id: 14,
      title: 'Chào buổi sáng! ☀️ Sẵn sàng tập chưa?',
      body: 'Bài tập sáng nay giúp bạn đạt mục tiêu $goal. '
          'Chỉ 20–30 phút thôi, bắt đầu thôi!',
      hour: 6,
      minute: 0,
      channelId: _workoutChannelId,
      channelName: _workoutChannelName,
      importance: Importance.high,
    );
  }

  // Every 2 hours from 8:00 → 20:00 — hydration reminders
  static Future<void> _scheduleHydrationReminders() async {
    for (var id = 30; id <= 35; id++) {
      await _plugin.cancel(id);
    }

    const messages = [
      'Uống một ly nước ngay bây giờ nhé! 💧',
      'Đã uống đủ nước chưa? Mục tiêu 2L mỗi ngày! 💧',
      'Nhớ uống nước! Giữ cơ thể luôn đủ nước giúp tập tốt hơn. 💧',
      'Uống nước đi! Cơ thể bạn đang cần nước đó. 💧',
      'Nước là nguồn năng lượng tự nhiên tốt nhất! Uống một ly nhé. 💧',
      'Chiều rồi, uống nước đầy đủ để não hoạt động tốt hơn nhé! 💧',
    ];

    const slots = [
      (id: 30, hour: 8, minute: 0),
      (id: 31, hour: 10, minute: 0),
      (id: 32, hour: 12, minute: 30),
      (id: 33, hour: 14, minute: 0),
      (id: 34, hour: 16, minute: 0),
      (id: 35, hour: 18, minute: 0),
    ];

    for (var i = 0; i < slots.length; i++) {
      final s = slots[i];
      await _schedule(
        id: s.id,
        title: 'Nhắc uống nước 💧',
        body: messages[i],
        hour: s.hour,
        minute: s.minute,
        channelId: _wellnessChannelId,
        channelName: _wellnessChannelName,
        importance: Importance.low,
      );
    }
  }

  // 21:00 — streak guard
  static Future<void> _scheduleStreakGuard(DemoProfile profile) async {
    await _plugin.cancel(40);

    final streakMsg = profile.hasWorkoutPlan
        ? 'Streak của bạn đang chờ! Vào CoreHealth hoàn thành bài tập hôm nay trước nửa đêm nhé. 🔥'
        : 'Sắp hết ngày rồi! Đừng quên ghi nhật ký sức khoẻ hôm nay nhé. 🔥';

    await _schedule(
      id: 40,
      title: 'Sắp hết ngày rồi! Giữ streak nào 🔥',
      body: streakMsg,
      hour: 21,
      minute: 0,
      channelId: _workoutChannelId,
      channelName: _workoutChannelName,
      importance: Importance.high,
    );
  }

  // 20:00 — evening nutrition check-in
  static Future<void> _scheduleEveningCheckIn() async {
    await _plugin.cancel(41);

    await _schedule(
      id: 41,
      title: 'Tổng kết hôm nay 📋',
      body: 'Hôm nay bạn đã ăn đủ chưa? '
          'Ghi lại bữa tối để CoreHealth điều chỉnh kế hoạch cho ngày mai.',
      hour: 20,
      minute: 0,
      channelId: _mealChannelId,
      channelName: _mealChannelName,
      importance: Importance.defaultImportance,
    );
  }

  // ─── Immediate notifications ──────────────────────────────────────────────

  static Future<void> showMealAdjusted(String message) async {
    if (!_initialized || kIsWeb) return;

    await _plugin.show(
      20,
      'Kế hoạch ăn đã cập nhật 🥗',
      message,
      _details(
        channelId: _mealChannelId,
        channelName: _mealChannelName,
        importance: Importance.high,
      ),
    );
  }

  /// Call when user logs a workout — cancel streak guard for today.
  /// (Can't truly cancel a recurring alarm for one day only with local notifs,
  /// so we just reschedule it to tomorrow by leaving the daily repeat intact.)
  static Future<void> showWorkoutCompleted(int streakCount) async {
    if (!_initialized || kIsWeb) return;

    await _plugin.show(
      50,
      'Tuyệt vời! Streak $streakCount ngày 🔥',
      'Bài tập hôm nay hoàn thành. Cơ thể bạn đang thay đổi từng ngày!',
      _details(
        channelId: _workoutChannelId,
        channelName: _workoutChannelName,
        importance: Importance.defaultImportance,
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
    required Importance importance,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute),
      _details(channelId: channelId, channelName: channelName, importance: importance),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static NotificationDetails _details({
    required String channelId,
    required String channelName,
    required Importance importance,
  }) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: importance,
          priority: importance == Importance.high ? Priority.high : Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
