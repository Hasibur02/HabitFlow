import 'app_locale.dart';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'notification_service.dart';
import 'adhkar_screen.dart';
import 'login_screen.dart';
import 'prayer_tracker.dart';
import 'profile_screen.dart';
import 'theme_controller.dart';

import 'features/tasks/tasks_screen.dart';
import 'features/tasks/task_repository.dart';
import 'models/task_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeController.instance.load();
  await AppLocale.instance.load();

  runApp(const HabitFlowApp());
}

// ==================================================
// EMERALD LUXURY THEME
// ==================================================

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF0F6B57);
  static const Color ink = Color(0xFF10332B);
  static const Color gold = Color(0xFFE2B857);
  static const Color goldLight = Color(0xFFF6E7B4);
  static const Color mint = Color(0xFFF4FAF6);
  static const Color deep = Color(0xFF06241E);

  static const List<Color> emerald = [
    Color(0xFF06241E),
    Color(0xFF0C4A3C),
    Color(0xFF14876B),
  ];

  static const List<Color> study = [
    Color(0xFF0F1B4D),
    Color(0xFF1F3A9E),
    Color(0xFF3F5BD9),
  ];

  static const List<Color> prayer = [
    Color(0xFF3A2A08),
    Color(0xFF7A5514),
    Color(0xFFC08A2B),
  ];

  static const List<Color> health = [
    Color(0xFF2E0B1A),
    Color(0xFF7A1F3D),
    Color(0xFFD6455F),
  ];

  static const List<Color> muted = [
    Color(0xFF1F2E2B),
    Color(0xFF2E4540),
  ];

  static const List<Color> splash = [
    Color(0xFF06241E),
    Color(0xFF0C4A3C),
    Color(0xFF06241E),
  ];

  static List<Color> forCategory(String category) {
    switch (category) {
      case 'Study':
        return study;
      case 'Spiritual':
        return emerald;
      case 'Prayer':
        return prayer;
      case 'Health & Fitness':
        return health;
      default:
        return emerald;
    }
  }

  static List<Color> bgFor(String category, {bool dark = false}) {
    if (dark) {
      switch (category) {
        case 'Study':
          return const [
            Color(0xFF0A0F1F),
            Color(0xFF0E1630),
            Color(0xFF0A1411),
          ];
        case 'Prayer':
          return const [
            Color(0xFF14100A),
            Color(0xFF1F170A),
            Color(0xFF0C0A06),
          ];
        case 'Health & Fitness':
          return const [
            Color(0xFF1A0B10),
            Color(0xFF24101A),
            Color(0xFF0A0709),
          ];
        default:
          return const [
            Color(0xFF08110E),
            Color(0xFF0C1B16),
            Color(0xFF0A1411),
          ];
      }
    }

    switch (category) {
      case 'Study':
        return const [
          Color(0xFFF3F6FF),
          Color(0xFFE6ECFC),
          Color(0xFFFFF8E8),
        ];
      case 'Prayer':
        return const [
          Color(0xFFFFF9EC),
          Color(0xFFFBEFD3),
          Color(0xFFFFF8E8),
        ];
      case 'Health & Fitness':
        return const [
          Color(0xFFFFF4F6),
          Color(0xFFFBE6EB),
          Color(0xFFFFF8E8),
        ];
      default:
        return const [
          Color(0xFFF4FAF6),
          Color(0xFFE8F4EE),
          Color(0xFFFFF8E8),
        ];
    }
  }

  static BoxDecoration luxury({
    List<Color> colors = emerald,
    double radius = 17,
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
}

// ==================================================
// APP
// ==================================================

class HabitFlowApp extends StatelessWidget {
  const HabitFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.instance.language,
      builder: (context, lang, _) {
        return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          locale: Locale(lang),
          supportedLocales: const [Locale('en'), Locale('bn')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return AppLocaleScope(
              notifier: AppLocale.instance.language,
              child: child ?? const SizedBox.shrink(),
            );
          },
          title: 'HabitFlow',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primary,
              brightness: Brightness.light,
            ).copyWith(onSurface: AppTheme.ink),
            scaffoldBackgroundColor: AppTheme.mint,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppTheme.mint,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: AppTheme.ink,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primary,
              brightness: Brightness.dark,
            ).copyWith(
              primary: const Color(0xFF2FB38F),
              onPrimary: AppTheme.deep,
              surface: const Color(0xFF0F1A16),
              onSurface: const Color(0xFFE8F4EE),
            ),
            scaffoldBackgroundColor: const Color(0xFF0A1411),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0A1411),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: Color(0xFFE8F4EE),
            ),
          ),
          home: const AppStartupScreen(),
        );
      },
    );
      },
    );
  }
}

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  bool isInitialized = false;
  String? initializationError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('STARTUP 1: Firebase starting');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      debugPrint('STARTUP 2: Firebase completed');

      await NotificationService.instance.initialize();

      debugPrint('STARTUP 3: Notification completed');

      if (!mounted) return;

      setState(() {
        isInitialized = true;
      });

      debugPrint('STARTUP 4: Startup completed');
    } catch (e) {
      debugPrint('STARTUP ERROR: $e');

      if (!mounted) return;

      setState(() {
        initializationError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    if (isInitialized) {
      return const AuthGate();
    }

    return Scaffold(
      backgroundColor: AppTheme.deep,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.splash,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/habitflow_logo.png',
                width: 145,
                height: 145,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              const Text(
                'HabitFlow',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Tr(
                'Build Better Habits. Build Better Life.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFC9E8DB),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (initializationError != null) ...[
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 28,
                ),
                const SizedBox(height: 8),
                const Tr(
                  'Unable to initialize HabitFlow',
                  style: TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      initializationError = null;
                    });
                    _initializeApp();
                  },
                  child: const Tr(
                    'Try Again',
                    style: TextStyle(color: AppTheme.gold),
                  ),
                ),
              ] else ...[
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Tr(
                  'YOUR PERSONAL LIFE COMPANION',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: Color(0xFFA9CBBE),
                  ),
                ),
              ],
              const SizedBox(height: 55),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================
// AUTH GATE
// ==================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint(
          'AUTH STATE: ${snapshot.connectionState}, '
          'Has Data: ${snapshot.hasData}',
        );

        // Firebase Auth is checking login status.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.deep,
            body: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppTheme.splash,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/habitflow_logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'HabitFlow',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Tr(
                      'Build Better Habits. Build Better Life.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFC9E8DB),
                      ),
                    ),
                    const SizedBox(height: 35),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.gold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Tr(
                      'Preparing your experience...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA9CBBE),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // User is logged in.
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // User is not logged in.
        return const LoginScreen();
      },
    );
  }
}

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
  int _analyticsRefreshKey = 0;
  static const String storageKey = 'habits';

  List<Map<String, dynamic>> habits = [];
  bool isLoading = true;
  int _prayersDoneToday = 0;

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

  Widget _buildHomeBody() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          _buildWelcomeCard(),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Tr(
                'Your Lifestyle',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
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
            ],
          ),

          const SizedBox(height: 6),

          const Tr(
            'Build a balanced and meaningful daily routine.',
            style: TextStyle(
              color: Color(0xFF6B7F78),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 18),

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

          const SizedBox(height: 23),

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
                const Expanded(
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
                      Tr(
                        'Consistency matters more than perfection.',
                        style: TextStyle(
                          color: AppTheme.goldLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 23),

          const Center(
            child: Tr(
              'One day at a time. Keep growing.',
              style: TextStyle(
                color: Color(0xFF96A8A1),
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

    await _restoreReminders();

    debugPrint('HOME 6: Reminders restored');

    await _loadPrayerProgress();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    debugPrint('HOME 7: Home loading completed');
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
    final dates = List<String>.from(
      habit['completedDates'] ?? [],
    );

    if (dates.contains(todayKey)) {
      dates.remove(todayKey);
    } else {
      dates.add(todayKey);
    }

    setState(() {
      habit['completedDates'] = dates;
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
          dates.contains(todayKey);
    }).length;
  }

  int _totalHabits(String category) {
    return habits.where(
      (habit) => habit['category'] == category,
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

  Widget _buildWelcomeCard() {
    final completed = _completedToday('Study') +
        _completedToday('Spiritual') +
        _completedToday('Health & Fitness');

    final total = habits.length;

    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.luxury(radius: 26),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -28,
              top: -35,
              child: Container(
                height: 145,
                width: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -65,
              child: Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.waving_hand_rounded,
                        color: AppTheme.gold,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formattedDate,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Tr(
                  'Make today count.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Tr(
                  'Small steps today, big changes tomorrow.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Tr(
                      "Today's habit progress",
                      style: TextStyle(
                        color: AppTheme.goldLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$completed / $total',
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0).toDouble(),
                    minHeight: 9,
                    backgroundColor: Colors.white.withValues(alpha: 0.20),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  total == 0
                      ? AppLocale.tr('Start building your daily routine.')
                      : AppLocale.digits(AppLocale.pick('${(progress * 100).round()}% of your habits completed today', 'আজ আপনার অভ্যাসের ${(progress * 100).round()}% সম্পন্ন হয়েছে')),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeBody(),
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
      bottomNavigationBar: Container(
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

                if (index == 4) {
                  _analyticsRefreshKey++;
                }
              });
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
    );
  }
}

// ==================================================
// CATEGORY HABITS SCREEN
// ==================================================

class CategoryHabitsScreen extends StatefulWidget {
  final String category;
  final List<Map<String, dynamic>> habits;
  final Map<String, IconData> habitIcons;

  final Future<void> Function() onAddHabit;
  final Future<void> Function(Map<String, dynamic>) onToggleHabit;
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
      final dates = List<String>.from(
        habit['completedDates'] ?? [],
      );
      return dates.contains(todayKey);
    }).length;
  }

  double get progress {
    if (currentHabits.isEmpty) return 0;
    return completedCount / currentHabits.length;
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
          if (widget.onOpenAdhkar != null) ...[
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
                                'সকাল · সন্ধ্যা · ঘুমের আগে',
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
            const SizedBox(height: 16),
          ],

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
                      AppLocale.digits(AppLocale.pick('$completedCount of ${items.length} completed', '${items.length}টির মধ্যে $completedCount সম্পন্ন')),
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
                '$completedCount/${items.length}',
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

// ==================================================
// HISTORY SCREEN
// ==================================================

class HistoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> habits;
  final Map<String, IconData> habitIcons;

  const HistoryScreen({
    super.key,
    required this.habits,
    required this.habitIcons,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime selectedMonth = DateTime.now();
  DateTime selectedDate = DateUtils.dateOnly(DateTime.now());

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> get completedHabits {
    return widget.habits.where((habit) {
      final dates = List<String>.from(
        habit['completedDates'] ?? [],
      );
      return dates.contains(_dateKey(selectedDate));
    }).toList();
  }

  void _changeMonth(int amount) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + amount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    final firstDay = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    final startingWeekday = firstDay.weekday % 7;

    return Scaffold(
      appBar: AppBar(
        title: const Tr(
          'Calendar History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.luxury(radius: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(
                        Icons.chevron_left,
                        color: AppTheme.gold,
                      ),
                    ),
                    Text(
                      '${_monthName(selectedMonth.month)} ${selectedMonth.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(
                        Icons.chevron_right,
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    'Sun',
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                  ].map((day) {
                    return Expanded(
                      child: Center(
                        child: Tr(
                          day,
                          style: const TextStyle(
                            color: AppTheme.goldLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: startingWeekday + daysInMonth,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 5,
                  ),
                  itemBuilder: (context, index) {
                    if (index < startingWeekday) {
                      return const SizedBox();
                    }

                    final day = index - startingWeekday + 1;
                    final date = DateTime(
                      selectedMonth.year,
                      selectedMonth.month,
                      day,
                    );

                    final key = _dateKey(date);
                    final isSelected =
                        _dateKey(selectedDate) == key;

                    final completed = widget.habits.any((habit) {
                      final dates = List<String>.from(
                        habit['completedDates'] ?? [],
                      );
                      return dates.contains(key);
                    });

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDate = date;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.gold
                              : completed
                                  ? const Color(0xFF2FB38F)
                                      .withValues(alpha: 0.35)
                                  : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.deep
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '${selectedDate.day} ${_monthName(selectedDate.month)} ${selectedDate.year}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (completedHabits.isEmpty)
            const Padding(
              padding: EdgeInsets.all(25),
              child: Center(
                child: Tr(
                  'No completed habits on this day.',
                ),
              ),
            )
          else
            ...completedHabits.map((habit) {
              final icon = widget.habitIcons[habit['icon']] ??
                  Icons.star_rounded;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: AppTheme.luxury(radius: 16),
                child: ListTile(
                  leading: Icon(
                    icon,
                    color: AppTheme.gold,
                  ),
                  title: Text(
                    AppLocale.tr(habit['name'].toString()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    AppLocale.tr(habit['category'].toString()),
                    style: const TextStyle(
                      color: AppTheme.goldLight,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.check_circle,
                    color: AppTheme.gold,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return AppLocale.tr(months[month - 1]);
  }
}

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

// ==================================================
// ADD HABIT DIALOG
// ==================================================

class AddHabitDialog extends StatefulWidget {
  final Map<String, IconData> habitIcons;

  const AddHabitDialog({
    super.key,
    required this.habitIcons,
  });

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  late final TextEditingController nameController;

  String selectedIcon = 'star';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _addHabit() {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop({
      'name': name,
      'icon': selectedIcon,
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    return AlertDialog(
      title: const Tr(
        'Add New Habit',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: AppLocale.tr('Habit name'),
              hintText: AppLocale.tr('Enter habit name'),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _addHabit(),
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            initialValue: selectedIcon,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: AppLocale.tr('Select icon'),
              border: OutlineInputBorder(),
            ),
            items: widget.habitIcons.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    Icon(entry.value),
                    const SizedBox(width: 10),
                    Text(entry.key),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedIcon = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Tr('Cancel'),
        ),

        FilledButton.icon(
          onPressed: _addHabit,
          icon: const Icon(Icons.add),
          label: const Tr('Add'),
        ),
      ],
    );
  }
}