const admin = require('firebase-admin');

class Assignment {
  constructor(data) {
    this.id = data.id || null;
    this.title = data.title || '';
    this.description = data.description || '';
    this.courseId = data.courseId || '';
    this.courseName = data.courseName || '';
    this.teacherId = data.teacherId || '';
    this.teacherName = data.teacherName || '';
    this.dueDate = data.dueDate || new Date();
    this.maxPoints = data.maxPoints || 100;
    this.instructions = data.instructions || '';
    this.attachments = data.attachments || [];
    this.allowedFileTypes = data.allowedFileTypes || ['pdf', 'doc', 'docx'];
    this.maxFileSize = data.maxFileSize || 10; // MB
    this.isPublished = data.isPublished !== undefined ? data.isPublished : false;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Tạo assignment mới
  static async create(assignmentData) {
    try {
      const db = admin.firestore();
      const assignmentRef = await db.collection('assignments').add({
        ...assignmentData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id: assignmentRef.id, ...assignmentData };
    } catch (error) {
      throw new Error(`Error creating assignment: ${error.message}`);
    }
  }

  // Lấy assignment theo ID
  static async findById(id) {
    try {
      const db = admin.firestore();
      const assignmentDoc = await db.collection('assignments').doc(id).get();
      if (!assignmentDoc.exists) {
        return null;
      }
      return { id: assignmentDoc.id, ...assignmentDoc.data() };
    } catch (error) {
      throw new Error(`Error finding assignment: ${error.message}`);
    }
  }

  // Lấy tất cả assignments
  static async findAll(filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('assignments');
      
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
      
      const assignmentsSnapshot = await query.get();
      return assignmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding assignments: ${error.message}`);
    }
  }

  // Lấy assignments theo course
  static async findByCourse(courseId) {
    try {
      const db = admin.firestore();
      const assignmentsSnapshot = await db.collection('assignments')
        .where('courseId', '==', courseId)
        .orderBy('createdAt', 'desc')
        .get();
      
      return assignmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding assignments by course: ${error.message}`);
    }
  }

  // Lấy assignments theo teacher
  static async findByTeacher(teacherId) {
    try {
      const db = admin.firestore();
      const assignmentsSnapshot = await db.collection('assignments')
        .where('teacherId', '==', teacherId)
        .orderBy('createdAt', 'desc')
        .get();
      
      return assignmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding assignments by teacher: ${error.message}`);
    }
  }

  // Lấy assignments với submission info cho student
  static async findByStudent(studentId, courseId = null) {
    try {
      const db = admin.firestore();
      let query = db.collection('assignments');
      
      if (courseId) {
        query = query.where('courseId', '==', courseId);
      }
      
      const assignmentsSnapshot = await query.get();
      const assignments = assignmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      // Lấy submissions của student
      const submissionsSnapshot = await db.collection('submissions')
        .where('studentId', '==', studentId)
        .get();
      
      const submissions = submissionsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      // Kết hợp assignments với submissions
      return assignments.map(assignment => {
        const submission = submissions.find(sub => sub.assignmentId === assignment.id);
        return {
          ...assignment,
          mySubmission: submission || null
        };
      });
    } catch (error) {
      throw new Error(`Error finding assignments by student: ${error.message}`);
    }
  }

  // Cập nhật assignment
  static async update(id, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('assignments').doc(id).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, ...updateData };
    } catch (error) {
      throw new Error(`Error updating assignment: ${error.message}`);
    }
  }

  // Xóa assignment
  static async delete(id) {
    try {
      const db = admin.firestore();
      await db.collection('assignments').doc(id).delete();
      return { id };
    } catch (error) {
      throw new Error(`Error deleting assignment: ${error.message}`);
    }
  }

  // Publish assignment
  static async publish(id) {
    try {
      const db = admin.firestore();
      await db.collection('assignments').doc(id).update({
        isPublished: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, isPublished: true };
    } catch (error) {
      throw new Error(`Error publishing assignment: ${error.message}`);
    }
  }

  // Unpublish assignment
  static async unpublish(id) {
    try {
      const db = admin.firestore();
      await db.collection('assignments').doc(id).update({
        isPublished: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, isPublished: false };
    } catch (error) {
      throw new Error(`Error unpublishing assignment: ${error.message}`);
    }
  }
}

module.exports = Assignment;




