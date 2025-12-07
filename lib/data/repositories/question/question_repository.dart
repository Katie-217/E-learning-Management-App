// ========================================
// FILE: question_repository.dart
// MÔ TẢ: Repository quản lý ngân hàng câu hỏi
// LOGIC: Query theo courseCode để tái sử dụng giữa các học kỳ
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/domain/models/question_model.dart';

class QuestionRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'questions';

  // ========================================
  // HÀM: streamQuestionsByCourseCode()
  // MÔ TẢ: Lắng nghe real-time câu hỏi theo courseCode
  // QUAN TRỌNG: Query theo courseCode, KHÔNG phải courseId
  // ========================================
  static Stream<List<QuestionModel>> streamQuestionsByCourseCode(
      String courseCode) {
    return _firestore
        .collection(_collectionName)
        .where('courseCode', isEqualTo: courseCode)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => QuestionModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    });
  }

  // ========================================
  // HÀM: addQuestion()
  // MÔ TẢ: Thêm câu hỏi mới
  // ========================================
  static Future<String> addQuestion(QuestionModel question) async {
    try {
      // Remove id field before adding (let Firestore auto-generate)
      final data = question.toMap();
      data.remove('id');

      final docRef = await _firestore.collection(_collectionName).add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add question: $e');
    }
  }

  // ========================================
  // HÀM: updateQuestion()
  // MÔ TẢ: Cập nhật câu hỏi
  // ========================================
  static Future<void> updateQuestion(QuestionModel question) async {
    try {
      await _firestore.collection(_collectionName).doc(question.id).update({
        ...question.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update question: $e');
    }
  }

  // ========================================
  // HÀM: deleteQuestion()
  // MÔ TẢ: Xóa mềm câu hỏi (set isActive = false)
  // Câu hỏi vẫn tồn tại trong database nhưng không hiển thị
  // ========================================
  static Future<void> deleteQuestion(String questionId) async {
    try {
      // Soft delete - Set isActive = false
      await _firestore.collection(_collectionName).doc(questionId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete question: $e');
    }
  }

  // ========================================
  // HÀM: hardDeleteQuestion()
  // MÔ TẢ: Xóa vĩnh viễn câu hỏi khỏi database
  // CẢNH BÁO: Không thể khôi phục sau khi xóa!
  // ========================================
  static Future<void> hardDeleteQuestion(String questionId) async {
    try {
      await _firestore.collection(_collectionName).doc(questionId).delete();
    } catch (e) {
      throw Exception('Failed to permanently delete question: $e');
    }
  }

  // ========================================
  // HÀM: getQuestionById()
  // MÔ TẢ: Lấy 1 câu hỏi theo ID
  // ========================================
  static Future<QuestionModel?> getQuestionById(String questionId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(questionId).get();

      if (!doc.exists) return null;

      return QuestionModel.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      throw Exception('Failed to get question: $e');
    }
  }

  // ========================================
  // HÀM: getQuestionsByDifficulty()
  // MÔ TẢ: Lấy câu hỏi theo courseCode và độ khó
  // ========================================
  static Future<List<QuestionModel>> getQuestionsByDifficulty(
      String courseCode, QuestionDifficulty difficulty) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('courseCode', isEqualTo: courseCode)
          .where('difficulty', isEqualTo: difficulty.name)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => QuestionModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get questions by difficulty: $e');
    }
  }

  // ========================================
  // HÀM: incrementUsageCount()
  // MÔ TẢ: Tăng số lần sử dụng câu hỏi
  // ========================================
  static Future<void> incrementUsageCount(String questionId) async {
    try {
      await _firestore.collection(_collectionName).doc(questionId).update({
        'usageCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment usage count: $e');
    }
  }

  // ========================================
  // HÀM: searchQuestions()
  // MÔ TẢ: Tìm kiếm câu hỏi theo text (client-side)
  // ========================================
  static Stream<List<QuestionModel>> searchQuestions(
      String courseCode, String searchQuery) {
    return streamQuestionsByCourseCode(courseCode).map((questions) {
      if (searchQuery.isEmpty) return questions;

      final lowerQuery = searchQuery.toLowerCase();
      return questions
          .where((q) => q.question.toLowerCase().contains(lowerQuery))
          .toList();
    });
  }

  // ========================================
  // HÀM: getQuestionCount()
  // ========================================
  // HÀM: getQuestionCount()
  // MÔ TẢ: Đếm số câu hỏi theo courseCode
  // ========================================
  static Future<int> getQuestionCount(String courseCode) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('courseCode', isEqualTo: courseCode)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get question count: $e');
    }
  }

  // ========================================
  // HÀM: getQuestionCountByDifficulty()
  // MÔ TẢ: Đếm số câu hỏi theo courseCode và difficulty
  // RETURN: Map<String, int> {'easy': 50, 'medium': 30, 'hard': 20}
  // ========================================
  static Future<Map<String, int>> getQuestionCountByDifficulty(
      String courseCode) async {
    try {
      final counts = <String, int>{};

      for (final difficulty in ['easy', 'medium', 'hard']) {
        final snapshot = await _firestore
            .collection(_collectionName)
            .where('courseCode', isEqualTo: courseCode)
            .where('difficulty', isEqualTo: difficulty)
            .where('isActive', isEqualTo: true)
            .count()
            .get();

        counts[difficulty] = snapshot.count ?? 0;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get question count by difficulty: $e');
    }
  }
}
