import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:habitflow/app_locale.dart';
import 'package:habitflow/app_theme.dart';
import 'package:habitflow/firebase_options.dart';
import 'package:habitflow/login_screen.dart';
import 'package:habitflow/notification_service.dart';
import 'package:habitflow/screens/home_screen.dart';
import 'package:habitflow/theme_controller.dart';

// Keeps `import 'main.dart'` working in files that use AppTheme from here.
export 'package:habitflow/app_theme.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // The only splash is the native one (logo + tagline). Keep it on screen
  // until the app is ready; there is no second splash page in Flutter.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Safety net: never keep the splash longer than this.
  Timer(const Duration(seconds: 10), FlutterNativeSplash.remove);

  await ThemeController.instance.load();
  await AppLocale.instance.load();

  runApp(const HabitFlowApp());
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
  static const Color _bg = Color(0xFF0E2B24);

  bool isInitialized = false;
  bool _splashRemoved = false;
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

      // Show the error page instead of the native splash.
      FlutterNativeSplash.remove();

      setState(() {
        _splashRemoved = true;
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

    if (initializationError != null) {
      return Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 32,
                ),
                const SizedBox(height: 10),
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
              ],
            ),
          ),
        ),
      );
    }

    // Normally the native splash is still on screen here, so nothing is
    // visible. Only after an error + retry do we show a small spinner.
    return Scaffold(
      backgroundColor: _bg,
      body: _splashRemoved
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
              ),
            )
          : null,
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
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        debugPrint(
          'AUTH STATE: ${snapshot.connectionState}, '
          'Has Data: ${snapshot.hasData}',
        );

        // Firebase Auth is still checking. The native splash is on screen,
        // so there is nothing to draw here (no second loading page).
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Color(0xFF0E2B24));
        }

        // User is logged in.
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // User is not logged in: show the login page, then remove the splash.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FlutterNativeSplash.remove();
        });

        return const LoginScreen();
      },
    );
  }
}
