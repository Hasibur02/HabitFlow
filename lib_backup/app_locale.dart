import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';

/// Keeps the selected app language ('en' or 'bn') and remembers it.
class AppLocale {
  AppLocale._();

  static final AppLocale instance = AppLocale._();

  static const String _storageKey = 'app_language_v1';

  final ValueNotifier<String> language = ValueNotifier<String>('en');

  static bool get isBangla => instance.language.value == 'bn';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);

      language.value = saved == 'bn' ? 'bn' : 'en';
    } catch (e) {
      debugPrint('Language load error: $e');
    }
  }

  Future<void> setLanguage(String code) async {
    language.value = code == 'bn' ? 'bn' : 'en';

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, language.value);
    } catch (e) {
      debugPrint('Language save error: $e');
    }
  }

  /// Translates an English text. Unknown text is returned unchanged.
  static String tr(String en) {
    if (!isBangla) return en;
    return bnStrings[en] ?? en;
  }

  /// Picks the right text when you already have both versions.
  static String pick(String en, String bn) {
    return isBangla && bn.isNotEmpty ? bn : en;
  }

  /// 0123456789 -> ০১২৩৪৫৬৭৮৯ (only in Bangla mode).
  static String digits(Object value) {
    final text = value.toString();

    if (!isBangla) return text;

    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

    return text.replaceAllMapped(
      RegExp(r'[0-9]'),
      (match) => bangla[int.parse(match.group(0)!)],
    );
  }

  /// Call at the start of a build() so the screen rebuilds on language change.
  static void watch(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
  }
}

/// Placed above the Navigator so every screen can listen to language changes.
class AppLocaleScope extends InheritedNotifier<ValueNotifier<String>> {
  const AppLocaleScope({
    super.key,
    required ValueNotifier<String> notifier,
    required super.child,
  }) : super(notifier: notifier);
}

/// Works like Text(), but the text follows the selected language.
class Tr extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const Tr(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    return Text(
      AppLocale.tr(text),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
