// ========================================
// FILE: quiz_submission_repository.dart
// MÔ TẢ: Repository for quiz submissions (CRUD operations)
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/domain/models/quiz_submission_model.dart';
import 'package:cloud_functions/cloud_functions.dart';

class QuizSubmissionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ========================================
  // START QUIZ (Call Cloud Function)
  // ========================================
  Future<Map<String, dynamic>> startQuiz({
    required String quizId,
    required String courseId,
  }) async {
    try {
      final callable = _functions.httpsCallable('startQuiz');
      final result = await callable.call({
        'quizId': quizId,
        'courseId': courseId,
      });

      return {
        'success': result.data['success'],
        'submissionId': result.data['submissionId'],
        'questions': result.data['questions'],
        'attemptNumber': result.data['attemptNumber'],
        'maxAttempts': result.data['maxAttempts'],
        'durationMinutes': result.data['durationMinutes'],
        'message': result.data['message'],
      };
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Failed to start quiz: ${e.message}');
    } catch (e) {
      throw Exception('Failed to start quiz: $e');
    }
  }

  // ========================================
  // GET SUBMISSION
  // ========================================
  Future<QuizSubmissionModel?> getSubmission(String submissionId) async {
    try {
      final doc = await _firestore
          .collection('quiz_submissions')
          .doc(submissionId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = {
        'id': doc.id,
        ...doc.data()!,
      };

      print('📄 Submission data: ${data.keys}');
      print('📄 Questions type: ${data['questions'].runtimeType}');

      return QuizSubmissionModel.fromMap(data);
    } catch (e, stackTrace) {
      print('❌ Error in getSubmission: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Failed to get submission: $e');
    }
  }

  // ========================================
  // STREAM SUBMISSION (Real-time)
  // ========================================
  Stream<QuizSubmissionModel?> streamSubmission(String submissionId) {
    return _firestore
        .collection('quiz_submissions')
        .doc(submissionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return null;
      }

      try {
        final data = {
          'id': doc.id,
          ...doc.data()!,
        };

        print('📡 Streaming submission data keys: ${data.keys}');

        return QuizSubmissionModel.fromMap(data);
      } catch (e, stackTrace) {
        print('❌ Error parsing submission stream: $e');
        print('📍 Stack trace: $stackTrace');
        print('📄 Raw data: ${doc.data()}');
        rethrow;
      }
    });
  }

  // ========================================
  // UPDATE ANSWER
  // ========================================
  Future<void> updateAnswer({
    required String submissionId,
    required String questionId,
    required int answerIndex,
  }) async {
    try {
      await _firestore.collection('quiz_submissions').doc(submissionId).update({
        'answers.$questionId': answerIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update answer: $e');
    }
  }

  // ========================================
  // SUBMIT QUIZ (Calculate score and mark as completed)
  // ========================================
  Future<double> submitQuiz({
    required String submissionId,
    required bool isAutoSubmitted,
  }) async {
    try {
      // Get submission data
      final submission = await getSubmission(submissionId);
      if (submission == null) {
        throw Exception('Submission not found');
      }

      // Calculate score
      int correctCount = 0;
      for (final question in submission.questions) {
        final selectedAnswer = submission.answers[question.id];
        if (selectedAnswer != null &&
            selectedAnswer == question.correctAnswer) {
          correctCount++;
        }
      }

      final totalQuestions = submission.questions.length;
      final score =
          totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;

      // Calculate time spent
      final now = DateTime.now();
      final timeSpent = now.difference(submission.startedAt).inSeconds;

      // Update submission
      await _firestore.collection('quiz_submissions').doc(submissionId).update({
        'submittedAt': FieldValue.serverTimestamp(),
        'score': score,
        'status': 'completed',
        'isAutoSubmitted': isAutoSubmitted,
        'timeSpentSeconds': timeSpent,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ========================================
      // NEW: Update Quiz Tracker status to 'completed'
      // ========================================
      try {
        final compositeId = '${submission.quizId}_${submission.studentId}';
        final trackerRef =
            _firestore.collection('quiz_trackers').doc(compositeId);

        // Get current tracker to check best score
        final trackerDoc = await trackerRef.get();
        final trackerData = trackerDoc.data();
        final currentBestScore = trackerData != null
            ? (trackerData['score'] as num?)?.toDouble()
            : null;

        // Update with best score
        final bestScore = currentBestScore != null
            ? (score > currentBestScore ? score : currentBestScore)
            : score;

        // Get attemptNumber from the submission document (already incremented by startQuiz)
        // DO NOT increment here - attemptCount should equal the last attemptNumber
        final submissionDoc = await _firestore
            .collection('quiz_submissions')
            .doc(submissionId)
            .get();
        final attemptNumber =
            submissionDoc.data()?['attemptNumber'] as int? ?? 1;

        await trackerRef.update({
          'status': 'completed',
          'score': bestScore,
          'attemptCount':
              attemptNumber, // Use attemptNumber from submission, not increment
          'completedAt': FieldValue.serverTimestamp(),
          'lastAttemptAt': FieldValue.serverTimestamp(),
          'lastSubmissionId': submissionId,
        });
      } catch (trackerError) {
        // Non-critical: Don't throw if tracker update fails
        print('⚠️ Failed to update quiz tracker: $trackerError');
      }

      return score;
    } catch (e) {
      throw Exception('Failed to submit quiz: $e');
    }
  }

  // ========================================
  // GET STUDENT ATTEMPTS
  // ========================================
  Future<List<QuizSubmissionModel>> getStudentAttempts({
    required String quizId,
    required String studentId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('quiz_submissions')
          .where('quizId', isEqualTo: quizId)
          .where('studentId', isEqualTo: studentId)
          .orderBy('startedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return QuizSubmissionModel.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get student attempts: $e');
    }
  }

  // ========================================
  // GET IN-PROGRESS SUBMISSION
  // ========================================
  Future<QuizSubmissionModel?> getInProgressSubmission({
    required String quizId,
    required String studentId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('quiz_submissions')
          .where('quizId', isEqualTo: quizId)
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'in_progress')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return QuizSubmissionModel.fromMap({
        'id': doc.id,
        ...doc.data(),
      });
    } catch (e) {
      throw Exception('Failed to get in-progress submission: $e');
    }
  }

  // ========================================
  // COUNT COMPLETED ATTEMPTS
  // ========================================
  Future<int> countCompletedAttempts({
    required String quizId,
    required String studentId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('quiz_submissions')
          .where('quizId', isEqualTo: quizId)
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'completed')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to count attempts: $e');
    }
  }

  // ========================================
  // DELETE SUBMISSION
  // ========================================
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _firestore
          .collection('quiz_submissions')
          .doc(submissionId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete submission: $e');
    }
  }
}
