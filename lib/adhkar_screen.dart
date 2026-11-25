import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adhkar_data.dart';
import 'app_locale.dart';
import 'theme_controller.dart';

// ==================================================
// ADHKAR & DUA SCREEN
//
// Tabs: Morning, Evening, Before Sleep, Favorites.
// Every card shows the Arabic text. Pronunciation, meaning and
// the hadith reference open with "Show details". A tap counter is
// saved for today, so it survives closing the app.
//
// The language follows Profile > Language (AppLocale).
// Arabic, Bangla and English texts live in adhkar_data.dart and
// adhkar_extra.dart.
// ==================================================

class AdhkarScreen extends StatefulWidget {
  /// 0 = morning, 1 = evening, 2 = before sleep, 3 = favorites
  final int? initialTab;

  /// Called once when a whole list is finished.
  /// [kind] is 'morning' or 'evening'.
  final void Function(String kind)? onCompleted;

  const AdhkarScreen({
    super.key,
    this.initialTab,
    this.onCompleted,
  });

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _TabInfo {
  final String key;

  /// English text. It is translated when shown.
  final String label;
  final String subtitleEn;
  final String subtitleBn;
  final IconData icon;
  final List<Dhikr> items;
  final List<Color> gradient;
  final String? habitKind;

  const _TabInfo({
    required this.key,
    required this.label,
    required this.subtitleEn,
    required this.subtitleBn,
    required this.icon,
    required this.items,
    required this.gradient,
    this.habitKind,
  });
}

class _AdhkarScreenState extends State<AdhkarScreen>
    with SingleTickerProviderStateMixin {
  // ---------------- EMERALD LUXURY THEME ----------------
  static const Color gold = Color(0xFFE2B857);
  static const Color goldLight = Color(0xFFF6E7B4);
  static const Color deep = Color(0xFF06241E);

  static const String _progressKey = 'adhkar_progress_v1';
  static const String _sizeKey = 'adhkar_arabic_size';
  static const String _fontKey = 'adhkar_font_v1';
  static const String _favoritesKey = 'adhkar_favorites_v1';

  static const List<_TabInfo> _tabs = [
    _TabInfo(
      key: 'morning',
      label: 'Morning',
      subtitleEn: 'Morning Adhkar',
      subtitleBn: 'সকালের যিকির',
      icon: Icons.wb_sunny_rounded,
      items: morningAdhkar,
      gradient: [
        Color(0xFF3A2A08),
        Color(0xFF7A5514),
        Color(0xFFC08A2B),
      ],
      habitKind: 'morning',
    ),
    _TabInfo(
      key: 'evening',
      label: 'Evening',
      subtitleEn: 'Evening Adhkar',
      subtitleBn: 'সন্ধ্যার যিকির',
      icon: Icons.nights_stay_rounded,
      items: eveningAdhkar,
      gradient: [
        Color(0xFF0F1B4D),
        Color(0xFF1F3A9E),
        Color(0xFF3F5BD9),
      ],
      habitKind: 'evening',
    ),
    _TabInfo(
      key: 'sleep',
      label: 'Before Sleep',
      subtitleEn: 'Before Sleep',
      subtitleBn: 'ঘুমের আগের দু\'আ',
      icon: Icons.bedtime_rounded,
      items: sleepAdhkar,
      gradient: [
        Color(0xFF06241E),
        Color(0xFF0C4A3C),
        Color(0xFF14876B),
      ],
    ),
    _TabInfo(
      key: 'favorites',
      label: 'Favorites',
      subtitleEn: 'My favorite duas',
      subtitleBn: 'আমার পছন্দের দু\'আ',
      icon: Icons.star_rounded,
      items: [],
      gradient: [
        Color(0xFF2E0B1A),
        Color(0xFF7A1F3D),
        Color(0xFFD6455F),
      ],
    ),
  ];

  static const List<Color> _mutedGradient = [
    Color(0xFF1F2E2B),
    Color(0xFF2E4540),
  ];

  AppPalette get palette => AppPalette.of(context);

  late final TabController _tabController;

  Map<String, int> counts = {};
  final Set<String> _notified = {};
  Set<String> favorites = {};

  /// Cards whose pronunciation, meaning and reference are open.
  final Set<String> _expanded = {};

  double arabicSize = 24;

  /// 'amiri', 'scheherazade', 'indopak' or 'default'.
  /// 'indopak' needs a font with family name IndoPak in pubspec.yaml.
  String fontChoice = 'amiri';

  bool isLoading = true;

  AudioPlayer? _player;
  String? _playingKey;

  String get todayKey {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  int get _startTab {
    final given = widget.initialTab;

    if (given != null) {
      return given.clamp(0, _tabs.length - 1).toInt();
    }

    final hour = DateTime.now().hour;

    if (hour >= 21) return 2;
    if (hour >= 15) return 1;

    return 0;
  }

  String? get _fontFamily {
    switch (fontChoice) {
      case 'amiri':
        return 'Amiri';
      case 'scheherazade':
        return 'ScheherazadeNew';
      case 'indopak':
        return 'IndoPak';
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _startTab,
    );

    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _player?.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // ITEMS
  // --------------------------------------------------

  List<Dhikr> get _favoriteItems {
    final seen = <String>{};
    final result = <Dhikr>[];

    for (final item in [
      ...morningAdhkar,
      ...eveningAdhkar,
      ...sleepAdhkar,
    ]) {
      if (favorites.contains(item.id) && seen.add(item.id)) {
        result.add(item);
      }
    }

    return result;
  }

  List<Dhikr> _itemsFor(_TabInfo tab) {
    return tab.key == 'favorites' ? _favoriteItems : tab.items;
  }

  // --------------------------------------------------
  // LOAD AND SAVE
  // --------------------------------------------------

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      arabicSize = prefs.getDouble(_sizeKey) ?? 24;
      fontChoice = prefs.getString(_fontKey) ?? 'amiri';
      favorites = (prefs.getStringList(_favoritesKey) ?? []).toSet();

      final saved = prefs.getString(_progressKey);

      if (saved != null) {
        final decoded = jsonDecode(saved);

        // Progress is per day. A new day starts from zero.
        if (decoded is Map && decoded['date'] == todayKey) {
          final raw = decoded['counts'];

          if (raw is Map) {
            counts = raw.map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
            );
          }
        }
      }

      // Lists that were already finished earlier today must not
      // trigger the "completed" action again.
      for (final tab in _tabs) {
        if (_isTabComplete(tab)) {
          _notified.add(tab.key);
        }
      }
    } catch (e) {
      debugPrint('Adhkar load error: $e');
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _progressKey,
        jsonEncode({
          'date': todayKey,
          'counts': counts,
        }),
      );
    } catch (e) {
      debugPrint('Adhkar save error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setDouble(_sizeKey, arabicSize);
      await prefs.setString(_fontKey, fontChoice);
    } catch (e) {
      debugPrint('Adhkar settings error: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, favorites.toList());
    } catch (e) {
      debugPrint('Adhkar favorites error: $e');
    }
  }

  void _toggleFavorite(Dhikr item) {
    setState(() {
      if (!favorites.add(item.id)) {
        favorites.remove(item.id);
      }
    });

    _saveFavorites();
  }

  // --------------------------------------------------
  // PROGRESS
  // --------------------------------------------------

  String _itemKey(_TabInfo tab, Dhikr item) => '${tab.key}:${item.id}';

  int _current(_TabInfo tab, Dhikr item) => counts[_itemKey(tab, item)] ?? 0;

  bool _isDone(_TabInfo tab, Dhikr item) =>
      _current(tab, item) >= item.count;

  int _completedItems(_TabInfo tab) =>
      _itemsFor(tab).where((item) => _isDone(tab, item)).length;

  bool _isTabComplete(_TabInfo tab) {
    final items = _itemsFor(tab);
    return items.isNotEmpty && _completedItems(tab) == items.length;
  }

  void _tapCounter(_TabInfo tab, Dhikr item) {
    final key = _itemKey(tab, item);
    final current = counts[key] ?? 0;

    if (current >= item.count) return;

    setState(() {
      counts[key] = current + 1;
    });

    if (current + 1 >= item.count) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    _saveProgress();

    if (tab.key != 'favorites' &&
        _isTabComplete(tab) &&
        !_notified.contains(tab.key)) {
      _notified.add(tab.key);

      final kind = tab.habitKind;

      if (kind != null) {
        widget.onCompleted?.call(kind);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocale.tr('${tab.label} adhkar completed. May Allah accept it.'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _resetItem(_TabInfo tab, Dhikr item) {
    setState(() {
      counts.remove(_itemKey(tab, item));
      _notified.remove(tab.key);
    });

    _saveProgress();
  }

  void _snack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _copy(Dhikr item) async {
    final parts = <String>[
      item.shownTitle,
      if (item.arabic.isNotEmpty) item.arabic,
      if (item.shownTransliteration.isNotEmpty) item.shownTransliteration,
      item.shownMeaning,
      '${AppLocale.tr('Source')}: ${item.shownSource}',
    ];

    await Clipboard.setData(ClipboardData(text: parts.join('\n\n')));

    _snack(AppLocale.tr('Copied'));
  }

  void _changeSize(double delta) {
    setState(() {
      arabicSize = (arabicSize + delta).clamp(18.0, 40.0).toDouble();
    });

    _saveSettings();
  }

  // --------------------------------------------------
  // AUDIO
  // --------------------------------------------------

  AudioPlayer _getPlayer() {
    var player = _player;

    if (player == null) {
      player = AudioPlayer();

      player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _playingKey = null;
          });
        }
      });

      _player = player;
    }

    return player;
  }

  Future<void> _toggleAudio(_TabInfo tab, Dhikr item) async {
    final path = item.audio;

    if (path == null) {
      _snack(AppLocale.tr('Audio is not available for this dua yet.'));
      return;
    }

    final key = _itemKey(tab, item);

    try {
      final player = _getPlayer();

      if (_playingKey == key) {
        await player.stop();

        if (!mounted) return;

        setState(() {
          _playingKey = null;
        });

        return;
      }

      await player.stop();
      await player.play(AssetSource(path));

      if (!mounted) return;

      setState(() {
        _playingKey = key;
      });
    } catch (e) {
      debugPrint('Adhkar audio error: $e');

      if (!mounted) return;

      setState(() {
        _playingKey = null;
      });

      _snack(AppLocale.tr('Could not play the audio.'));
    }
  }

  // --------------------------------------------------
  // UI PARTS
  // --------------------------------------------------

  BoxDecoration _luxury(List<Color> colors, {double radius = 20}) {
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

  // ---------------- Summary card ----------------

  Widget _summaryCard(_TabInfo tab) {
    final done = _completedItems(tab);
    final total = _itemsFor(tab).length;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _luxury(tab.gradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gold.withValues(alpha: 0.4)),
                ),
                child: Icon(tab.icon, color: gold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocale.pick(tab.subtitleEn, tab.subtitleBn),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocale.tr('Daily Progress'),
                      style: const TextStyle(
                        color: goldLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                AppLocale.digits('$done / $total'),
                style: const TextStyle(
                  color: gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(gold),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Dhikr card ----------------

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          color: gold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _smallAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = goldLight,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterButton(_TabInfo tab, Dhikr item, int current, bool done) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: done ? null : () => _tapCounter(tab, item),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: done
                ? null
                : const LinearGradient(
                    colors: [
                      Color(0xFFE2B857),
                      Color(0xFFC9973A),
                    ],
                  ),
            color: done ? Colors.white.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                done ? Icons.check_rounded : Icons.touch_app_rounded,
                size: 18,
                color: done ? gold : deep,
              ),
              const SizedBox(width: 7),
              Text(
                AppLocale.digits('$current / ${item.count}'),
                style: TextStyle(
                  color: done ? gold : deep,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(_TabInfo tab, Dhikr item) {
    final key = _itemKey(tab, item);
    final current = _current(tab, item);
    final done = current >= item.count;
    final isOpen = _expanded.contains(key);
    final isFavorite = favorites.contains(item.id);
    final isPlaying = _playingKey == key;

    final transliteration = item.shownTransliteration;
    final note = item.shownNote;
    final hasArabic = item.arabic.trim().isNotEmpty;
    final hasTranslit = transliteration.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: _luxury(
        done ? _mutedGradient : tab.gradient,
        radius: 18,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.shownTitle,
                    style: TextStyle(
                      color: done ? Colors.white60 : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ),
                if (item.count > 1)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gold.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      AppLocale.digits('×${item.count}'),
                      style: const TextStyle(
                        color: gold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (done)
                  const Padding(
                    padding: EdgeInsets.only(left: 8, top: 2),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: gold,
                      size: 22,
                    ),
                  ),
              ],
            ),

            // Arabic text
            if (hasArabic) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: gold.withValues(alpha: 0.25)),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    item.arabic,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: done ? Colors.white70 : Colors.white,
                      fontFamily: _fontFamily,
                      fontSize: arabicSize,
                      height: fontChoice == 'indopak' ? 2.3 : 2.0,
                    ),
                  ),
                ),
              ),
            ],

            // Pronunciation, meaning and reference (open and close)
            if (isOpen) ...[
              if (hasTranslit) ...[
                const SizedBox(height: 14),
                _sectionLabel(AppLocale.tr('Pronunciation')),
                Text(
                  transliteration,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _sectionLabel(
                AppLocale.tr(hasArabic ? 'Meaning' : 'Instruction'),
              ),
              Text(
                item.shownMeaning,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${AppLocale.tr('Source')}: ${item.shownSource}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],

            // Note
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gold.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: gold,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note,
                        style: const TextStyle(
                          color: goldLight,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            Divider(
              height: 1,
              color: gold.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 8),

            // Bottom row: actions and counter
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 2,
                    children: [
                      _smallAction(
                        icon: isOpen
                            ? Icons.unfold_less_rounded
                            : Icons.unfold_more_rounded,
                        label: AppLocale.tr(
                          isOpen ? 'Hide details' : 'Show details',
                        ),
                        onTap: () {
                          setState(() {
                            if (isOpen) {
                              _expanded.remove(key);
                            } else {
                              _expanded.add(key);
                            }
                          });
                        },
                      ),
                      _smallAction(
                        icon: isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        label: AppLocale.tr('Favorite'),
                        color: isFavorite ? gold : goldLight,
                        onTap: () => _toggleFavorite(item),
                      ),
                      _smallAction(
                        icon: Icons.copy_rounded,
                        label: AppLocale.tr('Copy'),
                        onTap: () => _copy(item),
                      ),
                      if (item.audio != null)
                        _smallAction(
                          icon: isPlaying
                              ? Icons.stop_circle_outlined
                              : Icons.play_circle_outline_rounded,
                          label: AppLocale.tr(isPlaying ? 'Stop' : 'Play'),
                          color: gold,
                          onTap: () => _toggleAudio(tab, item),
                        ),
                      if (current > 0)
                        _smallAction(
                          icon: Icons.refresh_rounded,
                          label: AppLocale.tr('Reset'),
                          onTap: () => _resetItem(tab, item),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _counterButton(tab, item, current, done),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: _luxury(_tabs.last.gradient),
      child: const Column(
        children: [
          Icon(Icons.star_border_rounded, size: 46, color: gold),
          SizedBox(height: 12),
          Tr(
            'No favorites yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Tr(
            'Tap the star on any dua to save it here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: goldLight, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---------------- Tab body ----------------

  Widget _buildTabBody(_TabInfo tab) {
    final items = _itemsFor(tab);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      children: [
        _summaryCard(tab),
        const SizedBox(height: 16),
        if (items.isEmpty)
          _buildEmptyFavorites()
        else
          ...items.map((item) => _buildCard(tab, item)),
        const SizedBox(height: 4),
        Center(
          child: Text(
            AppLocale.tr('Please verify the text with a trusted book.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.muted,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fontMenu() {
    return PopupMenuButton<String>(
      tooltip: AppLocale.tr('Arabic font'),
      icon: const Icon(Icons.font_download_outlined),
      initialValue: fontChoice,
      onSelected: (value) {
        setState(() => fontChoice = value);
        _saveSettings();
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: 'amiri',
          checked: fontChoice == 'amiri',
          child: const Text('Amiri'),
        ),
        CheckedPopupMenuItem(
          value: 'scheherazade',
          checked: fontChoice == 'scheherazade',
          child: const Text('Scheherazade New'),
        ),
        CheckedPopupMenuItem(
          value: 'indopak',
          checked: fontChoice == 'indopak',
          child: const Text('IndoPak'),
        ),
        CheckedPopupMenuItem(
          value: 'default',
          checked: fontChoice == 'default',
          child: Text(AppLocale.tr('Default font')),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // MAIN UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.background,
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
            'Adhkar & Dua',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            _fontMenu(),
            IconButton(
              tooltip: AppLocale.tr('Smaller text'),
              icon: const Icon(Icons.text_decrease_rounded),
              onPressed: arabicSize <= 18 ? null : () => _changeSize(-2),
            ),
            IconButton(
              tooltip: AppLocale.tr('Larger text'),
              icon: const Icon(Icons.text_increase_rounded),
              onPressed: arabicSize >= 40 ? null : () => _changeSize(2),
            ),
            const SizedBox(width: 4),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: gold,
            labelColor: palette.accent,
            unselectedLabelColor: palette.muted,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: [
              for (final tab in _tabs)
                Tab(
                  icon: Icon(tab.icon, size: 20),
                  text: AppLocale.tr(tab.label),
                ),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  for (final tab in _tabs) _buildTabBody(tab),
                ],
              ),
      ),
    );
  }
}
