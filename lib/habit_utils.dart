// Helpers for habit schedule (specific weekdays), numeric targets and streaks.
// Habits are plain Map<String, dynamic> stored in SharedPreferences, so every
// new field is optional: old habits (no 'days' / 'target') behave exactly as
// before -> every day, simple tick.
//
// Extra keys used on a habit map:
//   'days'     : List<int>  weekdays, DateTime.monday(1) .. DateTime.sunday(7)
//   'target'   : int        1 = simple tick, >1 = counter habit
//   'unit'     : String     e.g. "L", "pages", "times"
//   'progress' : Map<String,int>  'yyyy-MM-dd' -> count (counter habits only)
//   'completedDates' stays the single source of truth for "done".

class HabitUtils {
  HabitUtils._();

  static String keyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? parseKey(String k) {
    final p = k.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  // ---------------- schedule ----------------

  static List<int> days(Map<String, dynamic> h) {
    final raw = h['days'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => (e as num).toInt()).toList();
    }
    return const [1, 2, 3, 4, 5, 6, 7];
  }

  static bool isEveryDay(Map<String, dynamic> h) => days(h).length == 7;

  static bool isScheduledOn(Map<String, dynamic> h, DateTime d) =>
      days(h).contains(d.weekday);

  static bool isScheduledToday(Map<String, dynamic> h) =>
      isScheduledOn(h, DateTime.now());

  // ---------------- target / progress ----------------

  static int target(Map<String, dynamic> h) {
    final t = h['target'];
    if (t is num && t.toInt() > 1) return t.toInt();
    return 1;
  }

  static bool isCounter(Map<String, dynamic> h) => target(h) > 1;

  static String unit(Map<String, dynamic> h) =>
      (h['unit'] ?? '').toString();

  static Map<String, dynamic> _progress(Map<String, dynamic> h) {
    final p = h['progress'];
    if (p is Map<String, dynamic>) return p;
    final m = <String, dynamic>{};
    if (p is Map) {
      p.forEach((k, v) => m[k.toString()] = v);
    }
    h['progress'] = m;
    return m;
  }

  static bool isDoneOn(Map<String, dynamic> h, String key) =>
      List<String>.from(h['completedDates'] ?? const []).contains(key);

  /// Count for a day. Simple habits: 0 or 1.
  static int countOn(Map<String, dynamic> h, String key) {
    if (!isCounter(h)) return isDoneOn(h, key) ? 1 : 0;
    final v = _progress(h)[key];
    final c = v is num ? v.toInt() : 0;
    // completed before target existed / marked from elsewhere
    if (c == 0 && isDoneOn(h, key)) return target(h);
    return c;
  }

  /// Set the count for a day and keep 'completedDates' in sync.
  static void setCount(Map<String, dynamic> h, String key, int value) {
    final t = target(h);
    final v = value.clamp(0, t).toInt();
    final dates = List<String>.from(h['completedDates'] ?? const []);

    if (isCounter(h)) {
      final p = _progress(h);
      if (v == 0) {
        p.remove(key);
      } else {
        p[key] = v;
      }
    }

    if (v >= t) {
      if (!dates.contains(key)) dates.add(key);
    } else {
      dates.remove(key);
    }
    h['completedDates'] = dates;
  }

  /// Tap on a habit: tick <-> untick, or +1 for counters (reset after full).
  static void tap(Map<String, dynamic> h, String key) {
    if (isCounter(h)) {
      final c = countOn(h, key);
      setCount(h, key, c >= target(h) ? 0 : c + 1);
    } else {
      setCount(h, key, isDoneOn(h, key) ? 0 : 1);
    }
  }

  // ---------------- streaks ----------------

  /// Current streak: consecutive *scheduled* days done, going back from today.
  /// Rest days are skipped (don't break it); today not yet done doesn't break it.
  static int streak(Map<String, dynamic> h) {
    final done = Set<String>.from(h['completedDates'] ?? const []);
    if (done.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var count = 0;
    var d = today;
    for (var i = 0; i < 3660; i++) {
      if (isScheduledOn(h, d)) {
        if (done.contains(keyOf(d))) {
          count++;
        } else if (d != today) {
          break;
        }
      }
      d = d.subtract(const Duration(days: 1));
      d = DateTime(d.year, d.month, d.day);
    }
    return count;
  }

  /// Best (longest) streak ever.
  static int bestStreak(Map<String, dynamic> h) {
    final done = Set<String>.from(h['completedDates'] ?? const []);
    if (done.isEmpty) return 0;
    DateTime? first;
    for (final k in done) {
      final d = parseKey(k);
      if (d != null && (first == null || d.isBefore(first))) first = d;
    }
    if (first == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var best = 0, run = 0;
    var d = first;
    while (!d.isAfter(today)) {
      if (isScheduledOn(h, d)) {
        if (done.contains(keyOf(d))) {
          run++;
          if (run > best) best = run;
        } else if (d != today) {
          run = 0;
        }
      }
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return best;
  }
}
