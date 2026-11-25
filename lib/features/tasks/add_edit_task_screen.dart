import '../../app_locale.dart';
import 'package:flutter/material.dart';

import '../../models/task_model.dart';
import '../../notification_service.dart';
import '../../theme_controller.dart';
import 'task_repository.dart';

class AddEditTaskScreen extends StatefulWidget {
  final TaskModel? task;

  const AddEditTaskScreen({
    super.key,
    this.task,
  });

  @override
  State<AddEditTaskScreen> createState() =>
      _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
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

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController descriptionController;

  final List<String> categories = [
    'Study',
    'Work',
    'Personal',
    'Health',
    'Spiritual',
    'Other',
  ];

  late String selectedCategory;
  late TaskType selectedTaskType;
  late TaskPriority selectedPriority;

  late DateTime startDate;
  DateTime? dueDate;

  TimeOfDay? scheduledTime;

  int estimatedMinutes = 30;

  List<int> repeatDays = [];

  bool reminderEnabled = false;
  bool isSaving = false;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    titleController = TextEditingController(
      text: task?.title ?? '',
    );

    descriptionController = TextEditingController(
      text: task?.description ?? '',
    );

    selectedCategory = task?.category ?? 'Study';
    selectedTaskType = task?.taskType ?? TaskType.oneTime;
    selectedPriority = task?.priority ?? TaskPriority.medium;

    startDate = task?.startDate ?? DateUtils.dateOnly(DateTime.now());

    dueDate = task?.dueDate;

    if (task?.scheduledHour != null &&
        task?.scheduledMinute != null) {
      scheduledTime = TimeOfDay(
        hour: task!.scheduledHour!,
        minute: task.scheduledMinute!,
      );
    }

    estimatedMinutes = task?.estimatedMinutes ?? 30;

    repeatDays = List<int>.from(task?.repeatDays ?? []);

    reminderEnabled = task?.reminderEnabled ?? false;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // DATE PICKERS
  // --------------------------------------------------

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: AppLocale.tr('Select Start Date'),
    );

    if (selected == null) return;

    setState(() {
      startDate = DateUtils.dateOnly(selected);

      if (dueDate != null &&
          dueDate!.isBefore(startDate)) {
        dueDate = startDate;
      }
    });
  }

  Future<void> _selectDueDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: dueDate ?? startDate,
      firstDate: startDate,
      lastDate: DateTime(2100),
      helpText: AppLocale.tr('Select Due Date'),
    );

    if (selected == null) return;

    setState(() {
      dueDate = DateUtils.dateOnly(selected);
    });
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: scheduledTime ?? TimeOfDay.now(),
      helpText: AppLocale.tr('Select Scheduled Time'),
    );

    if (selected == null) return;

    setState(() {
      scheduledTime = selected;
    });
  }

  // --------------------------------------------------
  // REPEAT DAYS
  // --------------------------------------------------

  Widget _buildRepeatDays() {
    const days = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return Wrap(
      spacing: 7,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final dayNumber = index + 1;
        final isSelected = repeatDays.contains(dayNumber);

        return FilterChip(
          label: Text(AppLocale.tr(days[index])),
          selected: isSelected,
          showCheckmark: false,
          backgroundColor: palette.surface,
          selectedColor: accent.withValues(alpha: 0.16),
          side: BorderSide(
            color: isSelected ? accent : palette.border,
          ),
          labelStyle: TextStyle(
            color: isSelected ? accent : palette.ink,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                repeatDays.add(dayNumber);
              } else {
                repeatDays.remove(dayNumber);
              }

              repeatDays.sort();
            });
          },
        );
      }),
    );
  }

  // --------------------------------------------------
  // FORM HELPERS
  // --------------------------------------------------

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: palette.muted,
            ),
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    String? label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      cursorColor: accent,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelStyle: TextStyle(color: accent),
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _inputBorder(palette.border),
        enabledBorder: _inputBorder(palette.border),
        focusedBorder: _inputBorder(accent, width: 1.6),
      ),
    );
  }

  Widget _dateTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: accent,
                size: 19,
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
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null)
              Icon(
                Icons.chevron_right_rounded,
                color: palette.muted,
              ),
          ],
        ),
      ),
    );
  }

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

  // --------------------------------------------------
  // SAVE TASK + REMINDER
  // --------------------------------------------------

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (dueDate != null && dueDate!.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Tr('Due date cannot be before start date.'),
        ),
      );
      return;
    }

    if (selectedTaskType == TaskType.recurring &&
        repeatDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Tr('Select at least one repeat day.'),
        ),
      );
      return;
    }

    if (reminderEnabled && scheduledTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Tr(
            'Please select a scheduled time for the reminder.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final oldTask = widget.task;

      final reminderId = oldTask?.reminderId ??
          TaskRepository.generateReminderId();

      final newTask = TaskModel(
        id: oldTask?.id ??
            TaskRepository.generateTaskId(),
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategory,
        taskType: selectedTaskType,
        priority: selectedPriority,
        startDate: startDate,
        dueDate: dueDate,
        scheduledHour: scheduledTime?.hour,
        scheduledMinute: scheduledTime?.minute,
        estimatedMinutes: estimatedMinutes,
        repeatDays: selectedTaskType == TaskType.recurring
            ? repeatDays
            : [],
        reminderEnabled: reminderEnabled,
        reminderId: reminderId,
        completedDates: oldTask?.completedDates ?? [],
        skippedDates: oldTask?.skippedDates ?? [],
        inProgressDates: oldTask?.inProgressDates ?? [],
        createdAt: oldTask?.createdAt ?? DateTime.now(),
      );

      // First save task data.
      if (isEditing) {
        await TaskRepository.instance.updateTask(newTask);
      } else {
        await TaskRepository.instance.addTask(newTask);
      }

      // Then schedule or cancel its reminder.
      // scheduleTaskReminder cancels old task notifications first.
      try {
        await NotificationService.instance.scheduleTaskReminder(
          newTask,
        );
      } catch (reminderError) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocale.pick('Task saved, but reminder could not be scheduled: $reminderError', 'টাস্ক সংরক্ষিত হয়েছে, কিন্তু রিমাইন্ডার সেট করা যায়নি: $reminderError'),
            ),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 5),
          ),
        );

        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? AppLocale.tr('Task updated successfully!')
                : AppLocale.tr('Task created successfully!'),
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.pick('Could not save task: $e', 'টাস্ক সংরক্ষণ করা যায়নি: $e')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // BUILD
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
          title: Text(
            isEditing
                ? AppLocale.tr('Edit Task')
                : AppLocale.tr('Create Task'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              30,
            ),
            children: [
              _sectionTitle(AppLocale.tr('Task Information')),
              const SizedBox(height: 12),

              _textField(
                controller: titleController,
                hint: AppLocale.tr('e.g. Study Mathematics'),
                label: AppLocale.tr('Task Title *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocale.tr('Please enter a task title.');
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              _textField(
                controller: descriptionController,
                hint: AppLocale.tr('Add task details or notes...'),
                label: AppLocale.tr('Description'),
                maxLines: 3,
              ),

              const SizedBox(height: 22),

              _sectionTitle(AppLocale.tr('Category')),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: palette.surface,
                  border: _inputBorder(palette.border),
                  enabledBorder: _inputBorder(palette.border),
                  focusedBorder: _inputBorder(accent, width: 1.6),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Tr(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),

              const SizedBox(height: 22),

              _sectionTitle(AppLocale.tr('Task Type'),
                subtitle: AppLocale.tr('Choose how this task should repeat.'),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _typeCard(
                      title: AppLocale.tr('One-time'),
                      subtitle: AppLocale.tr('Single occurrence'),
                      icon: Icons.looks_one_rounded,
                      type: TaskType.oneTime,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeCard(
                      title: AppLocale.tr('Recurring'),
                      subtitle: AppLocale.tr('Repeat on selected days'),
                      icon: Icons.repeat_rounded,
                      type: TaskType.recurring,
                    ),
                  ),
                ],
              ),

              if (selectedTaskType == TaskType.recurring) ...[
                const SizedBox(height: 20),
                _sectionTitle(AppLocale.tr('Repeat Days'),
                  subtitle: AppLocale.tr('Select the days you want to repeat this task.'),
                ),
                const SizedBox(height: 10),
                _buildRepeatDays(),
              ],

              const SizedBox(height: 22),

              _sectionTitle(AppLocale.tr('Priority')),
              const SizedBox(height: 12),

              Row(
                children: TaskPriority.values.map((priority) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: _priorityCard(priority),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              _sectionTitle(AppLocale.tr('Schedule')),
              const SizedBox(height: 12),

              _dateTile(
                title: AppLocale.tr('Start Date'),
                value: _formatDate(startDate),
                icon: Icons.calendar_today_rounded,
                onTap: _selectStartDate,
              ),

              const SizedBox(height: 10),

              _dateTile(
                title: AppLocale.tr('Due Date (Optional)'),
                value: dueDate == null
                    ? AppLocale.tr('No due date')
                    : _formatDate(dueDate!),
                icon: Icons.event_available_rounded,
                onTap: _selectDueDate,
                trailing: dueDate != null
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            dueDate = null;
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 19,
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: 10),

              _dateTile(
                title: AppLocale.tr('Scheduled Time (Optional)'),
                value: scheduledTime == null
                    ? AppLocale.tr('No scheduled time')
                    : scheduledTime!.format(context),
                icon: Icons.access_time_rounded,
                onTap: _selectTime,
                trailing: scheduledTime != null
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            scheduledTime = null;
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 19,
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: 22),

              _sectionTitle(AppLocale.tr('Estimated Duration')),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  children: [
                    Text(
                      AppLocale.digits(AppLocale.pick('$estimatedMinutes minutes', '$estimatedMinutes মিনিট')),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    Slider(
                      value: estimatedMinutes.toDouble(),
                      min: 5,
                      max: 240,
                      divisions: 47,
                      activeColor: accent,
                      label: AppLocale.digits(AppLocale.pick('$estimatedMinutes min', '$estimatedMinutes মিনিট')),
                      onChanged: (value) {
                        setState(() {
                          estimatedMinutes = value.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Tr(
                          '5 min',
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.muted,
                          ),
                        ),
                        Tr(
                          '4 hours',
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: palette.border),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: reminderEnabled,
                  activeThumbColor: accent,
                  onChanged: (value) {
                    setState(() {
                      reminderEnabled = value;
                    });
                  },
                  title: const Tr(
                    'Task Reminder',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Tr(
                    'Enable a notification at the scheduled time.',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 11,
                    ),
                  ),
                  secondary: Icon(
                    Icons.notifications_active_outlined,
                    color: accent,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSaving
                        ? const [
                            Color(0xFF2E4540),
                            Color(0xFF3B5750),
                          ]
                        : _emeraldGradient,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: gold.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _emeraldGradient.last
                          .withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: isSaving ? null : _saveTask,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: gold,
                    disabledForegroundColor:
                        gold.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: gold,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    isSaving
                        ? AppLocale.tr('Saving...')
                        : isEditing
                            ? AppLocale.tr('Update Task')
                            : AppLocale.tr('Create Task'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // TYPE CARD
  // --------------------------------------------------

  Widget _typeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required TaskType type,
  }) {
    final selected = selectedTaskType == type;

    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () {
        setState(() {
          selectedTaskType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _emeraldGradient,
                )
              : null,
          color: selected ? null : palette.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? gold.withValues(alpha: 0.7)
                : palette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? gold : palette.muted,
              size: 23,
            ),
            const SizedBox(height: 9),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : palette.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: selected ? goldLight : palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // PRIORITY CARD
  // --------------------------------------------------

  Widget _priorityCard(TaskPriority priority) {
    final selected = selectedPriority == priority;

    final color = switch (priority) {
      TaskPriority.high => const Color(0xFFE45D67),
      TaskPriority.medium => const Color(0xFFE0A13B),
      TaskPriority.low => const Color(0xFF159B83),
    };

    final label = switch (priority) {
      TaskPriority.high => AppLocale.tr('High'),
      TaskPriority.medium => AppLocale.tr('Medium'),
      TaskPriority.low => AppLocale.tr('Low'),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          selectedPriority = priority;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.14)
              : palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : palette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.flag_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: selected ? color : palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
