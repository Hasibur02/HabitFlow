
enum TaskType {
  oneTime,
  recurring,
}

enum TaskPriority {
  low,
  medium,
  high,
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String category;

  final TaskType taskType;
  final TaskPriority priority;

  final DateTime startDate;
  final DateTime? dueDate;

  final int? scheduledHour;
  final int? scheduledMinute;

  final int estimatedMinutes;

  // DateTime.weekday: Monday = 1 ... Sunday = 7
  final List<int> repeatDays;

  final bool reminderEnabled;
  final int reminderId;

  // Completion is recorded separately for each occurrence.
  final List<String> completedDates;
  final List<String> skippedDates;
  final List<String> inProgressDates;

  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Personal',
    this.taskType = TaskType.oneTime,
    this.priority = TaskPriority.medium,
    required this.startDate,
    this.dueDate,
    this.scheduledHour,
    this.scheduledMinute,
    this.estimatedMinutes = 30,
    this.repeatDays = const [],
    this.reminderEnabled = false,
    required this.reminderId,
    this.completedDates = const [],
    this.skippedDates = const [],
    this.inProgressDates = const [],
    required this.createdAt,
  });

  String dateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);

    return '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  bool isScheduledOn(DateTime date) {
    final selectedDate = DateTime(date.year, date.month, date.day);
    final firstDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    if (selectedDate.isBefore(firstDate)) return false;

    if (dueDate != null) {
      final lastDate = DateTime(
        dueDate!.year,
        dueDate!.month,
        dueDate!.day,
      );

      if (selectedDate.isAfter(lastDate)) return false;
    }

    if (taskType == TaskType.oneTime) {
      return selectedDate == firstDate;
    }

    return repeatDays.isEmpty || repeatDays.contains(selectedDate.weekday);
  }

  bool isCompletedOn(DateTime date) {
    return completedDates.contains(dateKey(date));
  }

  bool isSkippedOn(DateTime date) {
    return skippedDates.contains(dateKey(date));
  }

  bool isInProgressOn(DateTime date) {
    return inProgressDates.contains(dateKey(date));
  }

  TaskModel copyWith({
    String? title,
    String? description,
    String? category,
    TaskType? taskType,
    TaskPriority? priority,
    DateTime? startDate,
    DateTime? dueDate,
    bool clearDueDate = false,
    int? scheduledHour,
    int? scheduledMinute,
    bool clearScheduledTime = false,
    int? estimatedMinutes,
    List<int>? repeatDays,
    bool? reminderEnabled,
    int? reminderId,
    List<String>? completedDates,
    List<String>? skippedDates,
    List<String>? inProgressDates,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      taskType: taskType ?? this.taskType,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      scheduledHour: clearScheduledTime
          ? null
          : (scheduledHour ?? this.scheduledHour),
      scheduledMinute: clearScheduledTime
          ? null
          : (scheduledMinute ?? this.scheduledMinute),
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      repeatDays: repeatDays ?? this.repeatDays,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderId: reminderId ?? this.reminderId,
      completedDates: completedDates ?? this.completedDates,
      skippedDates: skippedDates ?? this.skippedDates,
      inProgressDates: inProgressDates ?? this.inProgressDates,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'taskType': taskType.name,
      'priority': priority.name,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'scheduledHour': scheduledHour,
      'scheduledMinute': scheduledMinute,
      'estimatedMinutes': estimatedMinutes,
      'repeatDays': repeatDays,
      'reminderEnabled': reminderEnabled,
      'reminderId': reminderId,
      'completedDates': completedDates,
      'skippedDates': skippedDates,
      'inProgressDates': inProgressDates,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    TaskType parseTaskType(String? value) {
      return TaskType.values.firstWhere(
        (item) => item.name == value,
        orElse: () => TaskType.oneTime,
      );
    }

    TaskPriority parsePriority(String? value) {
      return TaskPriority.values.firstWhere(
        (item) => item.name == value,
        orElse: () => TaskPriority.medium,
      );
    }

    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is String) {
        return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
      }

      return fallback ?? DateTime.now();
    }

    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }

      return [];
    }

    List<int> parseIntList(dynamic value) {
      if (value is List) {
        return value
            .map((item) => int.tryParse(item.toString()))
            .whereType<int>()
            .where((day) => day >= 1 && day <= 7)
            .toList();
      }

      return [];
    }

    final parsedStartDate = parseDate(json['startDate']);

    return TaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Personal',
      taskType: parseTaskType(json['taskType']?.toString()),
      priority: parsePriority(json['priority']?.toString()),
      startDate: parsedStartDate,
      dueDate: json['dueDate'] == null
          ? null
          : parseDate(json['dueDate']),
      scheduledHour: json['scheduledHour'] is num
          ? (json['scheduledHour'] as num).toInt()
          : null,
      scheduledMinute: json['scheduledMinute'] is num
          ? (json['scheduledMinute'] as num).toInt()
          : null,
      estimatedMinutes: json['estimatedMinutes'] is num
          ? (json['estimatedMinutes'] as num).toInt()
          : 30,
      repeatDays: parseIntList(json['repeatDays']),
      reminderEnabled: json['reminderEnabled'] == true,
      reminderId: json['reminderId'] is num
          ? (json['reminderId'] as num).toInt()
          : 0,
      completedDates: parseStringList(json['completedDates']),
      skippedDates: parseStringList(json['skippedDates']),
      inProgressDates: parseStringList(json['inProgressDates']),
      createdAt: parseDate(
        json['createdAt'],
        fallback: parsedStartDate,
      ),
    );
  }
}
