const admin = require('firebase-admin');

class Quiz {
  constructor(data) {
    this.id = data.id || null;
    this.title = data.title || '';
    this.description = data.description || '';
    this.courseId = data.courseId || '';
    this.courseName = data.courseName || '';
    this.teacherId = data.teacherId || '';
    this.teacherName = data.teacherName || '';
    this.duration = data.duration || 60; // minutes
    this.maxAttempts = data.maxAttempts || 1;
    this.dueDate = data.dueDate || new Date();
    this.startDate = data.startDate || new Date();
    this.endDate = data.endDate || new Date();
    this.questions = data.questions || [];
    this.totalQuestions = data.totalQuestions || 0;
    this.maxPoints = data.maxPoints || 100;
    this.isPublished = data.isPublished !== undefined ? data.isPublished : false;
    this.isRandomized = data.isRandomized !== undefined ? data.isRandomized : false;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Tạo quiz mới
  static async create(quizData) {
    try {
      const db = admin.firestore();
      const quizRef = await db.collection('quizzes').add({
        ...quizData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id: quizRef.id, ...quizData };
    } catch (error) {
      throw new Error(`Error creating quiz: ${error.message}`);
    }
  }

  // Lấy quiz theo ID
  static async findById(id) {
    try {
      const db = admin.firestore();
      const quizDoc = await db.collection('quizzes').doc(id).get();
      if (!quizDoc.exists) {
        return null;
      }
      return { id: quizDoc.id, ...quizDoc.data() };
    } catch (error) {
      throw new Error(`Error finding quiz: ${error.message}`);
    }
  }

  // Lấy tất cả quizzes
  static async findAll(filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('quizzes');
      
      // Apply filters
      if (filters.courseId) {
        query = query.where('courseId', '==', filters.courseId);
      }
      if (filters.teacherId) {
        query = query.where('teacherId', '==', filters.teacherId);
      }
      if (filters.isPublished !== undefined) {
        query = query.where('isPublished', '==', filters.isPublished);
      }
      
      const quizzesSnapshot = await query.get();
      return quizzesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding quizzes: ${error.message}`);
    }
  }

  // Lấy quizzes theo course
  static async findByCourse(courseId) {
    try {
      const db = admin.firestore();
      const quizzesSnapshot = await db.collection('quizzes')
        .where('courseId', '==', courseId)
        .orderBy('createdAt', 'desc')
        .get();
      
      return quizzesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding quizzes by course: ${error.message}`);
    }
  }

  // Lấy quizzes theo teacher
  static async findByTeacher(teacherId) {
    try {
      const db = admin.firestore();
      const quizzesSnapshot = await db.collection('quizzes')
        .where('teacherId', '==', teacherId)
        .orderBy('createdAt', 'desc')
        .get();
      
      return quizzesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding quizzes by teacher: ${error.message}`);
    }
  }

  // Lấy quizzes với attempt info cho student
  static async findByStudent(studentId, courseId = null) {
    try {
      const db = admin.firestore();
      let query = db.collection('quizzes');
      
      if (courseId) {
        query = query.where('courseId', '==', courseId);
      }
      
      const quizzesSnapshot = await query.get();
      const quizzes = quizzesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      // Lấy attempts của student
      const attemptsSnapshot = await db.collection('quiz_attempts')
        .where('studentId', '==', studentId)
        .get();
      
      const attempts = attemptsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      // Kết hợp quizzes với attempts
      return quizzes.map(quiz => {
        const quizAttempts = attempts.filter(attempt => attempt.quizId === quiz.id);
        return {
          ...quiz,
          myAttempts: quizAttempts
        };
      });
    } catch (error) {
      throw new Error(`Error finding quizzes by student: ${error.message}`);
    }
  }

  // Cập nhật quiz
  static async update(id, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('quizzes').doc(id).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, ...updateData };
    } catch (error) {
      throw new Error(`Error updating quiz: ${error.message}`);
    }
  }

  // Xóa quiz
  static async delete(id) {
    try {
      const db = admin.firestore();
      await db.collection('quizzes').doc(id).delete();
      return { id };
    } catch (error) {
      throw new Error(`Error deleting quiz: ${error.message}`);
    }
  }

  // Publish quiz
  static async publish(id) {
    try {
      const db = admin.firestore();
      await db.collection('quizzes').doc(id).update({
        isPublished: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, isPublished: true };
    } catch (error) {
      throw new Error(`Error publishing quiz: ${error.message}`);
    }
  }

  // Unpublish quiz
  static async unpublish(id) {
    try {
      const db = admin.firestore();
      await db.collection('quizzes').doc(id).update({
        isPublished: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, isPublished: false };
    } catch (error) {
      throw new Error(`Error unpublishing quiz: ${error.message}`);
    }
  }
}

module.exports = Quiz;




