const admin = require('firebase-admin');

class QuizAttempt {
  constructor(data) {
    this.id = data.id || null;
    this.quizId = data.quizId || '';
    this.studentId = data.studentId || '';
    this.studentName = data.studentName || '';
    this.courseId = data.courseId || '';
    this.answers = data.answers || {};
    this.score = data.score || 0;
    this.maxScore = data.maxScore || 0;
    this.timeSpent = data.timeSpent || 0; // minutes
    this.attemptNumber = data.attemptNumber || 1;
    this.startedAt = data.startedAt || new Date();
    this.submittedAt = data.submittedAt || null;
    this.status = data.status || 'in_progress';
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Tạo attempt mới
  static async create(attemptData) {
    try {
      const db = admin.firestore();
      const attemptRef = await db.collection('quiz_attempts').add({
        ...attemptData,
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id: attemptRef.id, ...attemptData };
    } catch (error) {
      throw new Error(`Error creating quiz attempt: ${error.message}`);
    }
  }

  // Lấy attempt theo ID
  static async findById(id) {
    try {
      const db = admin.firestore();
      const attemptDoc = await db.collection('quiz_attempts').doc(id).get();
      if (!attemptDoc.exists) {
        return null;
      }
      return { id: attemptDoc.id, ...attemptDoc.data() };
    } catch (error) {
      throw new Error(`Error finding quiz attempt: ${error.message}`);
    }
  }

  // Lấy tất cả attempts
  static async findAll(filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('quiz_attempts');
      
      // Apply filters
      if (filters.quizId) {
        query = query.where('quizId', '==', filters.quizId);
      }
      if (filters.studentId) {
        query = query.where('studentId', '==', filters.studentId);
      }
      if (filters.courseId) {
        query = query.where('courseId', '==', filters.courseId);
      }
      if (filters.status) {
        query = query.where('status', '==', filters.status);
      }
      
      const attemptsSnapshot = await query.get();
      return attemptsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding quiz attempts: ${error.message}`);
    }
  }

  // Lấy attempts theo quiz
  static async findByQuiz(quizId) {
    try {
      const db = admin.firestore();
      const attemptsSnapshot = await db.collection('quiz_attempts')
        .where('quizId', '==', quizId)
        .orderBy('submittedAt', 'desc')
        .get();
      
      return attemptsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding attempts by quiz: ${error.message}`);
    }
  }

  // Lấy attempts theo student
  static async findByStudent(studentId, courseId = null) {
    try {
      const db = admin.firestore();
      let query = db.collection('quiz_attempts').where('studentId', '==', studentId);
      
      if (courseId) {
        query = query.where('courseId', '==', courseId);
      }
      
      const attemptsSnapshot = await query.orderBy('submittedAt', 'desc').get();
      return attemptsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding attempts by student: ${error.message}`);
    }
  }

  // Lấy attempts của student cho quiz cụ thể
  static async findByStudentAndQuiz(studentId, quizId) {
    try {
      const db = admin.firestore();
      const attemptsSnapshot = await db.collection('quiz_attempts')
        .where('studentId', '==', studentId)
        .where('quizId', '==', quizId)
        .orderBy('attemptNumber', 'desc')
        .get();
      
      return attemptsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding attempts by student and quiz: ${error.message}`);
    }
  }

  // Lấy attempt hiện tại của student (in_progress)
  static async findCurrentAttempt(studentId, quizId) {
    try {
      const db = admin.firestore();
      const attemptsSnapshot = await db.collection('quiz_attempts')
        .where('studentId', '==', studentId)
        .where('quizId', '==', quizId)
        .where('status', '==', 'in_progress')
        .limit(1)
        .get();
      
      if (attemptsSnapshot.empty) {
        return null;
      }
      
      const attemptDoc = attemptsSnapshot.docs[0];
      return { id: attemptDoc.id, ...attemptDoc.data() };
    } catch (error) {
      throw new Error(`Error finding current attempt: ${error.message}`);
    }
  }

  // Cập nhật attempt
  static async update(id, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('quiz_attempts').doc(id).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, ...updateData };
    } catch (error) {
      throw new Error(`Error updating quiz attempt: ${error.message}`);
    }
  }

  // Submit attempt
  static async submit(id, answers, timeSpent) {
    try {
      const db = admin.firestore();
      
      // Calculate score
      const attemptDoc = await db.collection('quiz_attempts').doc(id).get();
      if (!attemptDoc.exists) {
        throw new Error('Attempt not found');
      }
      
      const attempt = attemptDoc.data();
      const quizDoc = await db.collection('quizzes').doc(attempt.quizId).get();
      const quiz = quizDoc.data();
      
      // Get questions for scoring
      const questionsSnapshot = await db.collection('quiz_questions')
        .where('quizId', '==', attempt.quizId)
        .get();
      
      let score = 0;
      let maxScore = 0;
      
      questionsSnapshot.docs.forEach(questionDoc => {
        const question = questionDoc.data();
        maxScore += question.points;
        
        const studentAnswer = answers[questionDoc.id];
        if (studentAnswer === question.correctAnswer) {
          score += question.points;
        }
      });
      
      await db.collection('quiz_attempts').doc(id).update({
        answers,
        score,
        maxScore,
        timeSpent,
        submittedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'completed',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { id, score, maxScore, timeSpent };
    } catch (error) {
      throw new Error(`Error submitting quiz attempt: ${error.message}`);
    }
  }

  // Xóa attempt
  static async delete(id) {
    try {
      const db = admin.firestore();
      await db.collection('quiz_attempts').doc(id).delete();
      return { id };
    } catch (error) {
      throw new Error(`Error deleting quiz attempt: ${error.message}`);
    }
  }

  // Lấy thống kê attempts của quiz
  static async getQuizStats(quizId) {
    try {
      const db = admin.firestore();
      const attemptsSnapshot = await db.collection('quiz_attempts')
        .where('quizId', '==', quizId)
        .where('status', '==', 'completed')
        .get();
      
      const attempts = attemptsSnapshot.docs.map(doc => doc.data());
      
      if (attempts.length === 0) {
        return {
          totalAttempts: 0,
          averageScore: 0,
          highestScore: 0,
          lowestScore: 0
        };
      }
      
      const scores = attempts.map(attempt => attempt.score);
      const totalAttempts = attempts.length;
      const averageScore = scores.reduce((sum, score) => sum + score, 0) / totalAttempts;
      const highestScore = Math.max(...scores);
      const lowestScore = Math.min(...scores);
      
      return {
        totalAttempts,
        averageScore: Math.round(averageScore * 100) / 100,
        highestScore,
        lowestScore
      };
    } catch (error) {
      throw new Error(`Error getting quiz stats: ${error.message}`);
    }
  }
}

module.exports = QuizAttempt;




