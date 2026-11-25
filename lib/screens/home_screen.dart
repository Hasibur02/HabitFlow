import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habitflow/adhkar_screen.dart';
import 'package:habitflow/app_locale.dart';
import 'package:habitflow/app_theme.dart';
import 'package:habitflow/features/tasks/add_edit_task_screen.dart';
import 'package:habitflow/habit_utils.dart';
import 'package:habitflow/features/tasks/task_repository.dart';
import 'package:habitflow/features/tasks/tasks_screen.dart';
import 'package:habitflow/notification_service.dart';
import 'package:habitflow/prayer_tracker.dart';
import 'package:habitflow/profile_screen.dart';
import 'package:habitflow/screens/analytics_screen.dart';
import 'package:habitflow/screens/category_habits_screen.dart';
import 'package:habitflow/screens/history_screen.dart';
import 'package:habitflow/theme_controller.dart';
import 'package:habitflow/widgets/add_habit_dialog.dart';

// ==================================================
// HOME SCREEN
// ==================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _showNav = true;
  int _analyticsRefreshKey = 0;
  static const String storageKey = 'habits';

  List<Map<String, dynamic>> habits = [];
  bool isLoading = true;
  int _prayersDoneToday = 0;
  int _tasksTodayCount = 0;

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Study',
      'subtitle': 'Learn and grow every day',
      'icon': Icons.school_rounded,
      'color': const Color(0xFF3F5BD9),
      'gradient': AppTheme.study,
    },
    {
      'name': 'Spiritual',
      'subtitle': 'Strengthen your spirituality',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFF159B83),
      'gradient': AppTheme.emerald,
    },
    {
      'name': 'Prayer',
      'subtitle': 'Stay connected with Allah',
      'icon': Icons.mosque_rounded,
      'color': const Color(0xFFDA9635),
      'gradient': AppTheme.prayer,
    },
    {
      'name': 'Health & Fitness',
      'subtitle': 'Build a healthy lifestyle',
      'icon': Icons.fitness_center_rounded,
      'color': const Color(0xFFE16B83),
      'gradient': AppTheme.health,
    },
  ];

  final Map<String, IconData> habitIcons = {
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

  String get todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();

    debugPrint('HOME 1: HomeScreen started');

    _loadHabits();
  }

  Widget _sectionHeader(String title, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.gold, Color(0xFFC08A2B)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Tr(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: AppTheme.luxury(colors: colors, radius: 18),
                child: Icon(icon, color: AppTheme.gold, size: 26),
              ),
              const SizedBox(height: 7),
              Tr(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _quickAction(
          icon: Icons.add_task_rounded,
          label: 'Add Task',
          colors: AppTheme.emerald,
          onTap: _quickAddTask,
        ),
        _quickAction(
          icon: Icons.mosque_rounded,
          label: 'Prayer',
          colors: AppTheme.prayer,
          onTap: _openPrayerTracker,
        ),
        _quickAction(
          icon: Icons.auto_stories_rounded,
          label: 'Adhkar',
          colors: AppTheme.study,
          onTap: _openAdhkar,
        ),
        _quickAction(
          icon: Icons.insights_rounded,
          label: 'Insights',
          colors: AppTheme.health,
          onTap: () {
            setState(() {
              _selectedIndex = 4;
              _analyticsRefreshKey++;
            });
          },
        ),
      ],
    );
  }

  String get _dailyQuote {
    final now = DateTime.now();
    final day = now.difference(DateTime(now.year, 1, 1)).inDays;

    final quotes = <List<String>>[
      [
        'Consistency matters more than perfection.',
        'নিখুঁত হওয়ার চেয়ে ধারাবাহিকতা বেশি গুরুত্বপূর্ণ।',
      ],
      [
        'Small deeds done regularly are the most beloved to Allah.',
        'নিয়মিত করা ছোট আমলই আল্লাহর কাছে সবচেয়ে প্রিয়।',
      ],
      [
        'Begin with Bismillah, and keep going.',
        'বিসমিল্লাহ বলে শুরু করো, থেমো না।',
      ],
      [
        'Every day is a fresh chance to grow.',
        'প্রতিটি দিন নতুন করে এগোনোর সুযোগ।',
      ],
      [
        'Do what you can, with what you have, today.',
        'আজ যা পারো, যা আছে তা দিয়েই শুরু করো।',
      ],
      [
        'Patience and effort turn habits into character.',
        'ধৈর্য আর চেষ্টাই অভ্যাসকে চরিত্রে বদলে দেয়।',
      ],
      [
        'One day at a time. Keep growing.',
        'একটি একটি করে দিন, এগিয়ে চলো।',
      ],
    ];

    final q = quotes[day % quotes.length];
    return AppLocale.pick(q[0], q[1]);
  }

  Widget _buildTodayFocus() {
    final pal = AppPalette.of(context);

    final pending = habits.where((habit) {
      if (!HabitUtils.isScheduledToday(habit)) return false;
      final dates = List<String>.from(habit['completedDates'] ?? []);
      return !dates.contains(todayKey);
    }).toList();

    final shown = pending.take(3).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: shown.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: AppTheme.luxury(radius: 14),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: AppTheme.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocale.pick(
                        'All habits done today. MashaAllah!',
                        'আজকের সব হ্যাবিট সম্পন্ন। মাশাআল্লাহ!',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                ...shown.map((habit) {
                  final icon = habitIcons[habit['icon']] ?? Icons.star_rounded;
                  final gradient = AppTheme.forCategory(
                    habit['category']?.toString() ?? '',
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _toggleHabit(habit),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 42,
                              width: 42,
                              decoration: AppTheme.luxury(
                                colors: gradient,
                                radius: 14,
                              ),
                              child: Icon(
                                icon,
                                color: AppTheme.gold,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocale.tr(
                                      habit['name']?.toString() ?? 'Habit',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppLocale.tr(
                                      habit['category']?.toString() ?? '',
                                    ),
                                    style: TextStyle(
                                      color: pal.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.radio_button_unchecked_rounded,
                              color: AppTheme.gold.withValues(alpha: 0.9),
                              size: 26,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (pending.length > shown.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Text(
                      AppLocale.digits(
                        AppLocale.pick(
                          '+${pending.length - shown.length} more today',
                          'আরও ${pending.length - shown.length}টি বাকি',
                        ),
                      ),
                      style: TextStyle(
                        color: pal.accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildHomeBody() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          _buildWelcomeCard(),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: AppPalette.of(context).surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.gold.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _buildQuickActions(),
          ),

          const SizedBox(height: 26),

          _sectionHeader(
            AppLocale.pick("Today's Focus", 'আজকের ফোকাস'),
          ),

          const SizedBox(height: 12),

          _buildTodayFocus(),

          const SizedBox(height: 28),

          _sectionHeader(
            'Your Lifestyle',
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: AppPalette.of(context).badgeBg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.6),
                ),
              ),
              child: Tr(
                '4 CATEGORIES',
                style: TextStyle(
                  color: AppPalette.of(context).accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Tr(
              'Build a balanced and meaningful daily routine.',
              style: TextStyle(
                color: AppPalette.of(context).muted,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),

          GridView.builder(
            itemCount: categories.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 13,
              mainAxisSpacing: 13,
              mainAxisExtent: 205,
            ),
            itemBuilder: (context, index) {
              return _buildCategoryCard(categories[index]);
            },
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.luxury(radius: 22),
            child: Row(
              children: [
                Container(
                  height: 47,
                  width: 47,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tr(
                        'A gentle reminder',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        _dailyQuote,
                        style: const TextStyle(
                          color: AppTheme.goldLight,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          Center(
            child: Tr(
              'One day at a time. Keep growing.',
              style: TextStyle(
                color: AppPalette.of(context).muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // DEFAULT HABITS
  // --------------------------------------------------

  List<Map<String, dynamic>> _defaultHabits() {
    return [
      {
        'name': 'Wake up early',
        'icon': 'sun',
        'category': 'Study',
      },
      {
        'name': 'Study for BCS',
        'icon': 'school',
        'category': 'Study',
      },
      {
        'name': 'English Vocabulary',
        'icon': 'book',
        'category': 'Study',
      },
      {
        'name': 'Quran Tilawat',
        'icon': 'book',
        'category': 'Spiritual',
      },
      {
        'name': 'Morning Adhkar',
        'icon': 'star',
        'category': 'Spiritual',
      },
      {
        'name': 'Evening Adhkar',
        'icon': 'star',
        'category': 'Spiritual',
      },
      {
        'name': 'Exercise',
        'icon': 'fitness',
        'category': 'Health & Fitness',
      },
      {
        'name': 'Walking',
        'icon': 'walk',
        'category': 'Health & Fitness',
      },
      {
        'name': 'Drink 3L water',
        'icon': 'water',
        'category': 'Health & Fitness',
      },
      {
        'name': 'Sleep on time',
        'icon': 'sleep',
        'category': 'Health & Fitness',
      },
      {
        'name': 'Healthy Eating',
        'icon': 'food',
        'category': 'Health & Fitness',
      },
    ];
  }

  Map<String, dynamic> _prepareNewHabit(
    Map<String, dynamic> habit,
  ) {
    return {
      ...habit,
      'completedDates': <String>[],
      'reminderEnabled': false,
      'reminderId':
          DateTime.now().microsecondsSinceEpoch % 1000000,
      'reminderHour': 8,
      'reminderMinute': 0,
    };
  }

  // --------------------------------------------------
  // LOAD AND SAVE
  // --------------------------------------------------

  Future<void> _loadHabits() async {
    debugPrint('HOME 2: Loading habits started');

    final prefs = await SharedPreferences.getInstance();
    debugPrint('HOME 3: SharedPreferences loaded');

    final savedData = prefs.getString(storageKey);

    if (savedData == null) {
      debugPrint('HOME 4: Creating default habits');

      habits = _defaultHabits()
          .map(_prepareNewHabit)
          .toList();

      await _saveHabits();
    } else {
      debugPrint('HOME 4: Reading saved habits');

      final decoded = jsonDecode(savedData) as List;

      habits = decoded.map((item) {
        final habit = Map<String, dynamic>.from(item);

        if (habit['completedDates'] == null) {
          habit['completedDates'] = <String>[];

          if (habit['done'] == true) {
            habit['completedDates'].add(todayKey);
          }
        }

        habit.remove('done');

        final name = habit['name']?.toString() ?? '';

        if (name == 'Read Quran') {
          habit['name'] = 'Quran Tilawat';
          habit['category'] = 'Spiritual';
        } else if (name == 'Morning exercise') {
          habit['name'] = 'Exercise';
          habit['category'] = 'Health & Fitness';
        } else if (name == 'Drink 3L water') {
          habit['category'] = 'Health & Fitness';
        } else if (name == 'Wake up early' ||
            name == 'Study for BCS' ||
            name == 'English Vocabulary') {
          habit['category'] = 'Study';
        }

        habit['category'] ??= 'Study';
        habit['icon'] ??= 'star';
        habit['reminderEnabled'] ??= false;
        habit['reminderId'] ??=
            DateTime.now().microsecondsSinceEpoch % 1000000;
        habit['reminderHour'] ??= 8;
        habit['reminderMinute'] ??= 0;

        return habit;
      }).toList();

      await _saveHabits();
    }

    debugPrint('HOME 5: Habits loaded: ${habits.length}');

    await _loadPrayerProgress();
    await _loadTaskProgress();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    debugPrint('HOME 6: Home loading completed');

    // The home page is ready: let the native splash go.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    // Scheduling reminders is slow and not visible, so it runs in the
    // background instead of keeping the user on a loading screen.
    unawaited(_restoreReminders());
  }

  Future<void> _loadPrayerProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('prayer_tracker_v1');

      var count = 0;

      if (saved != null) {
        final decoded = jsonDecode(saved);

        if (decoded is Map) {
          final day = decoded[todayKey];

          if (day is Map) {
            for (final prayer in [
              'Fajr',
              'Dhuhr',
              'Asr',
              'Maghrib',
              'Isha',
            ]) {
              final data = day[prayer];

              if (data is Map && data['prayed'] == true) {
                count++;
              }
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _prayersDoneToday = count;
      });
    } catch (e) {
      debugPrint('Prayer progress error: $e');
    }
  }

  Future<void> _loadTaskProgress() async {
    try {
      final tasks = await TaskRepository.instance.getTasks();
      final today = DateUtils.dateOnly(DateTime.now());

      final count = tasks.where((task) {
        return task.isScheduledOn(today) &&
            !task.isCompletedOn(today) &&
            !task.isSkippedOn(today);
      }).length;

      if (!mounted) return;

      setState(() {
        _tasksTodayCount = count;
      });
    } catch (e) {
      debugPrint('Task progress error: $e');
    }
  }

  Future<void> _quickAddTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditTaskScreen(),
      ),
    );

    await _loadTaskProgress();
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(habits));
  }

  // --------------------------------------------------
  // REMINDERS
  // --------------------------------------------------

  Future<void> _restoreReminders() async {
    for (final habit in habits) {
      if (habit['reminderEnabled'] == true) {
        await NotificationService.instance.scheduleDailyReminder(
          id: habit['reminderId'],
          habitName: habit['name'],
          hour: habit['reminderHour'],
          minute: habit['reminderMinute'],
        );
      }
    }
  }

  Future<void> _setReminder(
    Map<String, dynamic> habit,
  ) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: habit['reminderHour'] ?? 8,
        minute: habit['reminderMinute'] ?? 0,
      ),
    );

    if (selectedTime == null) return;

    await NotificationService.instance.scheduleDailyReminder(
      id: habit['reminderId'],
      habitName: habit['name'],
      hour: selectedTime.hour,
      minute: selectedTime.minute,
    );

    if (!mounted) return;

    setState(() {
      habit['reminderEnabled'] = true;
      habit['reminderHour'] = selectedTime.hour;
      habit['reminderMinute'] = selectedTime.minute;
    });

    await _saveHabits();
  }

  Future<void> _removeReminder(
    Map<String, dynamic> habit,
  ) async {
    await NotificationService.instance.cancelReminder(
      habit['reminderId'],
    );

    if (!mounted) return;

    setState(() {
      habit['reminderEnabled'] = false;
    });

    await _saveHabits();
  }

  // --------------------------------------------------
  // HABIT ACTIONS
  // --------------------------------------------------

  Future<void> _toggleHabit(
    Map<String, dynamic> habit,
  ) async {
    setState(() {
      HabitUtils.tap(habit, todayKey);
    });

    await _saveHabits();
  }

  /// Counter habits: +1 / -1 (delta) or an exact value (setTo).
  Future<void> _adjustHabit(
    Map<String, dynamic> habit, {
    int delta = 0,
    int? setTo,
  }) async {
    final current = HabitUtils.countOn(habit, todayKey);

    setState(() {
      HabitUtils.setCount(habit, todayKey, setTo ?? current + delta);
    });

    await _saveHabits();
  }

  Future<void> _deleteHabit(
    Map<String, dynamic> habit,
  ) async {
    if (habit['reminderEnabled'] == true) {
      await NotificationService.instance.cancelReminder(
        habit['reminderId'],
      );
    }

    setState(() {
      habits.remove(habit);
    });

    await _saveHabits();
  }

  Future<void> _addHabit(String category) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AddHabitDialog(
          habitIcons: habitIcons,
        );
      },
    );

    if (result == null || !mounted) return;

    final newHabit = _prepareNewHabit({
      'name': result['name'],
      'icon': result['icon'],
      'category': category,
      'days': result['days'],
      'target': result['target'],
      'unit': result['unit'],
      'progress': <String, int>{},
    });

    setState(() {
      habits.add(newHabit);
    });

    await _saveHabits();
  }

  // --------------------------------------------------
  // NAVIGATION
  // --------------------------------------------------

  void _openCategoryPage(String category) {
    if (category == 'Prayer') {
      _openPrayerTracker();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryHabitsScreen(
          category: category,
          habits: habits,
          habitIcons: habitIcons,
          onAddHabit: () => _addHabit(category),
          onToggleHabit: _toggleHabit,
          onAdjustHabit: _adjustHabit,
          onDeleteHabit: _deleteHabit,
          onSetReminder: _setReminder,
          onRemoveReminder: _removeReminder,
          onOpenAdhkar: category == 'Spiritual' ? _openAdhkar : null,
        ),
      ),
    );
  }

  Future<void> _markAdhkarHabit(String kind) async {
    final habitName =
        kind == 'morning' ? 'Morning Adhkar' : 'Evening Adhkar';

    final matches = habits.where((habit) => habit['name'] == habitName);

    if (matches.isEmpty) return;

    final habit = matches.first;

    final dates = List<String>.from(habit['completedDates'] ?? []);

    if (dates.contains(todayKey)) return;

    dates.add(todayKey);

    setState(() {
      habit['completedDates'] = dates;
    });

    await _saveHabits();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$habitName" habit marked as done.')),
    );
  }

  Future<void> _openAdhkar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdhkarScreen(onCompleted: _markAdhkarHabit),
      ),
    );
  }

  void _openPrayerTracker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrayerTrackerScreen(),
      ),
    ).then((_) => _loadPrayerProgress());
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryScreen(
          habits: habits,
          habitIcons: habitIcons,
        ),
      ),
    );
  }

  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyticsScreen(habits: habits),
      ),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(habits: habits),
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _openTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TasksScreen(),
      ),
    );
  }

  // --------------------------------------------------
  // HOME UI - PREMIUM DASHBOARD
  // --------------------------------------------------

  int _completedToday(String category) {
    return habits.where((habit) {
      final dates = List<String>.from(
        habit['completedDates'] ?? [],
      );

      return habit['category'] == category &&
          HabitUtils.isScheduledToday(habit) &&
          dates.contains(todayKey);
    }).length;
  }

  int _totalHabits(String category) {
    return habits.where(
      (habit) =>
          habit['category'] == category &&
          HabitUtils.isScheduledToday(habit),
    ).length;
  }

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) return AppLocale.tr('Good Morning!');
    if (hour < 17) return AppLocale.tr('Good Afternoon!');
    if (hour < 20) return AppLocale.tr('Good Evening!');
    return AppLocale.tr('Good Night!');
  }

  String get _formattedDate {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];

    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    final now = DateTime.now();

    return '${AppLocale.tr(weekdays[now.weekday - 1])}, '
        '${now.day} ${AppLocale.tr(months[now.month - 1])} ${now.year}';
  }

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim() ?? '';

    if (name.isNotEmpty) return name;

    final email = user?.email ?? '';

    if (email.contains('@')) return email.split('@').first;

    return AppLocale.tr('Friend');
  }

  Widget _heroStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.gold.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.gold, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Tr(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.goldLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final completed = _completedToday('Study') +
        _completedToday('Spiritual') +
        _completedToday('Health & Fitness');

    final total =
        habits.where(HabitUtils.isScheduledToday).length;

    final progress = total == 0
        ? 0.0
        : (completed / total).clamp(0.0, 1.0).toDouble();

    final percent = (progress * 100).round();

    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    final name = _userName;
    final initial = String.fromCharCode(name.runes.first).toUpperCase();

    Widget bubble(double size, double alpha) {
      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: AppTheme.luxury(radius: 28),
      // The clip is on the whole card, so the decoration is cut by the
      // card edge only and never inside the card.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(right: -34, top: -44, child: bubble(160, 0.06)),
            Positioned(left: -46, bottom: -64, child: bubble(150, 0.05)),
            Positioned(
              right: 22,
              bottom: 96,
              child: Icon(
                Icons.mosque_rounded,
                size: 74,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Salam, name and date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.gold,
                            width: 1.6,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF0C4A3C),
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null
                              ? Text(
                                  initial,
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocale.tr('Assalamu Alaikum'),
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppTheme.goldLight,
                                  size: 12,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    AppLocale.digits(_formattedDate),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.78),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Divider(
                    height: 1,
                    color: AppTheme.gold.withValues(alpha: 0.25),
                  ),

                  const SizedBox(height: 16),

                  // Message and progress ring
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Tr(
                              'Make today count.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Tr(
                              'Small steps today, big changes tomorrow.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        height: 62,
                        width: 62,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 62,
                              width: 62,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 6,
                                strokeCap: StrokeCap.round,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  AppTheme.gold,
                                ),
                              ),
                            ),
                            Text(
                              AppLocale.digits('$percent%'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Quick numbers
                  Row(
                    children: [
                      _heroStat(
                        icon: Icons.repeat_rounded,
                        value: AppLocale.digits('$completed/$total'),
                        label: 'Habits',
                      ),
                      const SizedBox(width: 8),
                      _heroStat(
                        icon: Icons.mosque_rounded,
                        value: AppLocale.digits('$_prayersDoneToday/5'),
                        label: 'Prayer',
                      ),
                      const SizedBox(width: 8),
                      _heroStat(
                        icon: Icons.checklist_rounded,
                        value: AppLocale.digits('$_tasksTodayCount'),
                        label: 'Tasks',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final name = category['name'] as String;
    final icon = category['icon'] as IconData;
    final gradient = category['gradient'] as List<Color>;

    final isPrayer = name == 'Prayer';
    final completed = isPrayer ? _prayersDoneToday : _completedToday(name);
    final total = isPrayer ? 5 : _totalHabits(name);

    final progress = total == 0
        ? 0.0
        : (completed / total).clamp(0.0, 1.0).toDouble();

    final pillText = isPrayer
        ? AppLocale.digits(AppLocale.pick('$completed / 5 prayed today', '৫ ওয়াক্তের মধ্যে $completed আদায়'))
        : AppLocale.digits(AppLocale.pick('$completed / $total completed', '$total টির মধ্যে $completed সম্পন্ন'));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openCategoryPage(name),
        child: Ink(
          decoration: AppTheme.luxury(colors: gradient, radius: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -32,
                  top: -35,
                  child: Container(
                    height: 115,
                    width: 115,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: -65,
                  child: Container(
                    height: 115,
                    width: 115,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                // Keeps the text readable even with a very large system font.
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.1,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.gold.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: AppTheme.gold,
                            size: 23,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Tr(
                            name,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              AppLocale.tr(category['subtitle']?.toString() ?? ''),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 10.5,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.22),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                              AppTheme.gold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.gold.withValues(alpha: 0.30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.gold,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    pillText,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitsTab() {
    // All four categories, including Prayer (opens the Prayer Tracker).
    final habitCategories = categories;

    return Scaffold(
      appBar: AppBar(
        title: const Tr(
          'My Habits',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Tr(
            'Build Better Habits',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Tr(
            'Track your daily routines and stay consistent.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            itemCount: habitCategories.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 13,
              mainAxisSpacing: 13,
              mainAxisExtent: 195,
            ),
            itemBuilder: (context, index) {
              return _buildCategoryCard(habitCategories[index]);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    debugPrint('HOME UI: Build started');

    if (isLoading) {
      // Same look as the splash, so it feels like one continuous page.
      return const Scaffold(
        backgroundColor: Color(0xFF09211B),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF17372F),
                Color(0xFF0F2D26),
                Color(0xFF09211B),
              ],
            ),
          ),
          child: SizedBox.expand(),
        ),
      );
    }

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              toolbarHeight: 68,
              titleSpacing: 18,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 39,
                    width: 39,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primary,
                          Color(0xFF2FB38F),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.7),
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'HabitFlow',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: AppLocale.tr('Dark mode'),
                  icon: Icon(
                    AppPalette.of(context).dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                  ),
                  onPressed: () {
                    ThemeController.instance.toggle(
                      AppPalette.of(context).dark,
                    );
                  },
                ),
                PopupMenuButton<String>(
                  tooltip: AppLocale.tr('Account'),
                  icon: const Icon(
                    Icons.account_circle_outlined,
                    size: 26,
                  ),
                  onSelected: (value) {
                    if (value == 'profile') {
                      _openProfile();
                    } else if (value == 'logout') {
                      _logout();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline_rounded),
                          SizedBox(width: 10),
                          Tr('Profile'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded),
                          SizedBox(width: 10),
                          Tr('Logout'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis != Axis.vertical) return false;

          if (notification.direction == ScrollDirection.reverse &&
              _showNav) {
            setState(() => _showNav = false);
          } else if (notification.direction == ScrollDirection.forward &&
              !_showNav) {
            setState(() => _showNav = true);
          }

          return false;
        },
        child: IndexedStack(
        index: _selectedIndex,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppPalette.of(context).background,
              ),
            ),
            child: _buildHomeBody(),
          ),
          const TasksScreen(),
          _buildHabitsTab(),
          HistoryScreen(
            habits: habits,
            habitIcons: habitIcons,
          ),
          AnalyticsScreen(
            key: ValueKey(_analyticsRefreshKey),
            habits: habits,
          ),
        ],
      ),
      ),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: !_showNav
            ? const SizedBox(width: double.infinity)
            : Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0C4A3C),
                AppTheme.deep,
              ],
            ),
            border: Border(
              top: BorderSide(
                color: AppTheme.gold.withValues(alpha: 0.55),
              ),
            ),
          ),
          child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppTheme.gold.withValues(alpha: 0.18),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected ? AppTheme.gold : Colors.white60,
              );
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.gold : Colors.white60,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
                _showNav = true;

                if (index == 4) {
                  _analyticsRefreshKey++;
                }
              });

              if (index == 0) {
                _loadPrayerProgress();
                _loadTaskProgress();
              }
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: AppLocale.tr('Home'),
              ),
              NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist_rounded),
                label: AppLocale.tr('Tasks'),
              ),
              NavigationDestination(
                icon: Icon(Icons.repeat_outlined),
                selectedIcon: Icon(Icons.repeat_rounded),
                label: AppLocale.tr('Habits'),
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: AppLocale.tr('Calendar'),
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights_rounded),
                label: AppLocale.tr('Insights'),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
