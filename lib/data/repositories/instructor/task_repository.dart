import 'package:dio/dio.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';

class TaskRepository {
  final Dio dio;

  TaskRepository(this.dio);

  /// Fetch tasks for a specific date
  Future<List<TaskModel>> fetchTasksByDate(DateTime date) async {
    try {
      final response = await dio.get(
        '/calendar/events',
        queryParameters: {
          'year': date.year,
          'month': date.month,
          'day': date.day,
        },
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final tasks = data
            .map((item) => TaskModel.fromMap(
                  item['id']?.toString() ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  item,
                ))
            .toList();

        // Filter tasks to only include those on the selected date
        final selectedDate = DateTime(date.year, date.month, date.day);
        return tasks.where((task) {
          final taskDate = DateTime(
            task.dateTime.year,
            task.dateTime.month,
            task.dateTime.day,
          );
          return taskDate == selectedDate;
        }).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      }
      return [];
    } catch (e) {
      // Return mock data for development if API fails
      return _getMockTasksForDate(date);
    }
  }

  /// Fetch all tasks for the current month
  Future<List<TaskModel>> fetchTasksForMonth(DateTime date) async {
    try {
      final response = await dio.get(
        '/calendar/events',
        queryParameters: {
          'year': date.year,
          'month': date.month,
        },
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data
            .map((item) => TaskModel.fromMap(
                  item['id']?.toString() ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  item,
                ))
            .toList();
      }
      return [];
    } catch (e) {
      // Return mock data for development if API fails
      return _getMockTasksForMonth(date);
    }
  }

  /// Create a new task
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final response = await dio.post(
        '/calendar/events',
        data: task.toMap(),
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return TaskModel.fromMap(data['id']?.toString() ?? '', data);
      }
      throw Exception('Failed to create task');
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  /// Update an existing task
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final response = await dio.put(
        '/calendar/events/${task.id}',
        data: task.toMap(),
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return TaskModel.fromMap(data['id']?.toString() ?? task.id, data);
      }
      throw Exception('Failed to update task');
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await dio.delete('/calendar/events/$taskId');
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }

  /// Mock data for development
  List<TaskModel> _getMockTasksForDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    // Only return mock tasks if the selected date is today
    if (selectedDate == today) {
      return [
        TaskModel(
          id: '1',
          title: 'Select an app or website and conduct an accessibility audit',
          description:
              'Select an app or website and conduct an accessibility audit',
          dateTime: DateTime(now.year, now.month, now.day, 11, 30),
          isPriority: true,
          type: TaskType.assignment,
        ),
        TaskModel(
          id: '2',
          title: 'Watch a lecture on UI/UX design and do homework',
          description: 'Watch a lecture on UI/UX design and do homework',
          dateTime: DateTime(now.year, now.month, now.day, 17, 0),
          isPriority: true,
          type: TaskType.assignment,
        ),
        TaskModel(
          id: '3',
          title:
              'Choose a real-world app that you use regularly and redesign it',
          description:
              'Choose a real-world app that you use regularly and redesign it',
          dateTime: DateTime(now.year, now.month, now.day, 10, 0),
          isPriority: false,
          type: TaskType.assignment,
        ),
        TaskModel(
          id: '4',
          title:
              'Address usability issues, improve the user interface, and enhance the overall user experience',
          description:
              'Address usability issues, improve the user interface, and enhance the overall user experience',
          dateTime: DateTime(now.year, now.month, now.day, 12, 0),
          isPriority: false,
          type: TaskType.assignment,
        ),
      ];
    }
    return [];
  }

  /// Mock data for month
  List<TaskModel> _getMockTasksForMonth(DateTime date) {
    return _getMockTasksForDate(date);
  }
}
