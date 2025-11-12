import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elearning_management_app/domain/models/task_model.dart';
import 'package:elearning_management_app/application/controllers/instructor/task_provider.dart';

class TaskListWidget extends ConsumerWidget {
  const TaskListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final tasksAsync = ref.watch(tasksProvider(selectedDate));
    final taskFilter = ref.watch(taskFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with filter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Task today',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            _buildFilterDropdown(context, ref, taskFilter),
          ],
        ),
        const SizedBox(height: 16),
        // Tasks list
        tasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No tasks for today',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }

            final priorityTasks = tasks
                .where((task) => task.isPriority && !task.isCompleted)
                .toList();
            final otherTasks = tasks
                .where((task) => !task.isPriority && !task.isCompleted)
                .toList();

            // Apply filter
            List<TaskModel> filteredPriorityTasks = priorityTasks;
            List<TaskModel> filteredOtherTasks = otherTasks;

            if (taskFilter == TaskFilter.priority) {
              filteredOtherTasks = [];
            } else if (taskFilter == TaskFilter.completed) {
              filteredPriorityTasks = tasks
                  .where((task) => task.isPriority && task.isCompleted)
                  .toList();
              filteredOtherTasks = tasks
                  .where((task) => !task.isPriority && task.isCompleted)
                  .toList();
            } else if (taskFilter == TaskFilter.pending) {
              filteredPriorityTasks = priorityTasks;
              filteredOtherTasks = otherTasks;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (filteredPriorityTasks.isNotEmpty) ...[
                  const Text(
                    'Priority',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...filteredPriorityTasks.map((task) => _buildTaskCard(
                        context,
                        task,
                        isPriority: true,
                      )),
                  const SizedBox(height: 16),
                ],
                if (filteredOtherTasks.isNotEmpty) ...[
                  const Text(
                    'Other',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...filteredOtherTasks.map((task) => _buildTaskCard(
                        context,
                        task,
                        isPriority: false,
                      )),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Error loading tasks: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context,
    WidgetRef ref,
    TaskFilter currentFilter,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<TaskFilter>(
        value: currentFilter,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        items: TaskFilter.values.map((filter) {
          return DropdownMenuItem<TaskFilter>(
            value: filter,
            child: Text(_getFilterLabel(filter)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            ref.read(taskFilterProvider.notifier).state = value;
          }
        },
      ),
    );
  }

  String _getFilterLabel(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'All tasks';
      case TaskFilter.priority:
        return 'Priority only';
      case TaskFilter.completed:
        return 'Completed';
      case TaskFilter.pending:
        return 'Pending';
    }
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task, {required bool isPriority}) {
    final timeFormat = DateFormat('h:mm a').format(task.dateTime);
    final dateFormat = DateFormat('EEEE').format(task.dateTime);
    final isToday = _isToday(task.dateTime);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isPriority ? Colors.yellow.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.description.isEmpty ? task.title : task.description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isToday
                        ? 'Today - $timeFormat'
                        : '$dateFormat - $timeFormat',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isPriority)
              Icon(
                Icons.notifications_active,
                color: Colors.purple,
                size: 20,
              )
            else
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () {
                  // Show task options
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

