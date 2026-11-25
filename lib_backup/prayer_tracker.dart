import 'app_locale.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_controller.dart';

class PrayerTrackerScreen extends StatefulWidget {
  const PrayerTrackerScreen({super.key});

  @override
  State<PrayerTrackerScreen> createState() =>
      _PrayerTrackerScreenState();
}

class _PrayerTrackerScreenState extends State<PrayerTrackerScreen> {
  // ---------------- EMERALD LUXURY THEME ----------------
  static const Color primary = Color(0xFF9A6B1A);
  static const Color ink = Color(0xFF2E2208);
  static const Color gold = Color(0xFFE2B857);
  static const Color goldLight = Color(0xFFF6E7B4);

  static const List<Color> _emeraldGradient = [
    Color(0xFF3A2A08),
    Color(0xFF7A5514),
    Color(0xFFC08A2B),
  ];

  static const List<Color> _mutedGradient = [
    Color(0xFF2E2718),
    Color(0xFF453B22),
  ];

  static const List<Color> _bgGradient = [
    Color(0xFFFFF9EC),
    Color(0xFFFBEFD3),
    Color(0xFFFFF8E8),
  ];

  static const String storageKey = 'prayer_tracker_v1';

  BoxDecoration _luxuryDecoration({
    List<Color> colors = _emeraldGradient,
    double radius = 20,
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

  final List<Map<String, dynamic>> prayers = [
    {
      'name': 'Fajr',
      'arabic': 'الفجر',
      'time': 'Dawn',
      'icon': Icons.wb_twilight,
      'color': Color(0xFF6685D9),
      'light': Color(0xFFEAF0FF),
    },
    {
      'name': 'Dhuhr',
      'arabic': 'الظهر',
      'time': 'Midday',
      'icon': Icons.wb_sunny,
      'color': Color(0xFFE3A333),
      'light': Color(0xFFFFF4DD),
    },
    {
      'name': 'Asr',
      'arabic': 'العصر',
      'time': 'Afternoon',
      'icon': Icons.sunny,
      'color': Color(0xFF4D9B83),
      'light': Color(0xFFE5F5EF),
    },
    {
      'name': 'Maghrib',
      'arabic': 'المغرب',
      'time': 'Sunset',
      'icon': Icons.wb_twilight,
      'color': Color(0xFFD47A52),
      'light': Color(0xFFFFEDE5),
    },
    {
      'name': 'Isha',
      'arabic': 'العشاء',
      'time': 'Night',
      'icon': Icons.nights_stay,
      'color': Color(0xFF8068C9),
      'light': Color(0xFFF0EBFF),
    },
  ];

  Map<String, dynamic> dailyData = {};
  bool isLoading = true;

  String get today {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> get todayData {
    final value = dailyData[today];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  Map<String, dynamic> prayerData(String name) {
    final value = todayData[name];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {
      'prayed': false,
      'masjid': false,
      'adhkar': false,
      'ayat': false,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(storageKey);

    if (saved != null) {
      try {
        final decoded = jsonDecode(saved);
        if (decoded is Map) {
          dailyData = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint('Prayer data loading error: $e');
      }
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(dailyData));
  }

  Future<void> _togglePrayer(String name, bool value) async {
    final dateData = todayData;
    final data = prayerData(name);

    data['prayed'] = value;
    dateData[name] = data;

    setState(() {
      dailyData[today] = dateData;
    });

    await _saveData();
  }

  Future<void> _openPrayerDetails(String name) async {
    final initial = prayerData(name);

    bool masjid = initial['masjid'] == true;
    bool adhkar = initial['adhkar'] == true;
    bool ayat = initial['ayat'] == true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppPalette.of(context).dark
                      ? const [
                          Color(0xFF1B1710),
                          Color(0xFF14110B),
                        ]
                      : const [
                          Color(0xFFFFFFFF),
                          Color(0xFFFFF9EC),
                        ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                border: Border(
                  top: BorderSide(
                    color: gold.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      AppLocale.pick('$name Prayer Details', '${AppLocale.tr(name)} নামাজের বিস্তারিত'),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Tr(
                      'Track your additional acts of worship.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    _detailTile(
                      title: AppLocale.tr('Prayed in the Masjid'),
                      subtitle: AppLocale.tr('Performed Salah in congregation'),
                      icon: Icons.mosque_rounded,
                      value: masjid,
                      onChanged: (value) {
                        setSheetState(() => masjid = value);
                      },
                    ),
                    _detailTile(
                      title: AppLocale.tr('Recited Adhkar after Salah'),
                      subtitle: AppLocale.tr('Completed post-prayer remembrance'),
                      icon: Icons.auto_awesome,
                      value: adhkar,
                      onChanged: (value) {
                        setSheetState(() => adhkar = value);
                      },
                    ),
                    _detailTile(
                      title: AppLocale.tr('Recited Ayatul Kursi'),
                      subtitle: AppLocale.tr('Recited Ayatul Kursi after Salah'),
                      icon: Icons.menu_book_rounded,
                      value: ayat,
                      onChanged: (value) {
                        setSheetState(() => ayat = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: _emeraldGradient,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: gold.withValues(alpha: 0.6),
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: gold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final dateData = todayData;
                          final data = prayerData(name);

                          data['masjid'] = masjid;
                          data['adhkar'] = adhkar;
                          data['ayat'] = ayat;

                          dateData[name] = data;

                          setState(() {
                            dailyData[today] = dateData;
                          });

                          await _saveData();

                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        child: const Tr(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final dark = AppPalette.of(context).dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: value
            ? (dark ? const Color(0xFF2A2312) : const Color(0xFFFFFBEF))
            : (dark ? const Color(0xFF1F1A10) : const Color(0xFFFBF3E0)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? gold.withValues(alpha: 0.6)
              : (dark ? const Color(0xFF3A3220) : const Color(0xFFF0DDB0)),
        ),
      ),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: primary,
        checkColor: Colors.white,
        secondary: CircleAvatar(
          backgroundColor: const Color(0xFFF6E7B4),
          child: Icon(icon, color: primary, size: 21),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        value: value,
        onChanged: (newValue) => onChanged(newValue ?? false),
      ),
    );
  }

  Widget _buildHeaderCard(int completedCount, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _luxuryDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Tr(
                "Today's Prayers",
                style: TextStyle(
                  color: goldLight,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '$completedCount/5',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: gold,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(gold),
            ),
          ),
          const SizedBox(height: 9),
          const Tr(
            'One prayer at a time. Keep going!',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(Map<String, dynamic> prayer) {
    final name = prayer['name'] as String;
    final data = prayerData(name);
    final isDone = data['prayed'] == true;

    final extraCount = [
      data['masjid'],
      data['adhkar'],
      data['ayat'],
    ].where((item) => item == true).length;

    final color = prayer['color'] as Color;
    final light = prayer['light'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: _luxuryDecoration(
        colors: isDone ? _mutedGradient : _emeraldGradient,
        radius: 17,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => _openPrayerDetails(name),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: gold.withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: light,
                    child: Icon(
                      prayer['icon'] as IconData,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tr(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDone ? Colors.white54 : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Tr(
                        prayer['time'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                      if (extraCount > 0) ...[
                        const SizedBox(height: 5),
                        Text(
                          AppLocale.digits(AppLocale.pick('$extraCount of 3 extra acts completed', '৩টির মধ্যে $extraCount অতিরিক্ত আমল সম্পন্ন')),
                          style: const TextStyle(
                            fontSize: 10,
                            color: goldLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  prayer['arabic'] as String,
                  style: const TextStyle(
                    fontSize: 17,
                    color: gold,
                  ),
                ),
                const SizedBox(width: 5),
                Checkbox(
                  value: isDone,
                  activeColor: gold,
                  checkColor: const Color(0xFF06241E),
                  side: BorderSide(
                    color: gold.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (value) {
                    _togglePrayer(name, value ?? false);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    final completedCount = prayers.where((prayer) {
      return prayerData(prayer['name'])['prayed'] == true;
    }).length;

    final progress = completedCount / prayers.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppPalette.of(context).dark
              ? const [
                  Color(0xFF110D06),
                  Color(0xFF1A1409),
                  Color(0xFF0C0A06),
                ]
              : _bgGradient,
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
            'Prayer Tracker',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeaderCard(completedCount, progress),
                  const SizedBox(height: 24),
                  const Tr(
                    'Five Daily Prayers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Tr(
                    'Tap a prayer to track your additional worship.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...prayers.map(_buildPrayerCard),
                  const SizedBox(height: 15),
                  Text(
                    AppLocale.pick(
                      'Tip: Tap a prayer card to record Masjid, Adhkar '
                          'and Ayatul Kursi.',
                      'টিপ: মসজিদ, যিকির ও আয়াতুল কুরসী লিখে রাখতে '
                          'কোনো ওয়াক্তের কার্ডে চাপ দিন।',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}