
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/task_model.dart';

class TaskRepository {
  TaskRepository._();

  static final TaskRepository instance = TaskRepository._();

  static const String storageKey = 'tasks_v1';

  Future<List<TaskModel>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(storageKey);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(savedData);

      if (decoded is! List) return [];

      final tasks = <TaskModel>[];

      for (final item in decoded) {
        if (item is! Map) continue;

        try {
          final task = TaskModel.fromJson(
            Map<String, dynamic>.from(item),
          );

          if (task.id.isNotEmpty) {
            tasks.add(task);
          }
        } catch (e) {
          // Ignore an invalid task without losing other tasks.
        }
      }

      return tasks;
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveTasks(List<TaskModel> tasks) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      tasks.map((task) => task.toJson()).toList(),
    );

    await prefs.setString(storageKey, encoded);
  }

  Future<void> addTask(TaskModel task) async {
    final tasks = await getTasks();

    final alreadyExists = tasks.any(
      (item) => item.id == task.id,
    );

    if (alreadyExists) {
      throw Exception('A task with this ID already exists.');
    }

    tasks.add(task);

    await _saveTasks(tasks);
  }

  Future<void> updateTask(TaskModel updatedTask) async {
    final tasks = await getTasks();

    final index = tasks.indexWhere(
      (task) => task.id == updatedTask.id,
    );

    if (index == -1) {
      throw Exception('Task not found.');
    }

    tasks[index] = updatedTask;

    await _saveTasks(tasks);
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await getTasks();

    tasks.removeWhere(
      (task) => task.id == taskId,
    );

    await _saveTasks(tasks);
  }

  Future<TaskModel?> getTaskById(String taskId) async {
    final tasks = await getTasks();

    for (final task in tasks) {
      if (task.id == taskId) {
        return task;
      }
    }

    return null;
  }

  Future<List<TaskModel>> getTasksForDate(DateTime date) async {
    final tasks = await getTasks();

    return tasks.where((task) {
      return task.isScheduledOn(date);
    }).toList();
  }

  Future<void> clearAllTasks() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(storageKey);
  }

  // Generate unique IDs for tasks and their notifications.
  // Task notification IDs use a separate range from existing habit IDs.
  static String generateTaskId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  static int generateReminderId() {
    return 1000000000 +
        (DateTime.now().microsecondsSinceEpoch % 1000000000);
  }
}
