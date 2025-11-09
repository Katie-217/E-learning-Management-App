const admin = require('firebase-admin');

class Submission {
  constructor(data) {
    this.id = data.id || null;
    this.assignmentId = data.assignmentId || '';
    this.studentId = data.studentId || '';
    this.studentName = data.studentName || '';
    this.courseId = data.courseId || '';
    this.content = data.content || '';
    this.attachments = data.attachments || [];
    this.submittedAt = data.submittedAt || new Date();
    this.grade = data.grade || null;
    this.feedback = data.feedback || '';
    this.gradedAt = data.gradedAt || null;
    this.gradedBy = data.gradedBy || '';
    this.status = data.status || 'submitted';
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Tạo submission mới
  static async create(submissionData) {
    try {
      const db = admin.firestore();
      const submissionRef = await db.collection('submissions').add({
        ...submissionData,
        submittedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id: submissionRef.id, ...submissionData };
    } catch (error) {
      throw new Error(`Error creating submission: ${error.message}`);
    }
  }

  // Lấy submission theo ID
  static async findById(id) {
    try {
      const db = admin.firestore();
      const submissionDoc = await db.collection('submissions').doc(id).get();
      if (!submissionDoc.exists) {
        return null;
      }
      return { id: submissionDoc.id, ...submissionDoc.data() };
    } catch (error) {
      throw new Error(`Error finding submission: ${error.message}`);
    }
  }

  // Lấy tất cả submissions
  static async findAll(filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('submissions');
      
      // Apply filters
      if (filters.assignmentId) {
        query = query.where('assignmentId', '==', filters.assignmentId);
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
      
      const submissionsSnapshot = await query.get();
      return submissionsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding submissions: ${error.message}`);
    }
  }

  // Lấy submissions theo assignment
  static async findByAssignment(assignmentId) {
    try {
      const db = admin.firestore();
      const submissionsSnapshot = await db.collection('submissions')
        .where('assignmentId', '==', assignmentId)
        .orderBy('submittedAt', 'desc')
        .get();
      
      return submissionsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding submissions by assignment: ${error.message}`);
    }
  }

  // Lấy submissions theo student
  static async findByStudent(studentId, courseId = null) {
    try {
      const db = admin.firestore();
      let query = db.collection('submissions').where('studentId', '==', studentId);
      
      if (courseId) {
        query = query.where('courseId', '==', courseId);
      }
      
      const submissionsSnapshot = await query.orderBy('submittedAt', 'desc').get();
      return submissionsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding submissions by student: ${error.message}`);
    }
  }

  // Lấy submission của student cho assignment cụ thể
  static async findByStudentAndAssignment(studentId, assignmentId) {
    try {
      const db = admin.firestore();
      const submissionsSnapshot = await db.collection('submissions')
        .where('studentId', '==', studentId)
        .where('assignmentId', '==', assignmentId)
        .limit(1)
        .get();
      
      if (submissionsSnapshot.empty) {
        return null;
      }
      
      const submissionDoc = submissionsSnapshot.docs[0];
      return { id: submissionDoc.id, ...submissionDoc.data() };
    } catch (error) {
      throw new Error(`Error finding submission by student and assignment: ${error.message}`);
    }
  }

  // Cập nhật submission
  static async update(id, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('submissions').doc(id).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, ...updateData };
    } catch (error) {
      throw new Error(`Error updating submission: ${error.message}`);
    }
  }

  // Xóa submission
  static async delete(id) {
    try {
      const db = admin.firestore();
      await db.collection('submissions').doc(id).delete();
      return { id };
    } catch (error) {
      throw new Error(`Error deleting submission: ${error.message}`);
    }
  }

  // Grade submission
  static async grade(id, gradeData) {
    try {
      const db = admin.firestore();
      await db.collection('submissions').doc(id).update({
        grade: gradeData.grade,
        feedback: gradeData.feedback,
        gradedAt: admin.firestore.FieldValue.serverTimestamp(),
        gradedBy: gradeData.gradedBy,
        status: 'graded',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, ...gradeData };
    } catch (error) {
      throw new Error(`Error grading submission: ${error.message}`);
    }
  }

  // Lấy submissions chưa được grade
  static async findUngraded(teacherId) {
    try {
      const db = admin.firestore();
      const submissionsSnapshot = await db.collection('submissions')
        .where('status', '==', 'submitted')
        .get();
      
      // Filter by teacher's assignments
      const teacherAssignmentsSnapshot = await db.collection('assignments')
        .where('teacherId', '==', teacherId)
        .get();
      
      const teacherAssignmentIds = teacherAssignmentsSnapshot.docs.map(doc => doc.id);
      
      return submissionsSnapshot.docs
        .map(doc => ({ id: doc.id, ...doc.data() }))
        .filter(submission => teacherAssignmentIds.includes(submission.assignmentId));
    } catch (error) {
      throw new Error(`Error finding ungraded submissions: ${error.message}`);
    }
  }
}

module.exports = Submission;




