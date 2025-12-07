import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Service to handle returning grades to students via Cloud Function
class GradeReturnService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Call Cloud Function to return assignment grades to selected students
  ///
  /// Parameters:
  /// - [assignmentId]: The assignment ID
  /// - [courseId]: The course ID
  /// - [studentIds]: List of student IDs to return grades to
  /// - [feedback]: Optional feedback message for all students
  ///
  /// Returns a Map with the result
  Future<Map<String, dynamic>> returnAssignmentGrades({
    required String assignmentId,
    required String courseId,
    required List<String> studentIds,
    String? feedback,
  }) async {
    try {
      debugPrint('📤 Calling returnAssignmentGrades Cloud Function');
      debugPrint('📋 Assignment: $assignmentId');
      debugPrint('👥 Students: ${studentIds.length}');

      final callable = _functions.httpsCallable('returnAssignmentGrades');

      final result = await callable.call<Map<String, dynamic>>({
        'assignmentId': assignmentId,
        'courseId': courseId,
        'studentIds': studentIds,
        'feedback': feedback ?? '',
      });

      debugPrint('✅ Cloud Function result: ${result.data}');

      return result.data ?? {'success': false, 'message': 'No data returned'};
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ FirebaseFunctionsException: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': e.message ?? 'Unknown error',
        'code': e.code,
      };
    } catch (e) {
      debugPrint('❌ Error calling returnAssignmentGrades: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Call Cloud Function to return quiz grades to selected students
  ///
  /// Parameters:
  /// - [quizId]: The quiz ID
  /// - [courseId]: The course ID
  /// - [studentIds]: List of student IDs to return grades to
  ///
  /// Returns a Map with the result
  Future<Map<String, dynamic>> returnQuizGrades({
    required String quizId,
    required String courseId,
    required List<String> studentIds,
  }) async {
    try {
      debugPrint('📤 Calling returnQuizGrades Cloud Function');
      debugPrint('📋 Quiz: $quizId');
      debugPrint('👥 Students: ${studentIds.length}');

      final callable = _functions.httpsCallable('returnQuizGrades');

      final result = await callable.call<Map<String, dynamic>>({
        'quizId': quizId,
        'courseId': courseId,
        'studentIds': studentIds,
      });

      debugPrint('✅ Cloud Function result: ${result.data}');

      return result.data ?? {'success': false, 'message': 'No data returned'};
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ FirebaseFunctionsException: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': e.message ?? 'Unknown error',
        'code': e.code,
      };
    } catch (e) {
      debugPrint('❌ Error calling returnQuizGrades: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
