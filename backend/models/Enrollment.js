const admin = require('firebase-admin');

class Enrollment {
  constructor(data) {
    this.id = data.id || null;
    this.studentId = data.studentId || '';
    this.studentName = data.studentName || '';
    this.courseId = data.courseId || '';
    this.courseName = data.courseName || '';
    this.teacherId = data.teacherId || '';
    this.teacherName = data.teacherName || '';
    this.enrolledAt = data.enrolledAt || new Date();
    this.status = data.status || 'active';
    this.grade = data.grade || '';
    this.progress = data.progress || 0;
    this.lastAccessed = data.lastAccessed || new Date();
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Tạo enrollment mới
  static async create(enrollmentData) {
    try {
      const db = admin.firestore();
      const enrollmentId = `${enrollmentData.studentId}_${enrollmentData.courseId}`;
      
      await db.collection('enrollments').doc(enrollmentId).set({
        ...enrollmentData,
        enrolledAt: admin.firestore.FieldValue.serverTimestamp(),
        lastAccessed: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { id: enrollmentId, ...enrollmentData };
    } catch (error) {
      throw new Error(`Error creating enrollment: ${error.message}`);
    }
  }

  // Lấy enrollment theo ID
  static async findById(id) {
    try {
      const db = admin.firestore();
      const enrollmentDoc = await db.collection('enrollments').doc(id).get();
      if (!enrollmentDoc.exists) {
        return null;
      }
      return { id: enrollmentDoc.id, ...enrollmentDoc.data() };
    } catch (error) {
      throw new Error(`Error finding enrollment: ${error.message}`);
    }
  }

  // Lấy enrollment theo student và course
  static async findByStudentAndCourse(studentId, courseId) {
    try {
      const db = admin.firestore();
      const enrollmentId = `${studentId}_${courseId}`;
      const enrollmentDoc = await db.collection('enrollments').doc(enrollmentId).get();
      
      if (!enrollmentDoc.exists) {
        return null;
      }
      
      return { id: enrollmentDoc.id, ...enrollmentDoc.data() };
    } catch (error) {
      throw new Error(`Error finding enrollment by student and course: ${error.message}`);
    }
  }

  // Lấy enrollments theo student
  static async findByStudent(studentId, filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('enrollments').where('studentId', '==', studentId);
      
      // Apply filters
      if (filters.status) {
        query = query.where('status', '==', filters.status);
      }
      
      const enrollmentsSnapshot = await query.get();
      return enrollmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding enrollments by student: ${error.message}`);
    }
  }

  // Lấy enrollments theo course
  static async findByCourse(courseId, filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('enrollments').where('courseId', '==', courseId);
      
      // Apply filters
      if (filters.status) {
        query = query.where('status', '==', filters.status);
      }
      
      const enrollmentsSnapshot = await query.get();
      return enrollmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding enrollments by course: ${error.message}`);
    }
  }

  // Lấy enrollments theo teacher
  static async findByTeacher(teacherId, filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('enrollments').where('teacherId', '==', teacherId);
      
      // Apply filters
      if (filters.status) {
        query = query.where('status', '==', filters.status);
      }
      
      const enrollmentsSnapshot = await query.get();
      return enrollmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding enrollments by teacher: ${error.message}`);
    }
  }

  // Lấy tất cả enrollments
  static async findAll(filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('enrollments');
      
      // Apply filters
      if (filters.studentId) {
        query = query.where('studentId', '==', filters.studentId);
      }
      if (filters.courseId) {
        query = query.where('courseId', '==', filters.courseId);
      }
      if (filters.teacherId) {
        query = query.where('teacherId', '==', filters.teacherId);
      }
      if (filters.status) {
        query = query.where('status', '==', filters.status);
      }
      
      const enrollmentsSnapshot = await query.get();
      return enrollmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding enrollments: ${error.message}`);
    }
  }

  // Cập nhật enrollment
  static async update(id, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('enrollments').doc(id).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, ...updateData };
    } catch (error) {
      throw new Error(`Error updating enrollment: ${error.message}`);
    }
  }

  // Xóa enrollment
  static async delete(id) {
    try {
      const db = admin.firestore();
      await db.collection('enrollments').doc(id).delete();
      return { id };
    } catch (error) {
      throw new Error(`Error deleting enrollment: ${error.message}`);
    }
  }

  // Enroll student vào course
  static async enrollStudent(studentId, courseId, studentName, courseName, teacherId, teacherName) {
    try {
      const db = admin.firestore();
      const enrollmentId = `${studentId}_${courseId}`;
      
      // Check if already enrolled
      const existingEnrollment = await this.findByStudentAndCourse(studentId, courseId);
      if (existingEnrollment) {
        throw new Error('Student is already enrolled in this course');
      }
      
      const enrollmentData = {
        studentId,
        studentName,
        courseId,
        courseName,
        teacherId,
        teacherName,
        status: 'active',
        progress: 0
      };
      
      await db.collection('enrollments').doc(enrollmentId).set({
        ...enrollmentData,
        enrolledAt: admin.firestore.FieldValue.serverTimestamp(),
        lastAccessed: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { id: enrollmentId, ...enrollmentData };
    } catch (error) {
      throw new Error(`Error enrolling student: ${error.message}`);
    }
  }

  // Unenroll student khỏi course
  static async unenrollStudent(studentId, courseId) {
    try {
      const db = admin.firestore();
      const enrollmentId = `${studentId}_${courseId}`;
      
      await db.collection('enrollments').doc(enrollmentId).delete();
      return { id: enrollmentId, studentId, courseId };
    } catch (error) {
      throw new Error(`Error unenrolling student: ${error.message}`);
    }
  }

  // Update progress
  static async updateProgress(studentId, courseId, progress) {
    try {
      const db = admin.firestore();
      const enrollmentId = `${studentId}_${courseId}`;
      
      await db.collection('enrollments').doc(enrollmentId).update({
        progress,
        lastAccessed: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { id: enrollmentId, progress };
    } catch (error) {
      throw new Error(`Error updating progress: ${error.message}`);
    }
  }

  // Update grade
  static async updateGrade(studentId, courseId, grade) {
    try {
      const db = admin.firestore();
      const enrollmentId = `${studentId}_${courseId}`;
      
      await db.collection('enrollments').doc(enrollmentId).update({
        grade,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { id: enrollmentId, grade };
    } catch (error) {
      throw new Error(`Error updating grade: ${error.message}`);
    }
  }

  // Complete course
  static async completeCourse(studentId, courseId, grade) {
    try {
      const db = admin.firestore();
      const enrollmentId = `${studentId}_${courseId}`;
      
      await db.collection('enrollments').doc(enrollmentId).update({
        status: 'completed',
        grade,
        progress: 100,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { id: enrollmentId, status: 'completed', grade };
    } catch (error) {
      throw new Error(`Error completing course: ${error.message}`);
    }
  }

  // Drop course
  static async dropCourse(studentId, courseId) {
    try {
      const db = admin.firestore();
      const enrollmentId = `${studentId}_${courseId}`;
      
      await db.collection('enrollments').doc(enrollmentId).update({
        status: 'dropped',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { id: enrollmentId, status: 'dropped' };
    } catch (error) {
      throw new Error(`Error dropping course: ${error.message}`);
    }
  }

  // Lấy thống kê enrollments
  static async getStats(courseId) {
    try {
      const db = admin.firestore();
      const enrollmentsSnapshot = await db.collection('enrollments')
        .where('courseId', '==', courseId)
        .get();
      
      const enrollments = enrollmentsSnapshot.docs.map(doc => doc.data());
      
      const total = enrollments.length;
      const active = enrollments.filter(e => e.status === 'active').length;
      const completed = enrollments.filter(e => e.status === 'completed').length;
      const dropped = enrollments.filter(e => e.status === 'dropped').length;
      
      const averageProgress = enrollments.length > 0 
        ? enrollments.reduce((sum, e) => sum + (e.progress || 0), 0) / enrollments.length 
        : 0;
      
      return {
        total,
        active,
        completed,
        dropped,
        averageProgress: Math.round(averageProgress * 100) / 100
      };
    } catch (error) {
      throw new Error(`Error getting enrollment stats: ${error.message}`);
    }
  }
}

module.exports = Enrollment;
