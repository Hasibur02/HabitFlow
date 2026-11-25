import '../../app_locale.dart';
import 'package:flutter/material.dart';

import '../../models/task_model.dart';
import '../../notification_service.dart';
import 'task_repository.dart';
import '../../theme_controller.dart';
import 'add_edit_task_screen.dart';
import 'task_detail_screen.dart';

enum TaskFilter {
  all,
  today,
  upcoming,
  completed,
  overdue,
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  static const Color primaryColor = Color(0xFF0F6B57);

  // ---------------- LUXURY THEME ----------------
  static const Color gold = Color(0xFFE2B857);
  static const Color goldLight = Color(0xFFF6E7B4);

  static const List<Color> _emeraldGradient = [
    Color(0xFF06241E),
    Color(0xFF0C4A3C),
    Color(0xFF14876B),
  ];

  static const List<Color> _oceanGradient = [
    Color(0xFF082A33),
    Color(0xFF0F5566),
    Color(0xFF1C8DA3),
  ];

  static const List<Color> _wineGradient = [
    Color(0xFF2E0B1A),
    Color(0xFF7A1F3D),
    Color(0xFFD6455F),
  ];

  static const List<Color> _mutedGradient = [
    Color(0xFF1F2E2B),
    Color(0xFF2E4540),
  ];

  BoxDecoration _luxuryDecoration({
    List<Color> colors = _emeraldGradient,
    double radius = 17,
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

  List<TaskModel> tasks = [];

  bool isLoading = true;
  String searchQuery = '';

  TaskFilter selectedFilter = TaskFilter.all;
  TaskPriority? selectedPriority;

  final TextEditingController searchController =
      TextEditingController();

  DateTime get today => DateUtils.dateOnly(DateTime.now());

  String _dateKey(DateTime date) {
    final d = DateUtils.dateOnly(date);

    return '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // LOAD TASKS
  // --------------------------------------------------

  Future<void> _loadTasks() async {
    try {
      final loadedTasks =
          await TaskRepository.instance.getTasks();

      if (!mounted) return;

      setState(() {
        tasks = loadedTasks;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.pick('Could not load tasks: $e', 'টাস্ক লোড করা যায়নি: $e')),
        ),
      );
    }
  }

  // --------------------------------------------------
  // FILTER TASKS
  // --------------------------------------------------

  List<TaskModel> get filteredTasks {
    final query = searchQuery.toLowerCase().trim();

    return tasks.where((task) {
      bool matchesTab = false;

      switch (selectedFilter) {
        case TaskFilter.all:
          matchesTab = true;
          break;

        case TaskFilter.today:
          matchesTab = task.isScheduledOn(today) &&
              !task.isCompletedOn(today) &&
              !task.isSkippedOn(today);
          break;

        case TaskFilter.upcoming:
          matchesTab = task.startDate.isAfter(today) &&
              !task.isCompletedOn(task.startDate);
          break;

        case TaskFilter.completed:
          matchesTab = task.completedDates.isNotEmpty;
          break;

        case TaskFilter.overdue:
          final dueDate = task.dueDate ?? task.startDate;

          matchesTab = DateUtils.dateOnly(dueDate)
                  .isBefore(today) &&
              !task.isCompletedOn(dueDate);
          break;
      }

      final matchesPriority = selectedPriority == null ||
          task.priority == selectedPriority;

      final matchesSearch = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.category.toLowerCase().contains(query);

      return matchesTab &&
          matchesPriority &&
          matchesSearch;
    }).toList()
      ..sort((a, b) {
        if (selectedFilter == TaskFilter.completed) {
          return b.createdAt.compareTo(a.createdAt);
        }

        final priorityOrder = {
          TaskPriority.high: 0,
          TaskPriority.medium: 1,
          TaskPriority.low: 2,
        };

        final priorityComparison =
            priorityOrder[a.priority]!
                .compareTo(priorityOrder[b.priority]!);

        if (priorityComparison != 0) {
          return priorityComparison;
        }

        return a.startDate.compareTo(b.startDate);
      });
  }

  int _count(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return tasks.length;

      case TaskFilter.today:
        return tasks.where((task) {
          return task.isScheduledOn(today) &&
              !task.isCompletedOn(today) &&
              !task.isSkippedOn(today);
        }).length;

      case TaskFilter.upcoming:
        return tasks.where((task) {
          return task.startDate.isAfter(today) &&
              !task.isCompletedOn(task.startDate);
        }).length;

      case TaskFilter.completed:
        return tasks.where((task) {
          return task.completedDates.isNotEmpty;
        }).length;

      case TaskFilter.overdue:
        return tasks.where((task) {
          final dueDate = task.dueDate ?? task.startDate;

          return DateUtils.dateOnly(dueDate)
                  .isBefore(today) &&
              !task.isCompletedOn(dueDate);
        }).length;
    }
  }

  // --------------------------------------------------
  // TASK ACTIONS
  // --------------------------------------------------

  Future<void> _toggleTask(TaskModel task) async {
    final occurrenceDate =
        task.taskType == TaskType.oneTime
            ? task.startDate
            : today;

    final key = _dateKey(occurrenceDate);

    final completed = List<String>.from(
      task.completedDates,
    );

    final skipped = List<String>.from(
      task.skippedDates,
    );

    final inProgress = List<String>.from(
      task.inProgressDates,
    );

    if (completed.contains(key)) {
      completed.remove(key);
    } else {
      completed.add(key);

      skipped.remove(key);
      inProgress.remove(key);
    }

    final updatedTask = task.copyWith(
      completedDates: completed,
      skippedDates: skipped,
      inProgressDates: inProgress,
    );

    await TaskRepository.instance.updateTask(updatedTask);

    await _loadTasks();
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Tr('Delete Task?'),
          content: Text(
            AppLocale.pick('Are you sure you want to delete "${task.title}"?', '"${task.title}" মুছে ফেলতে আপনি কি নিশ্চিত?'),
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
      // Delete task data first.
      await TaskRepository.instance.deleteTask(task.id);

      // Cancel only this task's reminders.
      try {
        await NotificationService.instance.cancelTaskReminder(
          task.reminderId,
        );
      } catch (e) {
        debugPrint('Could not cancel task reminder: $e');
      }

      if (!mounted) return;

      await _loadTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Tr('Task deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
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
  // NAVIGATION
  // --------------------------------------------------

  Future<void> _addTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditTaskScreen(),
      ),
    );

    await _loadTasks();
  }

  Future<void> _openTask(TaskModel task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task),
      ),
    );

    await _loadTasks();
  }

  Future<void> _editTask(TaskModel task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTaskScreen(task: task),
      ),
    );

    await _loadTasks();
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

  String _dateLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${AppLocale.tr(months[date.month - 1])} ${date.year}';
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppLocale.tr('High');
      case TaskPriority.medium:
        return AppLocale.tr('Medium');
      case TaskPriority.low:
        return AppLocale.tr('Low');
    }
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFE45D67);
      case TaskPriority.medium:
        return const Color(0xFFE0A13B);
      case TaskPriority.low:
        return const Color(0xFF159B83);
    }
  }

  Color _filterColor(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.overdue:
        return Colors.red;
      case TaskFilter.completed:
        return const Color(0xFF159B83);
      default:
        return AppPalette.of(context).accent;
    }
  }

  String _filterLabel(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return AppLocale.tr('All');
      case TaskFilter.today:
        return AppLocale.tr('Today');
      case TaskFilter.upcoming:
        return AppLocale.tr('Upcoming');
      case TaskFilter.completed:
        return AppLocale.tr('Completed');
      case TaskFilter.overdue:
        return AppLocale.tr('Overdue');
    }
  }

  String _taskDateLabel(TaskModel task) {
    if (task.taskType == TaskType.recurring) {
      return AppLocale.tr('Recurring');
    }

    return _dateLabel(task.startDate);
  }

  // --------------------------------------------------
  // HEADER
  // --------------------------------------------------

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tr(
          'Manage your tasks',
          style: TextStyle(
            color: AppPalette.of(context).muted,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: AppLocale.tr('Total'),
                count: tasks.length,
                icon: Icons.checklist_rounded,
                gradient: _emeraldGradient,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                title: AppLocale.tr('Today'),
                count: _count(TaskFilter.today),
                icon: Icons.today_rounded,
                gradient: _oceanGradient,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                title: AppLocale.tr('Overdue'),
                count: _count(TaskFilter.overdue),
                icon: Icons.warning_amber_rounded,
                gradient: _wineGradient,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required int count,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 14,
      ),
      decoration: _luxuryDecoration(colors: gradient, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: gold, size: 18),
          ),
          const SizedBox(height: 9),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: goldLight,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // FILTERS
  // --------------------------------------------------

  Widget _buildTaskFilters() {
    const filters = TaskFilter.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = selectedFilter == filter;
          final color = _filterColor(filter);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                '${_filterLabel(filter)} (${_count(filter)})',
              ),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  selectedFilter = filter;
                });
              },
              selectedColor: color.withValues(alpha: 0.13),
              backgroundColor: AppPalette.of(context).surface,
              side: BorderSide(
                color: selected ? color : AppPalette.of(context).border,
              ),
              labelStyle: TextStyle(
                color: selected ? color : AppPalette.of(context).ink,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriorityFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 9),
            child: Tr(
              'Priority:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppPalette.of(context).muted,
              ),
            ),
          ),
          _priorityChip(AppLocale.tr('All'), null),
          _priorityChip(AppLocale.tr('High'), TaskPriority.high),
          _priorityChip(AppLocale.tr('Medium'), TaskPriority.medium),
          _priorityChip(AppLocale.tr('Low'), TaskPriority.low),
        ],
      ),
    );
  }

  Widget _priorityChip(
    String label,
    TaskPriority? priority,
  ) {
    final selected = selectedPriority == priority;

    final color =
        priority == null
        ? AppPalette.of(context).accent
        : _priorityColor(priority);

    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            selectedPriority = priority;
          });
        },
        selectedColor: color.withValues(alpha: 0.13),
        backgroundColor: AppPalette.of(context).surface,
        side: BorderSide(
          color: selected ? color : AppPalette.of(context).border,
        ),
        labelStyle: TextStyle(
          color: selected ? color : AppPalette.of(context).ink,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // --------------------------------------------------
  // SEARCH
  // --------------------------------------------------

  Widget _buildSearch() {
    return TextField(
      controller: searchController,
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: AppLocale.tr('Search tasks...'),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  searchController.clear();

                  setState(() {
                    searchQuery = '';
                  });
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: AppPalette.of(context).surface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: AppPalette.of(context).border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: AppPalette.of(context).border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: AppPalette.of(context).accent,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // TASK LIST
  // --------------------------------------------------

  Widget _buildTaskList() {
    final items = filteredTasks;

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: items.map(_buildTaskCard).toList(),
    );
  }

  Widget _buildEmptyState() {
    String message;

    switch (selectedFilter) {
      case TaskFilter.today:
        message = AppLocale.tr('No tasks scheduled for today.');
        break;
      case TaskFilter.upcoming:
        message = AppLocale.tr('No upcoming tasks.');
        break;
      case TaskFilter.completed:
        message = AppLocale.tr('No completed tasks yet.');
        break;
      case TaskFilter.overdue:
        message = AppLocale.tr('Great! No overdue tasks.');
        break;
      case TaskFilter.all:
        message = AppLocale.tr('Start organizing your day.');
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 38,
        horizontal: 20,
      ),
      decoration: _luxuryDecoration(radius: 19),
      child: Column(
        children: [
          const Icon(
            Icons.task_alt_rounded,
            size: 48,
            color: gold,
          ),
          const SizedBox(height: 13),
          const Tr(
            'Nothing here',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: goldLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final occurrenceDate =
        task.taskType == TaskType.oneTime
            ? task.startDate
            : today;

    final isCompleted = task.isCompletedOn(occurrenceDate);

    final scheduledTime =
        task.scheduledHour != null &&
                task.scheduledMinute != null
            ? TimeOfDay(
                hour: task.scheduledHour!,
                minute: task.scheduledMinute!,
              ).format(context)
            : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _luxuryDecoration(
        colors: isCompleted ? _mutedGradient : _emeraldGradient,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => _openTask(task),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: isCompleted,
                  activeColor: gold,
                  checkColor: const Color(0xFF06241E),
                  side: BorderSide(
                    color: gold.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (_) => _toggleTask(task),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: goldLight,
                          color: isCompleted
                              ? Colors.white54
                              : Colors.white,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 7,
                        runSpacing: 6,
                        crossAxisAlignment:
                            WrapCrossAlignment.center,
                        children: [
                          _smallTag(AppLocale.tr(task.category), goldLight),
                          _smallTag(
                            _priorityLabel(task.priority),
                            _priorityColor(task.priority),
                          ),
                          _smallTag(
                            task.taskType == TaskType.recurring
                                ? AppLocale.tr('Recurring')
                                : AppLocale.tr('One-time'),
                            Colors.white70,
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 12,
                        runSpacing: 5,
                        children: [
                          _detailText(
                            Icons.calendar_today_rounded,
                            _taskDateLabel(task),
                          ),
                          if (scheduledTime != null)
                            _detailText(
                              Icons.access_time_rounded,
                              scheduledTime,
                            ),
                          _detailText(
                            Icons.timelapse_rounded,
                            AppLocale.digits(AppLocale.pick('${task.estimatedMinutes} min', '${task.estimatedMinutes} মিনিট')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: goldLight,
                  ),
                  onSelected: (value) {
                    if (value == 'details') {
                      _openTask(task);
                    } else if (value == 'delete') {
                      _deleteTask(task);
                    } else if (value == 'edit') {
                      _editTask(task);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'details',
                      child: ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Tr('Details'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Tr('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        title: Tr(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Color.lerp(color, Colors.white, 0.35),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _detailText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: gold),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
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

    final items = filteredTasks;

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
          title: Tr(
            'My Tasks',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppPalette.of(context).ink,
            ),
          ),
          actions: [
            IconButton(
              tooltip: AppLocale.tr('Refresh'),
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 5),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addTask,
          backgroundColor: const Color(0xFF0C4A3C),
          foregroundColor: gold,
          icon: const Icon(Icons.add_rounded),
          label: const Tr('Add Task'),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: _loadTasks,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 23),
                    _buildSearch(),
                    const SizedBox(height: 17),
                    _buildTaskFilters(),
                    const SizedBox(height: 13),
                    _buildPriorityFilters(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocale.pick('${_filterLabel(selectedFilter)} Tasks', '${_filterLabel(selectedFilter)} টাস্ক'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppLocale.digits(AppLocale.pick('${items.length} tasks', '${items.length}টি টাস্ক')),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTaskList(),
                  ],
                ),
              ),
      ),
    );
  }
}
