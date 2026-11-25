
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'models/task_model.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // --------------------------------------------------
  // INITIALIZATION
  // --------------------------------------------------

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        // Notification tapped.
      },
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // --------------------------------------------------
  // HABIT REMINDERS
  // --------------------------------------------------

  Future<void> scheduleDailyReminder({
    required int id,
    required String habitName,
    required int hour,
    required int minute,
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(
        const Duration(days: 1),
      );
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'habit_reminder_channel',
      'Habit Reminders',
      channelDescription: 'Daily reminders for your habits',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id: id,
      title: 'Habit Reminder 🔔',
      body: 'Time to complete: $habitName',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // --------------------------------------------------
  // TASK REMINDER CHANNEL
  // --------------------------------------------------

  static const String _taskChannelId = 'task_reminder_channel';

  static const String _taskChannelName = 'Task Reminders';

  NotificationDetails get _taskNotificationDetails {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _taskChannelId,
      _taskChannelName,
      channelDescription: 'Notifications for scheduled tasks',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );

    return const NotificationDetails(
      android: androidDetails,
    );
  }

  // --------------------------------------------------
  // TASK REMINDER ID
  // --------------------------------------------------

  int _taskNotificationId(TaskModel task, int weekday) {
    if (task.taskType == TaskType.oneTime) {
      return task.reminderId;
    }

    return task.reminderId + weekday;
  }

  // --------------------------------------------------
  // FIND NEXT OCCURRENCE
  // --------------------------------------------------

  tz.TZDateTime? _nextTaskOccurrence({
    required TaskModel task,
    required int weekday,
  }) {
    final now = tz.TZDateTime.now(tz.local);

    final start = task.startDate;

    final startDate = DateTime(
      start.year,
      start.month,
      start.day,
    );

    final currentDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    var daysAhead = (weekday - currentDate.weekday) % 7;

    var candidate = currentDate.add(
      Duration(days: daysAhead),
    );

    final scheduledHour = task.scheduledHour!;
    final scheduledMinute = task.scheduledMinute!;

    var candidateTime = tz.TZDateTime(
      tz.local,
      candidate.year,
      candidate.month,
      candidate.day,
      scheduledHour,
      scheduledMinute,
    );

    if (!candidateTime.isAfter(now)) {
      candidate = candidate.add(
        const Duration(days: 7),
      );

      candidateTime = tz.TZDateTime(
        tz.local,
        candidate.year,
        candidate.month,
        candidate.day,
        scheduledHour,
        scheduledMinute,
      );
    }

    // Never schedule before the task start date.
    while (candidate.isBefore(startDate) ||
        candidate.weekday != weekday) {
      candidate = candidate.add(
        const Duration(days: 1),
      );

      candidateTime = tz.TZDateTime(
        tz.local,
        candidate.year,
        candidate.month,
        candidate.day,
        scheduledHour,
        scheduledMinute,
      );
    }

    // Do not schedule beyond the due date.
    if (task.dueDate != null) {
      final due = task.dueDate!;

      final dueDate = DateTime(
        due.year,
        due.month,
        due.day,
      );

      if (candidate.isAfter(dueDate)) {
        return null;
      }
    }

    return candidateTime;
  }

  // --------------------------------------------------
  // SCHEDULE TASK REMINDER
  // --------------------------------------------------

  Future<void> scheduleTaskReminder(TaskModel task) async {
    await initialize();

    // Remove previous reminders for this task first.
    await cancelTaskReminder(task.reminderId);

    if (!task.reminderEnabled) return;

    if (task.scheduledHour == null ||
        task.scheduledMinute == null) {
      return;
    }

    final notificationDetails = _taskNotificationDetails;

    // One-time task.
    if (task.taskType == TaskType.oneTime) {
      final start = task.startDate;

      final scheduledDate = tz.TZDateTime(
        tz.local,
        start.year,
        start.month,
        start.day,
        task.scheduledHour!,
        task.scheduledMinute!,
      );

      final now = tz.TZDateTime.now(tz.local);

      if (!scheduledDate.isAfter(now)) return;

      await _notifications.zonedSchedule(
        id: task.reminderId,
        title: 'Task Reminder 📌',
        body: 'Time to complete: ${task.title}',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode.inexactAllowWhileIdle,
      );

      return;
    }

    // Recurring tasks.
    final days = task.repeatDays.isEmpty
        ? [1, 2, 3, 4, 5, 6, 7]
        : task.repeatDays;

    for (final weekday in days) {
      final nextOccurrence = _nextTaskOccurrence(
        task: task,
        weekday: weekday,
      );

      if (nextOccurrence == null) continue;

      await _notifications.zonedSchedule(
        id: _taskNotificationId(task, weekday),
        title: 'Recurring Task Reminder 🔔',
        body: 'Time to complete: ${task.title}',
        scheduledDate: nextOccurrence,
        notificationDetails: notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents:
            DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  // --------------------------------------------------
  // CANCEL TASK REMINDERS
  // --------------------------------------------------

  Future<void> cancelTaskReminder(int reminderId) async {
    await initialize();

    await _notifications.cancel(id: reminderId);

    for (int weekday = 1; weekday <= 7; weekday++) {
      await _notifications.cancel(
        id: reminderId + weekday,
      );
    }
  }

  // --------------------------------------------------
  // EXISTING CANCEL METHODS
  // --------------------------------------------------

  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id: id);
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }
}
