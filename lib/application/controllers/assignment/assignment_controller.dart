// ========================================
// FILE: assignment_controller.dart
// MÔ TẢ: Controller cho Assignment operations với Riverpod
// ARCHITECTURE: Application Layer - Business Logic
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/assignment_model.dart';
import '../../../data/repositories/assignment/assignment_repository.dart';

// ========================================
// STATE CLASSES
// ========================================

class AssignmentState {
  final bool isLoading;
  final List<Assignment> assignments;
  final Assignment? selectedAssignment;
  final String? error;

  const AssignmentState({
    this.isLoading = false,
    this.assignments = const [],
    this.selectedAssignment,
    this.error,
  });

  AssignmentState copyWith({
    bool? isLoading,
    List<Assignment>? assignments,
    Assignment? selectedAssignment,
    String? error,
  }) {
    return AssignmentState(
      isLoading: isLoading ?? this.isLoading,
      assignments: assignments ?? this.assignments,
      selectedAssignment: selectedAssignment ?? this.selectedAssignment,
      error: error,
    );
  }
}

// ========================================
// ASSIGNMENT CONTROLLER
// ========================================

class AssignmentController extends StateNotifier<AssignmentState> {
  AssignmentController() : super(const AssignmentState());

  // ========================================
  // HÀM: loadAssignmentsByCourse
  // MÔ TẢ: Load assignments từ repository
  // ========================================
  Future<void> loadAssignmentsByCourse(String courseId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      print('DEBUG: 🔄 Loading assignments for course: $courseId');
      final assignments =
          await AssignmentRepository.getAssignmentsByCourse(courseId);

      state = state.copyWith(
        isLoading: false,
        assignments: assignments,
      );

      print('DEBUG: ✅ Loaded ${assignments.length} assignments');
    } catch (e) {
      print('DEBUG: ❌ Error loading assignments: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ========================================
  // HÀM: loadAssignmentsBySemester
  // MÔ TẢ: Load assignments theo semester (for dashboard)
  // ========================================
  Future<void> loadAssignmentsBySemester(String semesterId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      print('DEBUG: 🔄 Loading assignments for semester: $semesterId');
      final assignments =
          await AssignmentRepository.getAssignmentsBySemester(semesterId);

      state = state.copyWith(
        isLoading: false,
        assignments: assignments,
      );

      print('DEBUG: ✅ Loaded ${assignments.length} assignments for semester');
    } catch (e) {
      print('DEBUG: ❌ Error loading semester assignments: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ========================================
  // HÀM: loadAssignmentsForStudent
  // MÔ TẢ: Load assignments cho student dashboard
  // ========================================
  Future<void> loadAssignmentsForStudent(
      String studentId, List<String> enrolledCourseIds) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      print('DEBUG: 🔄 Loading assignments for student: $studentId');
      final assignments = await AssignmentRepository.getAssignmentsForStudent(
          studentId, enrolledCourseIds);

      state = state.copyWith(
        isLoading: false,
        assignments: assignments,
      );

      print('DEBUG: ✅ Loaded ${assignments.length} assignments for student');
    } catch (e) {
      print('DEBUG: ❌ Error loading student assignments: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ========================================
  // HÀM: createAssignment
  // MÔ TẢ: Create new assignment (for instructors)
  // ========================================
  Future<bool> createAssignment(Assignment assignment) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      print('DEBUG: 📝 Creating assignment: ${assignment.title}');
      final assignmentId =
          await AssignmentRepository.createAssignment(assignment);

      if (assignmentId.isNotEmpty) {
        // Reload assignments to include new one
        await loadAssignmentsByCourse(assignment.courseId);
        print('DEBUG: ✅ Assignment created with ID: $assignmentId');
        return true;
      } else {
        state = state.copyWith(
            isLoading: false, error: 'Failed to create assignment');
        return false;
      }
    } catch (e) {
      print('DEBUG: ❌ Error creating assignment: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // ========================================
  // HÀM: updateAssignment
  // MÔ TẢ: Update existing assignment
  // ========================================
  Future<bool> updateAssignment(Assignment assignment) async {
    try {
      print('DEBUG: 📝 Updating assignment: ${assignment.id}');
      await AssignmentRepository.updateAssignment(assignment);

      // Update in local state
      final updatedAssignments = state.assignments
          .map((a) => a.id == assignment.id ? assignment : a)
          .toList();

      state = state.copyWith(assignments: updatedAssignments);
      print('DEBUG: ✅ Assignment updated');
      return true;
    } catch (e) {
      print('DEBUG: ❌ Error updating assignment: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ========================================
  // HÀM: deleteAssignment
  // MÔ TẢ: Delete assignment
  // ========================================
  Future<bool> deleteAssignment(String assignmentId) async {
    try {
      print('DEBUG: 🗑️ Deleting assignment: $assignmentId');
      await AssignmentRepository.deleteAssignment(assignmentId);

      // Remove from local state
      final updatedAssignments =
          state.assignments.where((a) => a.id != assignmentId).toList();
      state = state.copyWith(assignments: updatedAssignments);

      print('DEBUG: ✅ Assignment deleted');
      return true;
    } catch (e) {
      print('DEBUG: ❌ Error deleting assignment: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ========================================
  // HÀM: selectAssignment
  // MÔ TẢ: Set selected assignment for detail view
  // ========================================
  void selectAssignment(Assignment assignment) {
    state = state.copyWith(selectedAssignment: assignment);
    print('DEBUG: 🎯 Selected assignment: ${assignment.title}');
  }

  // ========================================
  // HÀM: clearError
  // MÔ TẢ: Clear error state
  // ========================================
  void clearError() {
    state = state.copyWith(error: null);
  }

  // ========================================
  // HÀM: clearState
  // MÔ TẢ: Reset controller state
  // ========================================
  void clearState() {
    state = const AssignmentState();
  }
}

// ========================================
// RIVERPOD PROVIDERS
// ========================================

final assignmentControllerProvider =
    StateNotifierProvider<AssignmentController, AssignmentState>((ref) {
  return AssignmentController();
});

// ========================================
// COMPUTED PROVIDERS
// ========================================

// Provider để get assignments list
final assignmentsProvider = Provider<List<Assignment>>((ref) {
  final state = ref.watch(assignmentControllerProvider);
  return state.assignments;
});

// Provider để get selected assignment
final selectedAssignmentProvider = Provider<Assignment?>((ref) {
  final state = ref.watch(assignmentControllerProvider);
  return state.selectedAssignment;
});

// Provider để get loading state
final assignmentsLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(assignmentControllerProvider);
  return state.isLoading;
});

// Provider để get error state
final assignmentsErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(assignmentControllerProvider);
  return state.error;
});

// ========================================
// UTILITY PROVIDERS
// ========================================

// Provider để get current user
final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

// Provider để check if user is instructor
final isInstructorProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  // TODO: Implement instructor check logic
  // For now, assume all authenticated users can be instructors
  return user != null;
});

// Provider để get assignments by status
final assignmentsByStatusProvider =
    Provider.family<List<Assignment>, String>((ref, status) {
  final assignments = ref.watch(assignmentsProvider);
  final now = DateTime.now();

  switch (status) {
    case 'upcoming':
      return assignments.where((a) => a.startDate.isAfter(now)).toList();
    case 'active':
      return assignments
          .where((a) => a.startDate.isBefore(now) && a.deadline.isAfter(now))
          .toList();
    case 'overdue':
      return assignments.where((a) => a.deadline.isBefore(now)).toList();
    default:
      return assignments;
  }
});

// ========================================
// ASYNC PROVIDERS FOR SPECIFIC OPERATIONS
// ========================================

// Provider để load assignments for specific course
final courseAssignmentsProvider =
    FutureProvider.family<List<Assignment>, String>((ref, courseId) async {
  final controller = ref.read(assignmentControllerProvider.notifier);
  await controller.loadAssignmentsByCourse(courseId);
  return ref.read(assignmentsProvider);
});
