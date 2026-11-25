import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==================================================
// APP LANGUAGE
//
// English is the default the first time the app opens.
// The choice is saved on the phone and restored on the
// next start. It is changed from Profile > Language.
// ==================================================

enum AppLanguage { english, bangla }

class LanguageController {
  LanguageController._();

  static final LanguageController instance = LanguageController._();

  static const String _storageKey = 'app_language_v1';

  final ValueNotifier<AppLanguage> language =
      ValueNotifier<AppLanguage>(AppLanguage.english);

  bool get isBangla => language.value == AppLanguage.bangla;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);

      language.value =
          saved == 'bangla' ? AppLanguage.bangla : AppLanguage.english;
    } catch (e) {
      debugPrint('Language load error: $e');
    }
  }

  Future<void> setLanguage(AppLanguage value) async {
    language.value = value;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        value == AppLanguage.bangla ? 'bangla' : 'english',
      );
    } catch (e) {
      debugPrint('Language save error: $e');
    }
  }
}

/// Rebuilds its child whenever the language changes.
class LangBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, AppLanguage language) builder;

  const LangBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageController.instance.language,
      builder: (context, language, _) => builder(context, language),
    );
  }
}