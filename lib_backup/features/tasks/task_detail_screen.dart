import '../../app_locale.dart';
import 'package:flutter/material.dart';

import '../../models/task_model.dart';
import '../../notification_service.dart';
import '../../theme_controller.dart';
import 'task_repository.dart';
import 'add_edit_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() =>
      _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  // ---------------- EMERALD LUXURY THEME ----------------
  static const Color gold = Color(0xFFE2B857);
  static const Color goldLight = Color(0xFFF6E7B4);

  static const List<Color> _emeraldGradient = [
    Color(0xFF06241E),
    Color(0xFF0C4A3C),
    Color(0xFF14876B),
  ];

  AppPalette get palette => AppPalette.of(context);

  Color get accent => palette.accent;

  BoxDecoration _luxury({double radius = 18}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _emeraldGradient,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: gold.withValues(alpha: 0.55),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: _emeraldGradient.last.withValues(alpha: 0.30),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  late TaskModel task;
  bool isLoading = true;

  DateTime get today => DateUtils.dateOnly(DateTime.now());

  DateTime get occurrenceDate {
    return task.taskType == TaskType.oneTime
        ? task.startDate
        : today;
  }

  String get currentDateKey => task.dateKey(occurrenceDate);

  bool get isCompleted => task.completedDates.contains(currentDateKey);

  bool get isSkipped => task.skippedDates.contains(currentDateKey);

  bool get isInProgress => task.inProgressDates.contains(currentDateKey);

  @override
  void initState() {
    super.initState();
    task = widget.task;
    _loadTask();
  }

  // --------------------------------------------------
  // LOAD TASK
  // --------------------------------------------------

  Future<void> _loadTask() async {
    try {
      final latestTask =
          await TaskRepository.instance.getTaskById(widget.task.id);

      if (!mounted) return;

      setState(() {
        if (latestTask != null) {
          task = latestTask;
        }

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.pick('Could not load task: $e', 'টাস্ক লোড করা যায়নি: $e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --------------------------------------------------
  // UPDATE STATUS
  // --------------------------------------------------

  Future<void> _updateStatus({
    bool? completed,
    bool? skipped,
    bool? inProgress,
  }) async {
    final key = currentDateKey;

    final completedDates = List<String>.from(task.completedDates);
    final skippedDates = List<String>.from(task.skippedDates);
    final inProgressDates = List<String>.from(task.inProgressDates);

    completedDates.remove(key);
    skippedDates.remove(key);
    inProgressDates.remove(key);

    if (completed == true) {
      completedDates.add(key);
    } else if (skipped == true) {
      skippedDates.add(key);
    } else if (inProgress == true) {
      inProgressDates.add(key);
    }

    final updatedTask = task.copyWith(
      completedDates: completedDates,
      skippedDates: skippedDates,
      inProgressDates: inProgressDates,
    );

    try {
      await TaskRepository.instance.updateTask(updatedTask);

      if (!mounted) return;

      setState(() {
        task = updatedTask;
      });

      String message = AppLocale.tr('Task status updated');

      if (completed == true) {
        message = AppLocale.tr('Task completed successfully!');
      } else if (skipped == true) {
        message = AppLocale.tr('Task skipped');
      } else if (inProgress == true) {
        message = AppLocale.tr('Task marked as in progress');
      } else {
        message = AppLocale.tr('Task status reset');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.pick('Could not update task: $e', 'টাস্ক আপডেট করা যায়নি: $e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --------------------------------------------------
  // EDIT TASK
  // --------------------------------------------------

  Future<void> _editTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTaskScreen(task: task),
      ),
    );

    if (!mounted) return;

    await _loadTask();
  }

  // --------------------------------------------------
  // DELETE TASK
  // --------------------------------------------------

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Tr('Delete Task?'),
          content: Text(
            AppLocale.pick(
              'Are you sure you want to delete "${task.title}"? '
                  'This action cannot be undone.',
              '"${task.title}" মুছে ফেলতে আপনি কি নিশ্চিত? '
                  'এই কাজ আর ফেরানো যাবে না।',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Tr('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Tr('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // First delete the task from local storage.
      await TaskRepository.instance.deleteTask(task.id);

      // Then cancel only this task's notifications.
      try {
        await NotificationService.instance.cancelTaskReminder(
          task.reminderId,
        );
      } catch (notificationError) {
        debugPrint(
          'Could not cancel task reminder: $notificationError',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Tr('Task deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.pick('Could not delete task: $e', 'টাস্ক মুছে ফেলা যায়নি: $e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

  String _formatDate(DateTime date) {
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

    return '${date.day} ${AppLocale.tr(months[date.month - 1])} ${date.year}';
  }

  String _formatTime() {
    if (task.scheduledHour == null ||
        task.scheduledMinute == null) {
      return AppLocale.tr('Not scheduled');
    }

    return TimeOfDay(
      hour: task.scheduledHour!,
      minute: task.scheduledMinute!,
    ).format(context);
  }

  String _priorityLabel() {
    switch (task.priority) {
      case TaskPriority.high:
        return AppLocale.tr('High');
      case TaskPriority.medium:
        return AppLocale.tr('Medium');
      case TaskPriority.low:
        return AppLocale.tr('Low');
    }
  }

  Color _priorityColor() {
    switch (task.priority) {
      case TaskPriority.high:
        return const Color(0xFFE45D67);
      case TaskPriority.medium:
        return const Color(0xFFE0A13B);
      case TaskPriority.low:
        return const Color(0xFF159B83);
    }
  }

  String _statusLabel() {
    if (isCompleted) return AppLocale.tr('Completed');
    if (isSkipped) return AppLocale.tr('Skipped');
    if (isInProgress) return AppLocale.tr('In Progress');

    final endDate = task.dueDate ?? task.startDate;

    if (DateUtils.dateOnly(endDate).isBefore(today)) {
      return AppLocale.tr('Overdue');
    }

    return AppLocale.tr('Pending');
  }

  // Bright shades so the status stays readable on the dark header card.
  Color _statusColor() {
    if (isCompleted) return const Color(0xFF5BD7A8);
    if (isSkipped) return const Color(0xFF9DB4C0);
    if (isInProgress) return const Color(0xFF7FB2FF);

    final endDate = task.dueDate ?? task.startDate;

    if (DateUtils.dateOnly(endDate).isBefore(today)) {
      return const Color(0xFFFF7A8A);
    }

    return const Color(0xFFF0B25C);
  }

  IconData _statusIcon() {
    if (isCompleted) return Icons.check_circle_rounded;
    if (isSkipped) return Icons.skip_next_rounded;
    if (isInProgress) return Icons.pending_actions_rounded;

    if (_statusLabel() == 'Overdue') {
      return Icons.warning_amber_rounded;
    }

    return Icons.radio_button_unchecked_rounded;
  }

  String _repeatDaysLabel() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    if (task.repeatDays.isEmpty) {
      return AppLocale.tr('Every day');
    }

    return task.repeatDays
        .where((day) => day >= 1 && day <= 7)
        .map((day) => AppLocale.tr(days[day - 1]))
        .join(', ');
  }

  // --------------------------------------------------
  // UI COMPONENTS
  // --------------------------------------------------

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? color,
  }) {
    final tileColor = color ?? accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            height: 39,
            width: 39,
            decoration: BoxDecoration(
              color: tileColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: tileColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    final color = _statusColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _statusIcon(),
            color: color,
            size: 24,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  task.taskType == TaskType.recurring
                      ? AppLocale.pick('Status for ${_formatDate(occurrenceDate)}', '${_formatDate(occurrenceDate)} এর অবস্থা')
                      : AppLocale.tr('Current task status'),
                  style: const TextStyle(
                    color: Colors.white70,
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

  Widget _actionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    return SizedBox(
      height: 48,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(title),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                backgroundColor: palette.surface,
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(title),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }

  // --------------------------------------------------
  // MAIN UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    AppLocale.watch(context);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Tr('Task Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
            'Task Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: AppLocale.tr('Edit Task'),
              onPressed: _editTask,
              icon: const Icon(Icons.edit_outlined),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteTask();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      SizedBox(width: 9),
                      Tr(
                        'Delete Task',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            12,
            18,
            30,
          ),
          children: [
            // TASK HEADER

            Container(
              padding: const EdgeInsets.all(19),
              decoration: _luxury(radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _priorityColor()
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _priorityColor()
                                .withValues(alpha: 0.55),
                          ),
                        ),
                        child: Text(
                          AppLocale.pick('${_priorityLabel()} Priority', '${_priorityLabel()} অগ্রাধিকার'),
                          style: TextStyle(
                            color: Color.lerp(
                              _priorityColor(),
                              Colors.white,
                              0.3,
                            ),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        task.taskType == TaskType.recurring
                            ? Icons.repeat_rounded
                            : Icons.looks_one_rounded,
                        color: gold,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        task.taskType == TaskType.recurring
                            ? AppLocale.tr('Recurring')
                            : AppLocale.tr('One-time'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: goldLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 11),
                    Text(
                      task.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.6,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _statusCard(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // TASK INFORMATION

            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: gold.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(AppLocale.tr('Task Information')),

                  _infoTile(
                    icon: Icons.category_outlined,
                    title: AppLocale.tr('Category'),
                    value: AppLocale.tr(task.category),
                  ),

                  _infoTile(
                    icon: Icons.flag_outlined,
                    title: AppLocale.tr('Priority'),
                    value: _priorityLabel(),
                    color: _priorityColor(),
                  ),

                  _infoTile(
                    icon: Icons.calendar_today_outlined,
                    title: AppLocale.tr('Start Date'),
                    value: _formatDate(task.startDate),
                  ),

                  _infoTile(
                    icon: Icons.event_available_outlined,
                    title: AppLocale.tr('Due Date'),
                    value: task.dueDate == null
                        ? AppLocale.tr('No due date')
                        : _formatDate(task.dueDate!),
                  ),

                  _infoTile(
                    icon: Icons.access_time_rounded,
                    title: AppLocale.tr('Scheduled Time'),
                    value: _formatTime(),
                  ),

                  _infoTile(
                    icon: Icons.timelapse_rounded,
                    title: AppLocale.tr('Estimated Duration'),
                    value: AppLocale.digits(AppLocale.pick('${task.estimatedMinutes} minutes', '${task.estimatedMinutes} মিনিট')),
                  ),

                  if (task.taskType == TaskType.recurring)
                    _infoTile(
                      icon: Icons.repeat_rounded,
                      title: AppLocale.tr('Repeat Days'),
                      value: _repeatDaysLabel(),
                    ),

                  _infoTile(
                    icon: Icons.notifications_active_outlined,
                    title: AppLocale.tr('Reminder'),
                    value: task.reminderEnabled
                        ? AppLocale.tr('Enabled')
                        : AppLocale.tr('Disabled'),
                    color: task.reminderEnabled
                        ? const Color(0xFF159B83)
                        : Colors.grey,
                  ),

                  _infoTile(
                    icon: Icons.add_circle_outline,
                    title: AppLocale.tr('Created On'),
                    value: _formatDate(task.createdAt),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ACTIONS

            _sectionTitle(AppLocale.tr('Update Task Status')),

            if (isCompleted)
              _actionButton(
                title: AppLocale.tr('Undo Completion'),
                icon: Icons.undo_rounded,
                color: accent,
                outlined: true,
                onPressed: () {
                  _updateStatus();
                },
              )
            else ...[
              _actionButton(
                title: AppLocale.tr('Mark as Completed'),
                icon: Icons.check_circle_outline,
                color: const Color(0xFF159B83),
                onPressed: () {
                  _updateStatus(completed: true);
                },
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      title: AppLocale.tr('In Progress'),
                      icon: Icons.pending_actions_rounded,
                      color: accent,
                      outlined: true,
                      onPressed: () {
                        _updateStatus(inProgress: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      title: AppLocale.tr('Skip Task'),
                      icon: Icons.skip_next_rounded,
                      color: Colors.blueGrey,
                      outlined: true,
                      onPressed: () {
                        _updateStatus(skipped: true);
                      },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 22),

            _actionButton(
              title: AppLocale.tr('Edit Task'),
              icon: Icons.edit_rounded,
              color: accent,
              outlined: true,
              onPressed: _editTask,
            ),

            const SizedBox(height: 12),

            _actionButton(
              title: AppLocale.tr('Delete Task'),
              icon: Icons.delete_outline_rounded,
              color: Colors.red,
              outlined: true,
              onPressed: _deleteTask,
            ),
          ],
        ),
      ),
    );
  }
}