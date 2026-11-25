import 'app_locale.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import 'theme_controller.dart';

class ReminderSettingsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> habits;

  const ReminderSettingsScreen({
    super.key,
    required this.habits,
  });

  @override
  State<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  // ---------------- EMERALD LUXURY THEME ----------------
  static const Color ink = Color(0xFF10332B);
  static const Color gold = Color(0xFFE2B857);
  static const Color goldLight = Color(0xFFF6E7B4);

  static const List<Color> _emerald = [
    Color(0xFF06241E),
    Color(0xFF0C4A3C),
    Color(0xFF14876B),
  ];

  static const List<Color> _study = [
    Color(0xFF0F1B4D),
    Color(0xFF1F3A9E),
    Color(0xFF3F5BD9),
  ];

  static const List<Color> _health = [
    Color(0xFF2E0B1A),
    Color(0xFF7A1F3D),
    Color(0xFFD6455F),
  ];

  static const Map<String, IconData> _icons = {
    'sun': Icons.wb_sunny_rounded,
    'fitness': Icons.fitness_center_rounded,
    'book': Icons.menu_book_rounded,
    'school': Icons.school_rounded,
    'water': Icons.water_drop_rounded,
    'star': Icons.star_rounded,
    'walk': Icons.directions_walk_rounded,
    'sleep': Icons.bedtime_rounded,
    'food': Icons.restaurant_rounded,
  };

  List<Color> _gradientFor(String category) {
    switch (category) {
      case 'Study':
        return _study;
      case 'Health & Fitness':
        return _health;
      default:
        return _emerald;
    }
  }

  BoxDecoration _luxury({
    List<Color> colors = _emerald,
    double radius = 18,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: gold.withValues(alpha: 0.55),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.last.withValues(alpha: 0.30),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  int get enabledCount {
    return widget.habits
        .where((habit) => habit['reminderEnabled'] == true)
        .length;
  }

  // --------------------------------------------------
  // SAVE AND SCHEDULE
  // --------------------------------------------------

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('habits', jsonEncode(widget.habits));
  }

  void _snack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<TimeOfDay?> _pickTime(Map<String, dynamic> habit) {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: habit['reminderHour'] ?? 8,
        minute: habit['reminderMinute'] ?? 0,
      ),
    );
  }

  Future<void> _turnOn(Map<String, dynamic> habit) async {
    final time = await _pickTime(habit);

    if (time == null || !mounted) return;

    try {
      await NotificationService.instance.scheduleDailyReminder(
        id: habit['reminderId'],
        habitName: habit['name'],
        hour: time.hour,
        minute: time.minute,
      );

      setState(() {
        habit['reminderEnabled'] = true;
        habit['reminderHour'] = time.hour;
        habit['reminderMinute'] = time.minute;
      });

      await _save();
    } catch (e) {
      _snack(AppLocale.pick('Could not set reminder: $e', 'রিমাইন্ডার সেট করা যায়নি: $e'));
    }
  }

  Future<void> _turnOff(Map<String, dynamic> habit) async {
    try {
      await NotificationService.instance.cancelReminder(
        habit['reminderId'],
      );

      setState(() {
        habit['reminderEnabled'] = false;
      });

      await _save();
    } catch (e) {
      _snack(AppLocale.pick('Could not turn off reminder: $e', 'রিমাইন্ডার বন্ধ করা যায়নি: $e'));
    }
  }

  Future<void> _changeTime(Map<String, dynamic> habit) async {
    final time = await _pickTime(habit);

    if (time == null || !mounted) return;

    try {
      await NotificationService.instance.scheduleDailyReminder(
        id: habit['reminderId'],
        habitName: habit['name'],
        hour: time.hour,
        minute: time.minute,
      );

      setState(() {
        habit['reminderHour'] = time.hour;
        habit['reminderMinute'] = time.minute;
      });

      await _save();
    } catch (e) {
      _snack(AppLocale.pick('Could not change time: $e', 'সময় বদলানো যায়নি: $e'));
    }
  }

  Future<void> _turnAllOff() async {
    for (final habit in widget.habits) {
      if (habit['reminderEnabled'] == true) {
        await _turnOff(habit);
      }
    }
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  Widget _buildSummary() {
    final total = widget.habits.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _luxury(radius: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: gold.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: gold,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocale.digits(AppLocale.pick('$enabledCount of $total reminders on', '$total টির মধ্যে $enabledCount রিমাইন্ডার চালু')),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                const Tr(
                  'Get a daily nudge for each habit.',
                  style: TextStyle(color: goldLight, fontSize: 12),
                ),
              ],
            ),
          ),
          if (enabledCount > 0)
            TextButton(
              onPressed: _turnAllOff,
              style: TextButton.styleFrom(foregroundColor: gold),
              child: const Tr('All off'),
            ),
        ],
      ),
    );
  }

  Widget _buildHabitTile(Map<String, dynamic> habit) {
    final enabled = habit['reminderEnabled'] == true;
    final category = habit['category']?.toString() ?? '';

    final icon = _icons[habit['icon']] ?? Icons.star_rounded;

    final time = TimeOfDay(
      hour: habit['reminderHour'] ?? 8,
      minute: habit['reminderMinute'] ?? 0,
    ).format(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _luxury(
        colors: enabled
            ? _gradientFor(category)
            : const [Color(0xFF1F2E2B), Color(0xFF2E4540)],
        radius: 16,
      ),
      child: Row(
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: gold.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocale.tr(habit['name']?.toString() ?? 'Habit'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: enabled ? () => _changeTime(habit) : null,
                  child: Row(
                    children: [
                      Icon(
                        enabled
                            ? Icons.access_time_rounded
                            : Icons.notifications_off_outlined,
                        size: 14,
                        color: enabled ? gold : Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        enabled
                            ? AppLocale.digits(AppLocale.pick('Daily at $time  (tap to change)', 'প্রতিদিন $time  (বদলাতে চাপ দিন)'))
                            : AppLocale.tr('Reminder off'),
                        style: TextStyle(
                          fontSize: 11,
                          color: enabled ? goldLight : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? gold
                  : Colors.white70;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? gold.withValues(alpha: 0.35)
                  : Colors.white24;
            }),
            onChanged: (value) {
              if (value) {
                _turnOn(habit);
              } else {
                _turnOff(habit);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppPalette.of(context).background,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Tr(
            'Reminder Settings',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            _buildSummary(),
            const SizedBox(height: 20),
            const Tr(
              'Your habits',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.habits.isEmpty)
              Padding(
                padding: const EdgeInsets.all(25),
                child: Center(
                  child: Tr(
                    'No habits yet.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...widget.habits.map(_buildHabitTile),
          ],
        ),
      ),
    );
  }
}
