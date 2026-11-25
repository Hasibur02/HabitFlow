import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the selected theme mode (System / Light / Dark) and remembers it.
class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _storageKey = 'theme_mode_v1';

  final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      switch (prefs.getString(_storageKey)) {
        case 'dark':
          mode.value = ThemeMode.dark;
          break;
        case 'system':
          mode.value = ThemeMode.system;
          break;
        default:
          mode.value = ThemeMode.light;
      }
    } catch (e) {
      debugPrint('Theme load error: $e');
    }
  }

  Future<void> setMode(ThemeMode newMode) async {
    mode.value = newMode;

    try {
      final prefs = await SharedPreferences.getInstance();

      final value = newMode == ThemeMode.dark
          ? 'dark'
          : newMode == ThemeMode.system
              ? 'system'
              : 'light';

      await prefs.setString(_storageKey, value);
    } catch (e) {
      debugPrint('Theme save error: $e');
    }
  }

  /// Quick light <-> dark switch.
  Future<void> toggle(bool currentlyDark) {
    return setMode(currentlyDark ? ThemeMode.light : ThemeMode.dark);
  }
}

/// Colors that change between light and dark mode.
class AppPalette {
  final bool dark;

  const AppPalette(this.dark);

  factory AppPalette.of(BuildContext context) {
    return AppPalette(Theme.of(context).brightness == Brightness.dark);
  }

  /// Main text color.
  Color get ink =>
      dark ? const Color(0xFFE8F4EE) : const Color(0xFF10332B);

  /// Secondary text color.
  Color get muted =>
      dark ? const Color(0xFF9DB5AC) : const Color(0xFF6B7F78);

  /// Cards, inputs and other surfaces that are white in light mode.
  Color get surface =>
      dark ? const Color(0xFF14231E) : Colors.white;

  Color get surfaceAlt =>
      dark ? const Color(0xFF1A2D27) : const Color(0xFFF4FAF6);

  Color get border =>
      dark ? const Color(0xFF2B4A3F) : const Color(0xFFDCEBE3);

  /// Emerald that stays readable on both backgrounds.
  Color get accent =>
      dark ? const Color(0xFF2FB38F) : const Color(0xFF0F6B57);

  Color get badgeBg =>
      dark ? const Color(0xFF183A30) : const Color(0xFFDDF1E8);

  /// Default screen background gradient.
  List<Color> get background => dark
      ? const [
          Color(0xFF08110E),
          Color(0xFF0C1B16),
          Color(0xFF0A1411),
        ]
      : const [
          Color(0xFFF4FAF6),
          Color(0xFFE8F4EE),
          Color(0xFFFFF8E8),
        ];
}