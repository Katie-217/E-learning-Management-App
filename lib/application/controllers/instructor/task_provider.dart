import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';
import 'package:elearning_management_app/data/repositories/instructor/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  // Create Dio instance with base URL configuration
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000/api', // Update this with your actual API base URL
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));
  return TaskRepository(dio);
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final tasksProvider = FutureProvider.family<List<TaskModel>, DateTime>((ref, date) async {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.fetchTasksByDate(date);
});

final tasksForMonthProvider = FutureProvider.family<List<TaskModel>, DateTime>((ref, month) async {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.fetchTasksForMonth(month);
});

final taskFilterProvider = StateProvider<TaskFilter>((ref) {
  return TaskFilter.all;
});

enum TaskFilter {
  all,
  priority,
  completed,
  pending,
}

