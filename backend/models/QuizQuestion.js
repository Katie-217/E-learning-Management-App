const admin = require('firebase-admin');

class QuizQuestion {
  constructor(data) {
    this.id = data.id || null;
    this.quizId = data.quizId || '';
    this.question = data.question || '';
    this.questionType = data.questionType || 'multiple_choice';
    this.options = data.options || [];
    this.correctAnswer = data.correctAnswer || '';
    this.points = data.points || 1;
    this.order = data.order || 0;
    this.explanation = data.explanation || '';
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Tạo question mới
  static async create(questionData) {
    try {
      const db = admin.firestore();
      const questionRef = await db.collection('quiz_questions').add({
        ...questionData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id: questionRef.id, ...questionData };
    } catch (error) {
      throw new Error(`Error creating quiz question: ${error.message}`);
    }
  }

  // Lấy question theo ID
  static async findById(id) {
    try {
      const db = admin.firestore();
      const questionDoc = await db.collection('quiz_questions').doc(id).get();
      if (!questionDoc.exists) {
        return null;
      }
      return { id: questionDoc.id, ...questionDoc.data() };
    } catch (error) {
      throw new Error(`Error finding quiz question: ${error.message}`);
    }
  }

  // Lấy questions theo quiz
  static async findByQuiz(quizId) {
    try {
      const db = admin.firestore();
      const questionsSnapshot = await db.collection('quiz_questions')
        .where('quizId', '==', quizId)
        .orderBy('order', 'asc')
        .get();
      
      return questionsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding questions by quiz: ${error.message}`);
    }
  }

  // Lấy tất cả questions
  static async findAll(filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('quiz_questions');
      
      // Apply filters
      if (filters.quizId) {
        query = query.where('quizId', '==', filters.quizId);
      }
      if (filters.questionType) {
        query = query.where('questionType', '==', filters.questionType);
      }
      
      const questionsSnapshot = await query.get();
      return questionsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding quiz questions: ${error.message}`);
    }
  }

  // Cập nhật question
  static async update(id, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('quiz_questions').doc(id).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, ...updateData };
    } catch (error) {
      throw new Error(`Error updating quiz question: ${error.message}`);
    }
  }

  // Xóa question
  static async delete(id) {
    try {
      const db = admin.firestore();
      await db.collection('quiz_questions').doc(id).delete();
      return { id };
    } catch (error) {
      throw new Error(`Error deleting quiz question: ${error.message}`);
    }
  }

  // Xóa tất cả questions của quiz
  static async deleteByQuiz(quizId) {
    try {
      const db = admin.firestore();
      const questionsSnapshot = await db.collection('quiz_questions')
        .where('quizId', '==', quizId)
        .get();
      
      const batch = db.batch();
      questionsSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      await batch.commit();
      return { deletedCount: questionsSnapshot.docs.length };
    } catch (error) {
      throw new Error(`Error deleting questions by quiz: ${error.message}`);
    }
  }

  // Tạo nhiều questions cùng lúc
  static async createBatch(questionsData) {
    try {
      const db = admin.firestore();
      const batch = db.batch();
      const questionRefs = [];
      
      questionsData.forEach(questionData => {
        const questionRef = db.collection('quiz_questions').doc();
        batch.set(questionRef, {
          ...questionData,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        questionRefs.push(questionRef);
      });
      
      await batch.commit();
      return questionRefs.map(ref => ({ id: ref.id }));
    } catch (error) {
      throw new Error(`Error creating batch questions: ${error.message}`);
    }
  }
}

module.exports = QuizQuestion;




