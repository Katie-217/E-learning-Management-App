// ========================================
// FILE: submission_controller.dart
// MÔ TẢ: Controller cho Submission operations với Riverpod
// ARCHITECTURE: Application Layer - Business Logic
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/submission_model.dart';
import '../../../domain/models/assignment_model.dart';
import '../../../domain/models/course_model.dart';
import '../../../data/repositories/submission/submission_repository.dart';

// ========================================
// STATE CLASSES
// ========================================

class SubmissionState {
  final bool isLoading;
  final List<SubmissionModel> submissions;
  final SubmissionModel? currentSubmission;
  final bool isSubmitting;
  final String? error;
  final Map<String, dynamic>? submissionStats;

  const SubmissionState({
    this.isLoading = false,
    this.submissions = const [],
    this.currentSubmission,
    this.isSubmitting = false,
    this.error,
    this.submissionStats,
  });

  SubmissionState copyWith({
    bool? isLoading,
    List<SubmissionModel>? submissions,
    SubmissionModel? currentSubmission,
    bool? isSubmitting,
    String? error,
    Map<String, dynamic>? submissionStats,
  }) {
    return SubmissionState(
      isLoading: isLoading ?? this.isLoading,
      submissions: submissions ?? this.submissions,
      currentSubmission: currentSubmission ?? this.currentSubmission,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      submissionStats: submissionStats ?? this.submissionStats,
    );
  }
}

// ========================================
// SUBMISSION CONTROLLER
// ========================================

class SubmissionController extends StateNotifier<SubmissionState> {
  SubmissionController() : super(const SubmissionState());

  // ========================================
  // HÀM: loadSubmissionForAssignment
  // MÔ TẢ: Load submission của student cho assignment cụ thể
  // ========================================
  Future<void> loadSubmissionForAssignment(
      String assignmentId, String studentId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      print(
          'DEBUG: 🔄 Loading submission for assignment: $assignmentId, student: $studentId');
      final submission =
          await SubmissionRepository.getStudentSubmissionForAssignment(
        assignmentId,
        studentId,
      );

      state = state.copyWith(
        isLoading: false,
        currentSubmission: submission,
      );

      if (submission != null) {
        print('DEBUG: ✅ Submission loaded: ${submission.id}');
      } else {
        print('DEBUG: ⚠️ No submission found');
      }
    } catch (e) {
      print('DEBUG: ❌ Error loading submission: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ========================================
  // HÀM: loadSubmissionsForAssignment
  // MÔ TẢ: Load tất cả submissions cho assignment (instructor view)
  // ========================================
  Future<void> loadSubmissionsForAssignment(String assignmentId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      print('DEBUG: 🔄 Loading submissions for assignment: $assignmentId');
      final submissions =
          await SubmissionRepository.getSubmissionsForAssignment(assignmentId);

      state = state.copyWith(
        isLoading: false,
        submissions: submissions,
      );

      print('DEBUG: ✅ Loaded ${submissions.length} submissions');
    } catch (e) {
      print('DEBUG: ❌ Error loading submissions: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ========================================
  // HÀM: loadSubmissionsForStudent
  // MÔ TẢ: Load submissions của student (dashboard)
  // ========================================
  Future<void> loadSubmissionsForStudent(String studentId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      print('DEBUG: 🔄 Loading submissions for student: $studentId');
      final submissions =
          await SubmissionRepository.getSubmissionsForStudent(studentId);

      state = state.copyWith(
        isLoading: false,
        submissions: submissions,
      );

      print('DEBUG: ✅ Loaded ${submissions.length} submissions for student');
    } catch (e) {
      print('DEBUG: ❌ Error loading student submissions: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ========================================
  // HÀM: createSubmission
  // MÔ TẢ: Create new submission
  // ========================================
  Future<bool> createSubmission({
    required Assignment assignment,
    required CourseModel course,
    required String studentId,
    required String studentName,
    List<AttachmentModel>? attachments,
    String? textContent,
    String? linkContent,
  }) async {
    try {
      state = state.copyWith(isSubmitting: true, error: null);

      print('DEBUG: 📝 Creating submission for assignment: ${assignment.id}');

      // Determine if submission is late
      final now = DateTime.now();
      final isLate = now.isAfter(assignment.deadline);

      // Calculate attempt number
      final attemptNumber = state.currentSubmission != null
          ? state.currentSubmission!.attemptNumber + 1
          : 1;

      // Create submission model
      final submission = SubmissionModel(
        id: '', // Will be set by Firestore
        assignmentId: assignment.id,
        studentId: studentId,
        studentName: studentName,
        courseId: course.id,
        submittedAt: now,
        status: SubmissionStatus.submitted,
        attachments: attachments ?? [],
        textContent: textContent ?? linkContent,
        isLate: isLate,
        attemptNumber: attemptNumber,
        lastModified: now,
        // TODO: Get these from proper context
        semesterId: 'current_semester',
        groupId: 'default_group',
      );

      final submissionId =
          await SubmissionRepository.createSubmission(submission);

      if (submissionId.isNotEmpty) {
        // Reload submission to get updated data
        await loadSubmissionForAssignment(assignment.id, studentId);

        state = state.copyWith(isSubmitting: false);
        print('DEBUG: ✅ Submission created with ID: $submissionId');
        return true;
      } else {
        state = state.copyWith(
          isSubmitting: false,
          error: 'Failed to create submission',
        );
        return false;
      }
    } catch (e) {
      print('DEBUG: ❌ Error creating submission: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // ========================================
  // HÀM: updateSubmission
  // MÔ TẢ: Update existing submission
  // ========================================
  Future<bool> updateSubmission({
    required String assignmentId,
    required String studentId,
    List<AttachmentModel>? attachments,
    String? textContent,
    String? linkContent,
  }) async {
    try {
      if (state.currentSubmission == null) {
        state = state.copyWith(error: 'No submission to update');
        return false;
      }

      state = state.copyWith(isSubmitting: true, error: null);

      print('DEBUG: 📝 Updating submission: ${state.currentSubmission!.id}');

      final updatedSubmission = state.currentSubmission!.copyWith(
        attachments: attachments ?? state.currentSubmission!.attachments,
        textContent:
            textContent ?? linkContent ?? state.currentSubmission!.textContent,
        status: SubmissionStatus.submitted,
        lastModified: DateTime.now(),
        attemptNumber: state.currentSubmission!.attemptNumber + 1,
      );

      await SubmissionRepository.updateSubmission(updatedSubmission);

      // Reload submission to get updated data
      await loadSubmissionForAssignment(assignmentId, studentId);

      state = state.copyWith(isSubmitting: false);
      print('DEBUG: ✅ Submission updated');
      return true;
    } catch (e) {
      print('DEBUG: ❌ Error updating submission: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // ========================================
  // HÀM: unsubmitAssignment
  // MÔ TẢ: Unsubmit assignment (change status back to draft)
  // ========================================
  Future<bool> unsubmitAssignment(String assignmentId, String studentId) async {
    try {
      if (state.currentSubmission == null) {
        return false;
      }

      state = state.copyWith(isSubmitting: true, error: null);

      print('DEBUG: ↩️ Unsubmitting assignment: $assignmentId');

      final updatedSubmission = state.currentSubmission!.copyWith(
        status: SubmissionStatus.missing,
        lastModified: DateTime.now(),
      );

      await SubmissionRepository.updateSubmission(updatedSubmission);

      // Reload submission
      await loadSubmissionForAssignment(assignmentId, studentId);

      state = state.copyWith(isSubmitting: false);
      print('DEBUG: ✅ Assignment unsubmitted');
      return true;
    } catch (e) {
      print('DEBUG: ❌ Error unsubmitting: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // ========================================
  // HÀM: loadSubmissionStats
  // MÔ TẢ: Load submission statistics for dashboard
  // ========================================
  Future<void> loadSubmissionStats({
    String? assignmentId,
    String? courseId,
    String? semesterId,
  }) async {
    try {
      print('DEBUG: 📊 Loading submission stats');
      final stats = await SubmissionRepository.getSubmissionStats(
        assignmentId: assignmentId,
        courseId: courseId,
        semesterId: semesterId,
      );

      state = state.copyWith(submissionStats: stats);
      print('DEBUG: ✅ Submission stats loaded');
    } catch (e) {
      print('DEBUG: ❌ Error loading submission stats: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // ========================================
  // HÀM: clearError
  // MÔ TẢ: Clear error state
  // ========================================
  void clearError() {
    state = state.copyWith(error: null);
  }

  // ========================================
  // HÀM: clearSubmission
  // MÔ TẢ: Clear current submission
  // ========================================
  void clearSubmission() {
    state = state.copyWith(currentSubmission: null);
  }

  // ========================================
  // HÀM: clearState
  // MÔ TẢ: Reset controller state
  // ========================================
  void clearState() {
    state = const SubmissionState();
  }
}

// ========================================
// RIVERPOD PROVIDERS
// ========================================

final submissionControllerProvider =
    StateNotifierProvider<SubmissionController, SubmissionState>((ref) {
  return SubmissionController();
});

// ========================================
// COMPUTED PROVIDERS
// ========================================

// Provider để get submissions list
final submissionsProvider = Provider<List<SubmissionModel>>((ref) {
  final state = ref.watch(submissionControllerProvider);
  return state.submissions;
});

// Provider để get current submission
final currentSubmissionProvider = Provider<SubmissionModel?>((ref) {
  final state = ref.watch(submissionControllerProvider);
  return state.currentSubmission;
});

// Provider để get loading state
final submissionsLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(submissionControllerProvider);
  return state.isLoading;
});

// Provider để get submitting state
final submissionSubmittingProvider = Provider<bool>((ref) {
  final state = ref.watch(submissionControllerProvider);
  return state.isSubmitting;
});

// Provider để get error state
final submissionsErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(submissionControllerProvider);
  return state.error;
});

// Provider để get submission stats
final submissionStatsProvider = Provider<Map<String, dynamic>?>((ref) {
  final state = ref.watch(submissionControllerProvider);
  return state.submissionStats;
});

// ========================================
// UTILITY PROVIDERS
// ========================================

// Provider để check if assignment is submitted
final isAssignmentSubmittedProvider = Provider<bool>((ref) {
  final submission = ref.watch(currentSubmissionProvider);
  return submission != null &&
      (submission.status == SubmissionStatus.submitted ||
          submission.status == SubmissionStatus.late ||
          submission.status == SubmissionStatus.graded);
});

// Provider để get submission status display
final submissionStatusDisplayProvider = Provider<Map<String, dynamic>>((ref) {
  final submission = ref.watch(currentSubmissionProvider);
  final isSubmitted = ref.watch(isAssignmentSubmittedProvider);

  if (isSubmitted) {
    return {
      'text': 'Turned in',
      'color': 'success',
      'icon': 'check_circle',
    };
  }

  if (submission != null && submission.status == SubmissionStatus.missing) {
    return {
      'text': 'Not Submitted',
      'color': 'warning',
      'icon': 'hourglass_empty',
    };
  }

  return {
    'text': 'Not submitted',
    'color': 'error',
    'icon': 'assignment',
  };
});

// ========================================
// ASYNC PROVIDERS FOR SPECIFIC OPERATIONS
// ========================================

// Provider để load submission for specific assignment and student
final studentSubmissionProvider =
    FutureProvider.family<SubmissionModel?, Map<String, String>>(
        (ref, params) async {
  final assignmentId = params['assignmentId']!;
  final studentId = params['studentId']!;

  final controller = ref.read(submissionControllerProvider.notifier);
  await controller.loadSubmissionForAssignment(assignmentId, studentId);

  return ref.read(currentSubmissionProvider);
});

// Provider để load submissions for assignment (instructor view)
final assignmentSubmissionsProvider =
    FutureProvider.family<List<SubmissionModel>, String>(
        (ref, assignmentId) async {
  final controller = ref.read(submissionControllerProvider.notifier);
  await controller.loadSubmissionsForAssignment(assignmentId);
  return ref.read(submissionsProvider);
});
