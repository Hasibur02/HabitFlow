import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habitflow/app_locale.dart';
import 'package:habitflow/app_theme.dart';
import 'package:habitflow/features/tasks/task_repository.dart';
import 'package:habitflow/models/task_model.dart';
import 'package:habitflow/theme_controller.dart';

// ==================================================
// ANALYTICS SCREEN
// ==================================================

enum AnalyticsPeriod { daily, weekly, monthly }

class AnalyticsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> habits;

  const AnalyticsScreen({
    super.key,
    required this.habits,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const String prayerStorageKey = 'prayer_tracker_v1';
  List<TaskModel> analyticsTasks = [];

  static const Color studyColor = Color(0xFF3F5BD9);
  static const Color spiritualColor = Color(0xFF159B83);
  static const Color prayerColor = Color(0xFFDA9635);
  static const Color healthColor = Color(0xFFE16B83);

  Map<String, int> get taskStats {
    int total = 0;
    int completed = 0;
    int pending = 0;
    int overdue = 0;
    int skipped = 0;

    for (
      var date = DateUtils.dateOnly(periodStart);
      !date.isAfter(DateUtils.dateOnly(periodEnd));
      date = date.add(const Duration(days: 1))
    ) {
      for (final task in analyticsTasks) {
        if (!task.isScheduledOn(date)) continue;

        total++;

        if (task.isCompletedOn(date)) {
          completed++;
        } else if (task.isSkippedOn(date)) {
          skipped++;
        } else if (date.isBefore(today)) {
          overdue++;
        } else {
          pending++;
        }
      }
    }

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'overdue': overdue,
      'skipped': skipped,
    };
  }

  double get taskCompletionRate {
    final stats = taskStats;
    final total = stats['total'] ?? 0;

    if (total == 0) return 0;

    return (stats['completed'] ?? 0) / total;
  }

  final List<String> prayerNames = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  Map<String, dynamic> prayerHistory = {};

  List<Map<String, dynamic>> analyticsHabits = [];

  bool isLoading = true;

  AnalyticsPeriod selectedPeriod = AnalyticsPeriod.daily;
  DateTime selectedDate = DateTime.now();

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadPrayerHistory();
  }

  // --------------------------------------------------
  // LOAD PRAYER DATA
  // --------------------------------------------------

  Future<void> _loadPrayerHistory() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      analyticsTasks = await TaskRepository.instance.getTasks();
    } catch (e) {
      debugPrint('Task analytics error: $e');
      analyticsTasks = [];
    }

    // Load latest habits
    final savedHabits = prefs.getString('habits');

    if (savedHabits != null) {
      try {
        final decodedHabits = jsonDecode(savedHabits);

        if (decodedHabits is List) {
          analyticsHabits = decodedHabits.map((item) {
            return Map<String, dynamic>.from(item);
          }).toList();
        }
      } catch (e) {
        debugPrint('Habit analytics error: $e');
        analyticsHabits = List<Map<String, dynamic>>.from(
          widget.habits,
        );
      }
    } else {
      analyticsHabits = List<Map<String, dynamic>>.from(
        widget.habits,
      );
    }

    // Load prayer history
    final savedPrayer = prefs.getString(prayerStorageKey);

    if (savedPrayer != null) {
      try {
        final decoded = jsonDecode(savedPrayer);

        if (decoded is Map) {
          prayerHistory = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint('Prayer analytics error: $e');
      }
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // --------------------------------------------------
  // PERIOD DATE RANGE
  // --------------------------------------------------

  DateTime get periodStart {
    final date = DateUtils.dateOnly(selectedDate);

    switch (selectedPeriod) {
      case AnalyticsPeriod.daily:
        return date;

      case AnalyticsPeriod.weekly:
        return date.subtract(
          Duration(days: date.weekday - 1),
        );

      case AnalyticsPeriod.monthly:
        return DateTime(date.year, date.month, 1);
    }
  }

  DateTime get periodEnd {
    DateTime end;

    switch (selectedPeriod) {
      case AnalyticsPeriod.daily:
        end = selectedDate;
        break;

      case AnalyticsPeriod.weekly:
        end = periodStart.add(const Duration(days: 6));
        break;

      case AnalyticsPeriod.monthly:
        end = DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          0,
        );
        break;
    }

    // Never count future days.
    return end.isAfter(today) ? today : end;
  }

  int get periodDays {
    if (periodEnd.isBefore(periodStart)) return 0;

    return periodEnd.difference(periodStart).inDays + 1;
  }

  String get periodLabel {
    switch (selectedPeriod) {
      case AnalyticsPeriod.daily:
        return '${selectedDate.day} ${_monthName(selectedDate.month)} ${selectedDate.year}';

      case AnalyticsPeriod.weekly:
        return '${periodStart.day} ${_monthName(periodStart.month)} - '
            '${periodEnd.day} ${_monthName(periodEnd.month)} ${periodEnd.year}';

      case AnalyticsPeriod.monthly:
        return '${_monthName(selectedDate.month)} ${selectedDate.year}';
    }
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return AppLocale.tr(months[month - 1]);
  }

  void _changePeriod(AnalyticsPeriod period) {
    setState(() {
      selectedPeriod = period;
    });
  }

  void _movePeriod(int amount) {
    DateTime next;

    switch (selectedPeriod) {
      case AnalyticsPeriod.daily:
        next = selectedDate.add(Duration(days: amount));
        break;

      case AnalyticsPeriod.weekly:
        next = selectedDate.add(Duration(days: amount * 7));
        break;

      case AnalyticsPeriod.monthly:
        next = DateTime(
          selectedDate.year,
          selectedDate.month + amount,
          1,
        );
        break;
    }

    if (next.isAfter(today)) return;

    setState(() {
      selectedDate = next;
    });
  }

  // --------------------------------------------------
  // HABIT STATISTICS
  // --------------------------------------------------

  int _habitCompletionCount(Map<String, dynamic> habit) {
    final dates = List<String>.from(
      habit['completedDates'] ?? [],
    );

    int count = 0;

    for (int i = 0; i < periodDays; i++) {
      final date = _dateKey(
        periodStart.add(Duration(days: i)),
      );

      if (dates.contains(date)) count++;
    }

    return count;
  }

  List<Map<String, dynamic>> _categoryHabits(String category) {
    return analyticsHabits.where((habit) {
      return habit['category'] == category;
    }).toList();
  }

  int _categoryCompleted(String category) {
    return _categoryHabits(category).fold(
      0,
      (sum, habit) => sum + _habitCompletionCount(habit),
    );
  }

  int _categoryTarget(String category) {
    return _categoryHabits(category).length * periodDays;
  }

  double _percentage(int completed, int target) {
    if (target == 0) return 0;

    return (completed / target * 100).clamp(0, 100).toDouble();
  }

  // --------------------------------------------------
  // PRAYER STATISTICS
  // --------------------------------------------------

  Map<String, dynamic> _getPrayerData(
    String date,
    String prayer,
  ) {
    final dayData = prayerHistory[date];

    if (dayData is Map) {
      final data = dayData[prayer];

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    }

    return {};
  }

  bool _isPrayerCompleted(String date, String prayer) {
    return _getPrayerData(date, prayer)['prayed'] == true;
  }

  int _prayerCount(String prayer) {
    int count = 0;

    for (int i = 0; i < periodDays; i++) {
      final date = _dateKey(
        periodStart.add(Duration(days: i)),
      );

      if (_isPrayerCompleted(date, prayer)) count++;
    }

    return count;
  }

  int get totalPrayerCompleted {
    return prayerNames.fold(
      0,
      (sum, prayer) => sum + _prayerCount(prayer),
    );
  }

  int get prayerTarget => periodDays * 5;

  // --------------------------------------------------
  // OVERALL STATISTICS
  // --------------------------------------------------

  int get totalHabitCompleted {
    return analyticsHabits.fold(
      0,
      (sum, habit) => sum + _habitCompletionCount(habit),
    );
  }

  int get totalOverallCompleted {
    return totalHabitCompleted + totalPrayerCompleted;
  }

  int get overallTarget {
    return (analyticsHabits.length * periodDays) + prayerTarget;
  }

  double get overallPercentage {
    return _percentage(
      totalOverallCompleted,
      overallTarget,
    );
  }

  // --------------------------------------------------
  // UI HELPERS
  // --------------------------------------------------

  Widget _sectionTitle(
    String title, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _periodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppPalette.of(context).surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          _periodButton(AppLocale.tr('Daily'), AnalyticsPeriod.daily),
          _periodButton(AppLocale.tr('Weekly'), AnalyticsPeriod.weekly),
          _periodButton(AppLocale.tr('Monthly'), AnalyticsPeriod.monthly),
        ],
      ),
    );
  }

  Widget _periodButton(
    String title,
    AnalyticsPeriod period,
  ) {
    final selected = selectedPeriod == period;

    return Expanded(
      child: GestureDetector(
        onTap: () => _changePeriod(period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0xFF0C4A3C),
                      Color(0xFF14876B),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppTheme.gold : AppPalette.of(context).muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateNavigation() {
    final isCurrentPeriod = selectedPeriod == AnalyticsPeriod.daily
        ? selectedDate == today
        : selectedPeriod == AnalyticsPeriod.weekly
            ? periodStart == today.subtract(
                Duration(days: today.weekday - 1),
              )
            : selectedDate.year == today.year &&
                selectedDate.month == today.month;

    return Row(
      children: [
        IconButton(
          onPressed: () => _movePeriod(-1),
          icon: Icon(
            Icons.chevron_left_rounded,
            color: AppPalette.of(context).accent,
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                periodLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                selectedPeriod == AnalyticsPeriod.daily
                    ? AppLocale.tr('Selected day')
                    : selectedPeriod == AnalyticsPeriod.weekly
                        ? AppLocale.tr('Monday - Sunday')
                        : AppLocale.tr('Monthly report'),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: isCurrentPeriod
              ? null
              : () => _movePeriod(1),
          icon: Icon(
            Icons.chevron_right_rounded,
            color: AppPalette.of(context).accent,
          ),
        ),
      ],
    );
  }

  Widget _overallCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.luxury(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Tr(
            'Overall Progress',
            style: TextStyle(
              color: AppTheme.goldLight,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                '${overallPercentage.round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$totalOverallCompleted / $overallTarget',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: overallTarget == 0
                  ? 0
                  : totalOverallCompleted / overallTarget,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.gold,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            AppLocale.digits(AppLocale.pick('$periodDays ${periodDays == 1 ? 'day' : 'days'} included in this report', 'এই রিপোর্টে $periodDays দিন অন্তর্ভুক্ত')),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskMetric(
    String title,
    int value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskAnalyticsCard() {
    final stats = taskStats;
    final rate = taskCompletionRate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.luxury(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Tr(
                  'Task Analytics',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${(rate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.gold,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              _taskMetric(AppLocale.tr('Total Tasks'),
                stats['total'] ?? 0,
                const Color(0xFF7FB2FF),
                Icons.list_alt_rounded,
              ),
              const SizedBox(width: 10),
              _taskMetric(AppLocale.tr('Completed'),
                stats['completed'] ?? 0,
                const Color(0xFF5BD7A8),
                Icons.check_circle_outline_rounded,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _taskMetric(AppLocale.tr('Pending'),
                stats['pending'] ?? 0,
                const Color(0xFFF0B25C),
                Icons.pending_actions_rounded,
              ),
              const SizedBox(width: 10),
              _taskMetric(AppLocale.tr('Overdue'),
                stats['overdue'] ?? 0,
                const Color(0xFFFF7A8A),
                Icons.warning_amber_rounded,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            AppLocale.digits(AppLocale.pick('Skipped: ${stats['skipped'] ?? 0}', 'বাদ দেওয়া: ${stats['skipped'] ?? 0}')),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required int completed,
    required int target,
    required VoidCallback onTap,
  }) {
    final percentage = _percentage(completed, target);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: AppTheme.luxury(colors: gradient, radius: 17),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppTheme.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(icon, color: AppTheme.gold),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocale.digits(AppLocale.pick('$completed of $target completed', '$target টির মধ্যে $completed সম্পন্ন')),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: target == 0
                              ? 0
                              : completed / target,
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                            AppTheme.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Text(
                      '${percentage.round()}%',
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.goldLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // CATEGORY DETAILS NAVIGATION
  // --------------------------------------------------

  void _openCategoryDetails(
    String category,
    Color color,
    IconData icon,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitCategoryAnalyticsPage(
          category: category,
          color: color,
          icon: icon,
          habits: _categoryHabits(category),
          periodStart: periodStart,
          periodDays: periodDays,
          periodLabel: periodLabel,
        ),
      ),
    );
  }

  void _openPrayerDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrayerAnalyticsPage(
          prayerHistory: prayerHistory,
          periodStart: periodStart,
          periodDays: periodDays,
          periodLabel: periodLabel,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // MAIN ANALYTICS UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Tr('Analytics')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Tr(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPrayerHistory,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _periodSelector(),
            const SizedBox(height: 10),
            _dateNavigation(),
            const SizedBox(height: 15),

            _overallCard(),

            const SizedBox(height: 18),

            _taskAnalyticsCard(),

            const SizedBox(height: 27),

            _sectionTitle(AppLocale.tr('Category Performance'),
              subtitle: AppLocale.tr('Tap a category to see detailed statistics.'),
            ),

            const SizedBox(height: 14),

            _categoryCard(
              title: AppLocale.tr('Study'),
              subtitle: AppLocale.tr('Study habits'),
              icon: Icons.school_rounded,
              gradient: AppTheme.study,
              completed: _categoryCompleted('Study'),
              target: _categoryTarget('Study'),
              onTap: () => _openCategoryDetails(
                'Study',
                studyColor,
                Icons.school_rounded,
              ),
            ),

            _categoryCard(
              title: AppLocale.tr('Spiritual'),
              subtitle: AppLocale.tr('Quran and Adhkar'),
              icon: Icons.menu_book_rounded,
              gradient: AppTheme.emerald,
              completed: _categoryCompleted('Spiritual'),
              target: _categoryTarget('Spiritual'),
              onTap: () => _openCategoryDetails(
                'Spiritual',
                spiritualColor,
                Icons.menu_book_rounded,
              ),
            ),

            _categoryCard(
              title: AppLocale.tr('Prayer'),
              subtitle: AppLocale.tr('Five daily prayers'),
              icon: Icons.mosque_rounded,
              gradient: AppTheme.prayer,
              completed: totalPrayerCompleted,
              target: prayerTarget,
              onTap: _openPrayerDetails,
            ),

            _categoryCard(
              title: AppLocale.tr('Health & Fitness'),
              subtitle: AppLocale.tr('Healthy lifestyle habits'),
              icon: Icons.fitness_center_rounded,
              gradient: AppTheme.health,
              completed: _categoryCompleted('Health & Fitness'),
              target: _categoryTarget('Health & Fitness'),
              onTap: () => _openCategoryDetails(
                'Health & Fitness',
                healthColor,
                Icons.fitness_center_rounded,
              ),
            ),

            const SizedBox(height: 18),

            Center(
              child: Tr(
                'Keep going. Small steps create big changes.',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// HABIT CATEGORY ANALYTICS PAGE
// ==================================================

class HabitCategoryAnalyticsPage extends StatelessWidget {
  final String category;
  final Color color;
  final IconData icon;
  final List<Map<String, dynamic>> habits;
  final DateTime periodStart;
  final int periodDays;
  final String periodLabel;

  const HabitCategoryAnalyticsPage({
    super.key,
    required this.category,
    required this.color,
    required this.icon,
    required this.habits,
    required this.periodStart,
    required this.periodDays,
    required this.periodLabel,
  });

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  int _completionCount(Map<String, dynamic> habit) {
    final dates = List<String>.from(
      habit['completedDates'] ?? [],
    );

    int count = 0;

    for (int i = 0; i < periodDays; i++) {
      final date = _dateKey(
        periodStart.add(Duration(days: i)),
      );

      if (dates.contains(date)) count++;
    }

    return count;
  }

  double _percentage(int completed, int target) {
    if (target == 0) return 0;
    return (completed / target * 100).clamp(0, 100).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    final totalCompleted = habits.fold<int>(
      0,
      (sum, habit) => sum + _completionCount(habit),
    );

    final totalTarget = habits.length * periodDays;

    final percentage = _percentage(
      totalCompleted,
      totalTarget,
    );

    final ranked = habits.toList()
      ..sort(
        (a, b) => _completionCount(b).compareTo(
          _completionCount(a),
        ),
      );

    final bestHabit = ranked.isEmpty ? null : ranked.first;
    final weakestHabit = ranked.isEmpty ? null : ranked.last;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppTheme.bgFor(
            category,
            dark: AppPalette.of(context).dark,
          ),
        ),
      ),
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(AppLocale.pick('$category Statistics', '${AppLocale.tr(category)} পরিসংখ্যান')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.luxury(
              colors: AppTheme.forCategory(category),
              radius: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppTheme.gold, size: 30),
                const SizedBox(height: 14),
                Text(
                  '${percentage.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Tr(
                  'Category Progress',
                  style: TextStyle(color: AppTheme.goldLight),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocale.digits(AppLocale.pick('$totalCompleted / $totalTarget completions', '$totalTarget টির মধ্যে $totalCompleted সম্পন্ন')),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: totalTarget == 0
                        ? 0
                        : totalCompleted / totalTarget,
                    minHeight: 8,
                    backgroundColor: Colors.white30,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                      AppTheme.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 17),

          Text(
            periodLabel,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 22),

          const Tr(
            'Habit-wise Performance',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 13),

          if (habits.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Tr('No habits in this category.'),
              ),
            )
          else
            ...habits.map((habit) {
              final completed = _completionCount(habit);
              final target = periodDays;
              final progress = _percentage(completed, target);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: AppTheme.luxury(
                  colors: AppTheme.forCategory(category),
                  radius: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocale.tr(habit['name']?.toString() ?? 'Habit'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          '${progress.round()}%',
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: target == 0
                            ? 0
                            : completed / target,
                        minHeight: 7,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          AppTheme.gold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      AppLocale.digits(AppLocale.pick('$completed of $target days completed', '$target দিনের মধ্যে $completed দিন সম্পন্ন')),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 18),

          const Tr(
            'Performance Insights',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _insightCard(
            icon: Icons.emoji_events_rounded,
            color: AppTheme.gold,
            title: AppLocale.tr('Best Performing Habit'),
            value: AppLocale.tr(bestHabit?['name']?.toString() ?? 'No data'),
            subtitle: bestHabit == null
                ? AppLocale.tr('No habits available')
                : AppLocale.digits(AppLocale.pick('${_completionCount(bestHabit)} completions', '${_completionCount(bestHabit)} বার সম্পন্ন')),
          ),

          const SizedBox(height: 10),

          _insightCard(
            icon: Icons.trending_down_rounded,
            color: const Color(0xFFFF7A8A),
            title: AppLocale.tr('Needs Improvement'),
            value: AppLocale.tr(weakestHabit?['name']?.toString() ?? 'No data'),
            subtitle: weakestHabit == null
                ? AppLocale.tr('No habits available')
                : AppLocale.digits(AppLocale.pick('${_completionCount(weakestHabit)} completions', '${_completionCount(weakestHabit)} বার সম্পন্ন')),
          ),
        ],
      ),
      ),
    );
  }

  Widget _insightCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppTheme.luxury(
        colors: AppTheme.forCategory(category),
        radius: 15,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.goldLight,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// PRAYER ANALYTICS PAGE
// ==================================================

class PrayerAnalyticsPage extends StatelessWidget {
  final Map<String, dynamic> prayerHistory;
  final DateTime periodStart;
  final int periodDays;
  final String periodLabel;

  const PrayerAnalyticsPage({
    super.key,
    required this.prayerHistory,
    required this.periodStart,
    required this.periodDays,
    required this.periodLabel,
  });

  final List<String> prayerNames = const [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _getPrayerData(
    String date,
    String prayer,
  ) {
    final dayData = prayerHistory[date];

    if (dayData is Map) {
      final data = dayData[prayer];

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    }

    return {};
  }

  int _prayerCount(String prayer) {
    int count = 0;

    for (int i = 0; i < periodDays; i++) {
      final date = _dateKey(
        periodStart.add(Duration(days: i)),
      );

      if (_getPrayerData(date, prayer)['prayed'] == true) {
        count++;
      }
    }

    return count;
  }

  int _extraCount(String extra) {
    int count = 0;

    for (int i = 0; i < periodDays; i++) {
      final date = _dateKey(
        periodStart.add(Duration(days: i)),
      );

      for (final prayer in prayerNames) {
        if (_getPrayerData(date, prayer)[extra] == true) {
          count++;
        }
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    final totalCompleted = prayerNames.fold<int>(
      0,
      (sum, prayer) => sum + _prayerCount(prayer),
    );

    final target = periodDays * 5;

    final percentage = target == 0
        ? 0
        : (totalCompleted / target * 100).round();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppTheme.bgFor(
            'Prayer',
            dark: AppPalette.of(context).dark,
          ),
        ),
      ),
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Tr('Prayer Statistics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.luxury(
              colors: AppTheme.prayer,
              radius: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.mosque_rounded,
                  color: AppTheme.gold,
                  size: 30,
                ),
                const SizedBox(height: 12),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Tr(
                  'Prayer Completion',
                  style: TextStyle(color: AppTheme.goldLight),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocale.digits(AppLocale.pick('$totalCompleted / $target prayers completed', '$target ওয়াক্তের মধ্যে $totalCompleted আদায়')),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: target == 0
                        ? 0
                        : totalCompleted / target,
                    minHeight: 8,
                    backgroundColor: Colors.white30,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                      AppTheme.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Text(
            periodLabel,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 23),

          const Tr(
            'Prayer-wise Statistics',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          ...prayerNames.map((prayer) {
            final count = _prayerCount(prayer);
            final progress = periodDays == 0
                ? 0.0
                : count / periodDays;

            return Container(
              margin: const EdgeInsets.only(bottom: 11),
              padding: const EdgeInsets.all(15),
              decoration: AppTheme.luxury(
        colors: AppTheme.prayer,
        radius: 15,
      ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Tr(
                          prayer,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '$count / $periodDays',
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                        AppTheme.gold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          const Tr(
            'Additional Worship',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Tr(
            'These activities are tracked separately from prayer completion.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 13),

          _extraCard(
            title: AppLocale.tr('Masjid'),
            subtitle: AppLocale.tr('Prayed in congregation'),
            count: _extraCount('masjid'),
            icon: Icons.mosque_rounded,
          ),

          const SizedBox(height: 10),

          _extraCard(
            title: AppLocale.tr('Adhkar'),
            subtitle: AppLocale.tr('Post-prayer remembrance'),
            count: _extraCount('adhkar'),
            icon: Icons.auto_awesome_rounded,
          ),

          const SizedBox(height: 10),

          _extraCard(
            title: AppLocale.tr('Ayatul Kursi'),
            subtitle: AppLocale.tr('Recitation after Salah'),
            count: _extraCount('ayat'),
            icon: Icons.menu_book_rounded,
          ),
        ],
      ),
      ),
    );
  }

  Widget _extraCard({
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
  }) {
    final target = periodDays * 5;
    final percentage = target == 0
        ? 0
        : (count / target * 100).round();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppTheme.luxury(
        colors: AppTheme.prayer,
        radius: 15,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.gold.withValues(alpha: 0.15),
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: target == 0
                        ? 0
                        : count / target,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                      AppTheme.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppTheme.gold,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
