import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/domain/models/quiz_model.dart';

class QuizRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // CREATE QUIZ
  // ========================================
  Future<String> createQuiz({
    required String courseId,
    required String title,
    required String description,
    required DateTime openDate,
    required DateTime closeDate,
    required int durationMinutes,
    required int maxAttempts,
    required double points,
    required Map<String, int> structure,
    required bool shuffleAnswers,
    required bool showScore,
    required List<String> selectedGroups,
  }) async {
    try {
      final totalQuestions =
          structure.values.fold<int>(0, (sum, count) => sum + count);

      final quizData = {
        'courseId': courseId,
        'title': title,
        'description': description,
        'openDate': openDate.toIso8601String(),
        'closeDate': closeDate.toIso8601String(),
        'durationMinutes': durationMinutes,
        'maxAttempts': maxAttempts,
        'points': points,
        'structure': structure,
        'questions': totalQuestions,
        'shuffleAnswers': shuffleAnswers,
        'showScore': showScore,
        'groupIds': selectedGroups, // Store group IDs, not names
        'status': _calculateStatus(openDate, closeDate),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('quizzes').add(quizData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create quiz: $e');
    }
  }

  // ========================================
  // STREAM QUIZZES BY COURSE
  // ========================================
  Stream<List<Quiz>> streamQuizzesByCourse(String courseId) {
    print('🔄 DEBUG: Streaming quizzes for courseId: $courseId');
    return _firestore
        .collection('quizzes')
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📦 DEBUG: Received ${snapshot.docs.length} quiz documents');
      return snapshot.docs.map((doc) {
        print(
            '  📋 Quiz: ${doc.data()['title']}, status: ${doc.data()['status']}');
        return Quiz.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // ========================================
  // GET QUIZ BY ID (for full details)
  // ========================================
  Future<Quiz?> getQuizById(String courseId, String quizId) async {
    try {
      final doc = await _firestore.collection('quizzes').doc(quizId).get();

      if (!doc.exists) return null;

      return Quiz.fromMap(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Failed to get quiz: $e');
    }
  }

  // ========================================
  // UPDATE QUIZ
  // ========================================
  Future<void> updateQuiz({
    required String courseId,
    required String quizId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final updateData = {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('quizzes').doc(quizId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update quiz: $e');
    }
  }

  // ========================================
  // DELETE QUIZ
  // ========================================
  Future<void> deleteQuiz({
    required String courseId,
    required String quizId,
  }) async {
    try {
      await _firestore.collection('quizzes').doc(quizId).delete();
    } catch (e) {
      throw Exception('Failed to delete quiz: $e');
    }
  }

  // ========================================
  // GET QUIZZES BY COURSE
  // ========================================
  Future<List<Quiz>> getQuizzesByCourse(String courseId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Quiz.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to get quizzes by course: $e');
    }
  }

  // ========================================
  // HELPER: Calculate Quiz Status
  // ========================================
  String _calculateStatus(DateTime openDate, DateTime closeDate) {
    final now = DateTime.now();

    if (now.isBefore(openDate)) {
      return 'upcoming';
    } else if (now.isAfter(closeDate)) {
      return 'closed';
    } else {
      return 'available';
    }
  }
}
