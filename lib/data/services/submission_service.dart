import 'package:cloud_functions/cloud_functions.dart';
import 'package:elearning_management_app/domain/models/submission_model.dart';

/// 🔒 SECURE SUBMISSION SERVICE
/// Calls Cloud Function to validate and create submissions server-side
/// This prevents spam submissions and enforces max attempt limits
class SubmissionService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Submit assignment via callable function
  /// This is the ONLY way to submit assignments securely
  ///
  /// Returns a map with submission details or throws an error
  static Future<Map<String, dynamic>> submitAssignment({
    required String assignmentId,
    required List<AttachmentModel> attachments,
    String? textContent,
  }) async {
    try {
      print('🚀 Calling submitAssignment function');
      print('   Assignment ID: $assignmentId');
      print('   Attachments: ${attachments.length}');

      final HttpsCallable callable =
          _functions.httpsCallable('submitAssignment');

      // Convert attachments to JSON
      final attachmentsJson = attachments.map((att) => att.toMap()).toList();

      final result = await callable.call({
        'assignmentId': assignmentId,
        'attachments': attachmentsJson,
        'textContent': textContent,
      });

      print('✅ submitAssignment success: ${result.data}');

      // Return the response data
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      print('❌ FirebaseFunctionsException: ${e.code} - ${e.message}');

      // Re-throw with user-friendly messages
      switch (e.code) {
        case 'unauthenticated':
          throw Exception('You must be logged in to submit assignments');
        case 'invalid-argument':
          throw Exception(e.message ?? 'Invalid submission data');
        case 'not-found':
          throw Exception('Assignment not found');
        case 'failed-precondition':
          throw Exception(e.message ?? 'Cannot submit: deadline has passed');
        case 'resource-exhausted':
          throw Exception(
              e.message ?? 'You have reached the maximum submission limit');
        default:
          throw Exception(e.message ?? 'Failed to submit assignment');
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Failed to submit assignment: $e');
    }
  }
}
