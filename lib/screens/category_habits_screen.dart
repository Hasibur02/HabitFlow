import 'package:flutter/material.dart';

import 'package:habitflow/app_locale.dart';
import 'package:habitflow/app_theme.dart';
import 'package:habitflow/habit_utils.dart';
import 'package:habitflow/theme_controller.dart';

// ==================================================
// CATEGORY HABITS SCREEN
// ==================================================

class CategoryHabitsScreen extends StatefulWidget {
  final String category;
  final List<Map<String, dynamic>> habits;
  final Map<String, IconData> habitIcons;

  final Future<void> Function() onAddHabit;
  final Future<void> Function(Map<String, dynamic>) onToggleHabit;
  final Future<void> Function(
    Map<String, dynamic> habit, {
    int delta,
    int? setTo,
  }) onAdjustHabit;
  final Future<void> Function(Map<String, dynamic>) onDeleteHabit;
  final Future<void> Function(Map<String, dynamic>) onSetReminder;
  final Future<void> Function(Map<String, dynamic>) onRemoveReminder;
  final Future<void> Function()? onOpenAdhkar;

  const CategoryHabitsScreen({
    super.key,
    required this.category,
    required this.habits,
    required this.habitIcons,
    required this.onAddHabit,
    required this.onToggleHabit,
    required this.onAdjustHabit,
    required this.onDeleteHabit,
    required this.onSetReminder,
    required this.onRemoveReminder,
    this.onOpenAdhkar,
  });

  @override
  State<CategoryHabitsScreen> createState() =>
      _CategoryHabitsScreenState();
}

class _CategoryHabitsScreenState extends State<CategoryHabitsScreen> {
  String get todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> get currentHabits {
    return widget.habits
        .where((habit) => habit['category'] == widget.category)
        .toList();
  }

  int get completedCount {
    return currentHabits.where((habit) {
      if (!HabitUtils.isScheduledToday(habit)) return false;
      final dates = List<String>.from(
        habit['completedDates'] ?? [],
      );
      return dates.contains(todayKey);
    }).length;
  }

  int get scheduledCount =>
      currentHabits.where(HabitUtils.isScheduledToday).length;

  double get progress {
    if (scheduledCount == 0) return 0;
    return completedCount / scheduledCount;
  }

  Future<void> _adjust(
    Map<String, dynamic> habit, {
    int delta = 0,
    int? setTo,
  }) async {
    await widget.onAdjustHabit(habit, delta: delta, setTo: setTo);
    if (mounted) setState(() {});
  }

  Future<void> _editCount(Map<String, dynamic> habit) async {
    final controller = TextEditingController(
      text: HabitUtils.countOn(habit, todayKey).toString(),
    );
    final target = HabitUtils.target(habit);
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocale.tr(habit['name']?.toString() ?? 'Habit')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: AppLocale.pick(
              'Today (max $target)',
              'আজকের সংখ্যা (সর্বোচ্চ $target)',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Tr('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              int.tryParse(controller.text.trim()),
            ),
            child: Text(AppLocale.pick('Save', 'সংরক্ষণ')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await _adjust(habit, setTo: value);
  }

  List<Color> get categoryGradient =>
      AppTheme.forCategory(widget.category);

  Future<void> _refreshAfter(
    Future<void> Function(Map<String, dynamic>) action,
    Map<String, dynamic> habit,
  ) async {
    await action(habit);
    if (mounted) setState(() {});
  }

  Future<void> _addHabit() async {
    await widget.onAddHabit();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    final items = currentHabits;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppTheme.bgFor(
            widget.category,
            dark: AppPalette.of(context).dark,
          ),
        ),
      ),
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Tr(
          widget.category,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        backgroundColor: categoryGradient[1],
        foregroundColor: AppTheme.gold,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Daily progress
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.luxury(
              colors: categoryGradient,
              radius: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Tr(
                  'Daily Progress',
                  style: TextStyle(
                    color: AppTheme.goldLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppLocale.digits(AppLocale.pick('$completedCount of ${scheduledCount} completed', '${scheduledCount}টির মধ্যে $completedCount সম্পন্ন')),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Adhkar & Dua (below Daily Progress)
          if (widget.onOpenAdhkar != null) ...[
            const SizedBox(height: 16),
            Container(
              decoration: AppTheme.luxury(
                colors: AppTheme.prayer,
                radius: 18,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await widget.onOpenAdhkar!();
                    if (mounted) setState(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.gold.withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: AppTheme.gold,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Tr(
                                'Adhkar & Dua',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Morning · Evening · Before Sleep',
                                style: TextStyle(
                                  color: AppTheme.goldLight,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.goldLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Tr(
                "Today's Habits",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$completedCount/${scheduledCount}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: AppTheme.luxury(radius: 18),
              child: const Column(
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    size: 45,
                    color: AppTheme.gold,
                  ),
                  SizedBox(height: 10),
                  Tr(
                    'No habits yet',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Tr(
                    'Tap the + button to add your first habit.',
                    style: TextStyle(
                      color: AppTheme.goldLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...items.map(_buildHabitCard),
        ],
      ),
      ),
    );
  }

  Widget _buildHabitCard(Map<String, dynamic> habit) {
    final dates = List<String>.from(
      habit['completedDates'] ?? [],
    );

    final isDone = dates.contains(todayKey);
    final scheduled = HabitUtils.isScheduledToday(habit);
    final isCounter = HabitUtils.isCounter(habit);
    final count = HabitUtils.countOn(habit, todayKey);
    final target = HabitUtils.target(habit);
    final unit = HabitUtils.unit(habit);
    final streak = HabitUtils.streak(habit);
    final best = HabitUtils.bestStreak(habit);
    final dayNames = AppLocale.pick(
      'Mon,Tue,Wed,Thu,Fri,Sat,Sun',
      'সোম,মঙ্গল,বুধ,বৃহঃ,শুক্র,শনি,রবি',
    ).split(',');
    final scheduleText = HabitUtils.isEveryDay(habit)
        ? ''
        : (HabitUtils.days(habit).toList()..sort())
            .map((d) => dayNames[d - 1])
            .join(' · ');
    final icon = widget.habitIcons[habit['icon']] ??
        Icons.star_rounded;

    final reminderEnabled = habit['reminderEnabled'] == true;
    final hour = habit['reminderHour'] ?? 8;
    final minute = habit['reminderMinute'] ?? 0;

    final reminderTime = TimeOfDay(
      hour: hour,
      minute: minute,
    ).format(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: AppTheme.luxury(
        colors: isDone ? AppTheme.muted : categoryGradient,
        radius: 16,
      ),
      child: Row(
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppTheme.gold.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              icon,
              color: AppTheme.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocale.tr(habit['name']?.toString() ?? 'Habit'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                    decorationColor: AppTheme.goldLight,
                    color: isDone ? Colors.white54 : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    if (reminderEnabled) {
                      await _refreshAfter(
                        widget.onRemoveReminder,
                        habit,
                      );
                    } else {
                      await _refreshAfter(
                        widget.onSetReminder,
                        habit,
                      );
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        reminderEnabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        size: 14,
                        color: reminderEnabled
                            ? AppTheme.gold
                            : Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reminderEnabled
                            ? AppLocale.digits(AppLocale.pick('Daily at $reminderTime', 'প্রতিদিন $reminderTime'))
                            : AppLocale.tr('Set reminder'),
                        style: TextStyle(
                          fontSize: 11,
                          color: reminderEnabled
                              ? AppTheme.goldLight
                              : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                if (streak > 0 || best > 0 || scheduleText.isNotEmpty || isCounter)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (streak > 0 || best > 0)
                          Text(
                            AppLocale.digits(
                              AppLocale.pick(
                                '🔥 $streak · Best $best',
                                '🔥 $streak · সর্বোচ্চ $best',
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.goldLight,
                            ),
                          ),
                        if (scheduleText.isNotEmpty)
                          Text(
                            scheduleText,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Colors.white60,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppLocale.tr('Delete habit'),
            onPressed: () async {
              await _refreshAfter(
                widget.onDeleteHabit,
                habit,
              );
            },
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white38,
              size: 21,
            ),
          ),
          if (!scheduled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                AppLocale.pick('Rest\nday', 'আজ\nছুটি'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Colors.white54,
                ),
              ),
            )
          else if (isCounter)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: count > 0
                      ? () => _adjust(habit, delta: -1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  color: AppTheme.gold,
                  disabledColor: Colors.white24,
                ),
                GestureDetector(
                  onTap: () => _editCount(habit),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocale.digits('$count/$target'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDone ? AppTheme.goldLight : Colors.white,
                        ),
                      ),
                      if (unit.isNotEmpty)
                        Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white60,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: count < target
                      ? () => _adjust(habit, delta: 1)
                      : null,
                  icon: const Icon(Icons.add_circle_rounded),
                  color: AppTheme.gold,
                  disabledColor: Colors.white24,
                ),
              ],
            )
          else
            Checkbox(
              value: isDone,
              activeColor: AppTheme.gold,
              checkColor: AppTheme.deep,
              side: BorderSide(
                color: AppTheme.gold.withValues(alpha: 0.8),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (_) async {
                await _refreshAfter(
                  widget.onToggleHabit,
                  habit,
                );
              },
            ),
        ],
      ),
    );
  }
}
