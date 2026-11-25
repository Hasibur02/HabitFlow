import 'app_locale.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/tasks/task_repository.dart';
import 'notification_service.dart';
import 'reminder_settings_screen.dart';
import 'theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  final List<Map<String, dynamic>> habits;

  const ProfileScreen({
    super.key,
    required this.habits,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ---------------- EMERALD LUXURY THEME ----------------
  static const Color primary = Color(0xFF0F6B57);
  static const Color ink = Color(0xFF10332B);
  static const Color gold = Color(0xFFE2B857);
  static const Color goldLight = Color(0xFFF6E7B4);

  static const List<Color> _emerald = [
    Color(0xFF06241E),
    Color(0xFF0C4A3C),
    Color(0xFF14876B),
  ];

  static const List<Color> _blue = [
    Color(0xFF0F1B4D),
    Color(0xFF1F3A9E),
    Color(0xFF3F5BD9),
  ];

  static const List<Color> _bronze = [
    Color(0xFF3A2A08),
    Color(0xFF7A5514),
    Color(0xFFC08A2B),
  ];

  static const List<Color> _wine = [
    Color(0xFF2E0B1A),
    Color(0xFF7A1F3D),
    Color(0xFFD6455F),
  ];

  BoxDecoration _luxury({
    List<Color> colors = _emerald,
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

  User? user = FirebaseAuth.instance.currentUser;
  int taskCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTaskCount();
  }

  Future<void> _loadTaskCount() async {
    try {
      final tasks = await TaskRepository.instance.getTasks();
      if (!mounted) return;
      setState(() => taskCount = tasks.length);
    } catch (e) {
      debugPrint('Profile task count error: $e');
    }
  }

  // --------------------------------------------------
  // DATA HELPERS
  // --------------------------------------------------

  String get displayName {
    final name = user?.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;

    final email = user?.email ?? '';
    if (email.contains('@')) return email.split('@').first;

    return 'HabitFlow User';
  }

  String get initial {
    final name = displayName.trim();
    return name.isEmpty ? 'H' : name[0].toUpperCase();
  }

  String get providerLabel {
    final providers = user?.providerData.map((e) => e.providerId) ?? [];

    if (providers.contains('google.com')) return 'Google';
    if (providers.contains('password')) return AppLocale.tr('Email & Password');

    return AppLocale.tr('Unknown');
  }

  bool get usesPassword {
    final providers = user?.providerData.map((e) => e.providerId) ?? [];
    return providers.contains('password');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppLocale.tr('Unknown');

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${AppLocale.tr(months[date.month - 1])} ${date.year}';
  }

  String _key(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Set<String> get _activeDays {
    final days = <String>{};

    for (final habit in widget.habits) {
      days.addAll(List<String>.from(habit['completedDates'] ?? []));
    }

    return days;
  }

  int get totalCompletions {
    return widget.habits.fold<int>(
      0,
      (sum, habit) =>
          sum + List<String>.from(habit['completedDates'] ?? []).length,
    );
  }

  int get currentStreak {
    final days = _activeDays;
    var date = DateUtils.dateOnly(DateTime.now());

    // If nothing is done today yet, the streak can still continue from yesterday.
    if (!days.contains(_key(date))) {
      date = date.subtract(const Duration(days: 1));
    }

    var streak = 0;

    while (days.contains(_key(date))) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int get bestStreak {
    final dates = _activeDays
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map(DateUtils.dateOnly)
        .toList()
      ..sort();

    if (dates.isEmpty) return 0;

    var best = 1;
    var run = 1;

    for (var i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;

      if (diff == 1) {
        run++;
        if (run > best) best = run;
      } else if (diff > 1) {
        run = 1;
      }
    }

    return best;
  }

  // --------------------------------------------------
  // ACTIONS
  // --------------------------------------------------

  void _snack(String message, {Color? color}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _editName() async {
    final controller = TextEditingController(
      text: user?.displayName ?? '',
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Tr(
            'Edit name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: AppLocale.tr('Your name'),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Tr('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Tr('Save'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty || !mounted) return;

    try {
      await user?.updateDisplayName(newName);
      await user?.reload();

      if (!mounted) return;

      setState(() => user = FirebaseAuth.instance.currentUser);
      _snack(AppLocale.tr('Name updated'), color: Colors.green);
    } catch (e) {
      _snack(AppLocale.pick('Could not update name: $e', 'নাম আপডেট করা যায়নি: $e'), color: Colors.red);
    }
  }

  Future<void> _resetPassword() async {
    final email = user?.email;

    if (email == null || email.isEmpty) {
      _snack(AppLocale.pick('No email found for this account', 'এই অ্যাকাউন্টে কোনো ইমেইল পাওয়া যায়নি'));
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _snack(AppLocale.pick('Password reset email sent to $email', '$email ঠিকানায় পাসওয়ার্ড রিসেট ইমেইল পাঠানো হয়েছে'), color: Colors.green);
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? AppLocale.pick('Reset failed', 'রিসেট ব্যর্থ হয়েছে'), color: Colors.red);
    } catch (e) {
      _snack(AppLocale.pick('Something went wrong: $e', 'কিছু ভুল হয়েছে: $e'), color: Colors.red);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Tr('Logout?'),
          content: const Tr('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Tr('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Tr('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // Close this screen first so the login screen is visible after sign out.
    Navigator.of(context).popUntil((route) => route.isFirst);

    await FirebaseAuth.instance.signOut();
  }

  void _openReminderSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReminderSettingsScreen(habits: widget.habits),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _clearLocalData() async {
    // Cancel habit reminders.
    for (final habit in widget.habits) {
      if (habit['reminderEnabled'] == true) {
        try {
          await NotificationService.instance.cancelReminder(
            habit['reminderId'],
          );
        } catch (e) {
          debugPrint('Could not cancel habit reminder: $e');
        }
      }
    }

    // Delete tasks and their reminders.
    try {
      final tasks = await TaskRepository.instance.getTasks();

      for (final task in tasks) {
        try {
          await NotificationService.instance.cancelTaskReminder(
            task.reminderId,
          );
        } catch (e) {
          debugPrint('Could not cancel task reminder: $e');
        }

        await TaskRepository.instance.deleteTask(task.id);
      }
    } catch (e) {
      debugPrint('Could not clear tasks: $e');
    }

    // Remove saved habits and prayer data.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('habits');
    await prefs.remove('prayer_tracker_v1');
  }

  Future<void> _deleteAccount() async {
    final currentUser = user;

    if (currentUser == null) return;

    final confirmController = TextEditingController();
    final passwordController = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? confirmError;
        String? passwordError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Tr(
                'Delete account?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocale.pick(
                        'This permanently deletes your account and your '
                            'habit, prayer and task data. This cannot be undone.',
                        'এটি আপনার অ্যাকাউন্ট এবং অভ্যাস, নামাজ ও টাস্কের '
                            'সব তথ্য চিরতরে মুছে ফেলবে। এটি আর ফেরানো যাবে না।',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmController,
                      decoration: InputDecoration(
                        labelText: AppLocale.tr('Type DELETE to confirm'),
                        border: const OutlineInputBorder(),
                        errorText: confirmError,
                      ),
                    ),
                    if (usesPassword) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: AppLocale.tr('Password'),
                          border: const OutlineInputBorder(),
                          errorText: passwordError,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Tr('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () {
                    final typedOk =
                        confirmController.text.trim() == 'DELETE';
                    final passwordOk = !usesPassword ||
                        passwordController.text.isNotEmpty;

                    if (!typedOk || !passwordOk) {
                      setDialogState(() {
                        confirmError =
                            typedOk ? null : AppLocale.pick('Please type DELETE', 'অনুগ্রহ করে DELETE লিখুন');
                        passwordError =
                            passwordOk ? null : AppLocale.pick('Enter your password', 'আপনার পাসওয়ার্ড লিখুন');
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, passwordController.text);
                  },
                  child: const Tr('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    if (password == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Email users confirm their identity again before deletion.
      if (usesPassword && currentUser.email != null) {
        await currentUser.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: currentUser.email!,
            password: password,
          ),
        );
      }

      await currentUser.delete();
    } on FirebaseAuthException catch (e) {
      String message;

      if (e.code == 'requires-recent-login') {
        message = AppLocale.pick(
          'For security, please log out, log in again, '
              'and then delete your account.',
          'নিরাপত্তার জন্য আগে লগআউট করে আবার লগইন করুন, '
              'তারপর অ্যাকাউন্ট মুছুন।',
        );
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = AppLocale.pick(
          'Wrong password. Account was not deleted.',
          'পাসওয়ার্ড ভুল। অ্যাকাউন্ট মোছা হয়নি।',
        );
      } else {
        message = e.message ??
            AppLocale.pick(
              'Could not delete account.',
              'অ্যাকাউন্ট মুছে ফেলা যায়নি।',
            );
      }

      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocale.pick('Could not delete account: $e', 'অ্যাকাউন্ট মুছে ফেলা যায়নি: $e')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // The account is gone, so remove the data stored on this device.
    await _clearLocalData();

    navigator.popUntil((route) => route.isFirst);

    messenger.showSnackBar(
      const SnackBar(content: Tr('Your account has been deleted.')),
    );
  }

  Widget _buildAppearanceSection() {
    final palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Tr(
          'Appearance',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.instance.mode,
          builder: (context, mode, _) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: gold.withValues(alpha: 0.5)),
              ),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded, size: 18),
                    label: Tr('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded, size: 18),
                    label: Tr('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded, size: 18),
                    label: Tr('Dark'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (selection) {
                  ThemeController.instance.setMode(selection.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? const Color(0xFF0C4A3C)
                        : Colors.transparent,
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? gold
                        : palette.ink,
                  ),
                  side: WidgetStateProperty.all(
                    BorderSide(color: gold.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 22),
        const Text(
          'Language',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<String>(
          valueListenable: AppLocale.instance.language,
          builder: (context, language, _) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: gold.withValues(alpha: 0.5)),
              ),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'en',
                    label: Text('English'),
                  ),
                  ButtonSegment(
                    value: 'bn',
                    label: Text('বাংলা'),
                  ),
                ],
                selected: {language},
                onSelectionChanged: (selection) {
                  AppLocale.instance.setLanguage(selection.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? const Color(0xFF0C4A3C)
                        : Colors.transparent,
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? gold
                        : palette.ink,
                  ),
                  side: WidgetStateProperty.all(
                    BorderSide(color: gold.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --------------------------------------------------
  // UI PARTS
  // --------------------------------------------------

  Widget _buildHeader() {
    final photoUrl = user?.photoURL;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: _luxury(radius: 26),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: gold, width: 2),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFF0C4A3C),
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: gold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? AppLocale.pick('No email', 'ইমেইল নেই'),
            style: const TextStyle(
              color: goldLight,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gold.withValues(alpha: 0.5)),
            ),
            child: Text(
              AppLocale.pick('Signed in with $providerLabel', '$providerLabel দিয়ে সাইন ইন'),
              style: const TextStyle(
                color: gold,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String value,
    required String label,
    required List<Color> gradient,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: _luxury(colors: gradient, radius: 18),
        child: Column(
          children: [
            Icon(icon, color: gold, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: goldLight,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPalette.of(context)
                  .accent
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppPalette.of(context).accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    final verified = user?.emailVerified == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.of(context).surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.email_outlined,
            label: AppLocale.tr('Email'),
            value: user?.email ?? AppLocale.tr('Not available'),
            trailing: Icon(
              verified ? Icons.verified_rounded : Icons.error_outline,
              color: verified ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          Divider(height: 1, color: gold.withValues(alpha: 0.3)),
          _infoRow(
            icon: Icons.login_rounded,
            label: AppLocale.tr('Sign-in method'),
            value: providerLabel,
          ),
          Divider(height: 1, color: gold.withValues(alpha: 0.3)),
          _infoRow(
            icon: Icons.calendar_month_rounded,
            label: AppLocale.tr('Member since'),
            value: _formatDate(user?.metadata.creationTime),
          ),
          Divider(height: 1, color: gold.withValues(alpha: 0.3)),
          _infoRow(
            icon: Icons.check_circle_outline_rounded,
            label: AppLocale.tr('Total habit completions'),
            value: '$totalCompletions',
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.of(context).ink,
          backgroundColor: AppPalette.of(context).surface,
          side: BorderSide(
            color: AppPalette.of(context).accent.withValues(alpha: 0.45),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, color: AppPalette.of(context).accent),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _wine),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withValues(alpha: 0.6)),
      ),
      child: ElevatedButton.icon(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Tr(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppPalette.of(context).background,
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
            'My Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            _buildHeader(),

            const SizedBox(height: 16),

            Row(
              children: [
                _statTile(
                  icon: Icons.repeat_rounded,
                  value: '${widget.habits.length}',
                  label: AppLocale.tr('Habits'),
                  gradient: _blue,
                ),
                const SizedBox(width: 10),
                _statTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '$currentStreak',
                  label: AppLocale.tr('Day streak'),
                  gradient: _bronze,
                ),
                const SizedBox(width: 10),
                _statTile(
                  icon: Icons.checklist_rounded,
                  value: '$taskCount',
                  label: AppLocale.tr('Tasks'),
                  gradient: _emerald,
                ),
              ],
            ),

            const SizedBox(height: 10),

            Center(
              child: Text(
                AppLocale.digits(AppLocale.pick('Best streak: $bestStreak ${bestStreak == 1 ? 'day' : 'days'}', 'সেরা ধারাবাহিকতা: $bestStreak দিন')),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 22),

            const Tr(
              'Account',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _buildAccountCard(),

            const SizedBox(height: 22),

            _buildAppearanceSection(),

            const SizedBox(height: 22),

            _actionButton(
              icon: Icons.edit_outlined,
              label: AppLocale.tr('Edit name'),
              onTap: _editName,
            ),

            const SizedBox(height: 10),

            _actionButton(
              icon: Icons.notifications_active_outlined,
              label: AppLocale.tr('Reminder settings'),
              onTap: _openReminderSettings,
            ),

            if (usesPassword) ...[
              const SizedBox(height: 10),
              _actionButton(
                icon: Icons.lock_reset_rounded,
                label: AppLocale.tr('Reset password'),
                onTap: _resetPassword,
              ),
            ],

            const SizedBox(height: 18),

            _logoutButton(),

            const SizedBox(height: 8),

            Center(
              child: TextButton.icon(
                onPressed: _deleteAccount,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
                icon: const Icon(Icons.delete_forever_rounded, size: 20),
                label: const Tr('Delete account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
