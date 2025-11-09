const admin = require('firebase-admin');

class Course {
  constructor(data) {
    this.id = data.id || null;
    this.code = data.code || '';
    this.name = data.name || '';
    this.description = data.description || '';
    this.teacherId = data.teacherId || '';
    this.teacherName = data.teacherName || '';
    this.semester = data.semester || '';
    this.year = data.year || new Date().getFullYear();
    this.credits = data.credits || 3;
    this.status = data.status || 'active';
    this.imageUrl = data.imageUrl || '';
    this.startDate = data.startDate || new Date();
    this.endDate = data.endDate || new Date();
    this.group = data.group || '';
    this.sessions = data.sessions || 0;
    this.maxStudents = data.maxStudents || 50;
    this.students = data.students || [];
    this.progress = data.progress || 0;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Tạo course mới
  static async create(courseData) {
    try {
      const db = admin.firestore();
      const courseRef = await db.collection('courses').add({
        ...courseData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id: courseRef.id, ...courseData };
    } catch (error) {
      throw new Error(`Error creating course: ${error.message}`);
    }
  }

  // Lấy course theo ID
  static async findById(id) {
    try {
      const db = admin.firestore();
      const courseDoc = await db.collection('courses').doc(id).get();
      if (!courseDoc.exists) {
        return null;
      }
      return { id: courseDoc.id, ...courseDoc.data() };
    } catch (error) {
      throw new Error(`Error finding course: ${error.message}`);
    }
  }

  // Lấy tất cả courses
  static async findAll(filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('courses');
      
      // Apply filters
      if (filters.semester) {
        query = query.where('semester', '==', filters.semester);
      }
      if (filters.status) {
        query = query.where('status', '==', filters.status);
      }
      if (filters.teacherId) {
        query = query.where('teacherId', '==', filters.teacherId);
      }
      if (filters.year) {
        query = query.where('year', '==', filters.year);
      }
      
      const coursesSnapshot = await query.get();
      return coursesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding courses: ${error.message}`);
    }
  }

  // Lấy courses theo teacher
  static async findByTeacher(teacherId) {
    try {
      const db = admin.firestore();
      const coursesSnapshot = await db.collection('courses')
        .where('teacherId', '==', teacherId)
        .get();
      
      return coursesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding courses by teacher: ${error.message}`);
    }
  }

  // Lấy courses theo student (through enrollments)
  static async findByStudent(studentId) {
    try {
      const db = admin.firestore();
      
      // Lấy enrollments của student
      const enrollmentsSnapshot = await db.collection('enrollments')
        .where('studentId', '==', studentId)
        .where('status', '==', 'active')
        .get();
      
      if (enrollmentsSnapshot.empty) {
        return [];
      }
      
      const courseIds = enrollmentsSnapshot.docs.map(doc => doc.data().courseId);
      
      // Lấy courses
      const coursesSnapshot = await db.collection('courses')
        .where('id', 'in', courseIds)
        .get();
      
      return coursesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding courses by student: ${error.message}`);
    }
  }

  // Lấy course với full data (assignments, quizzes, materials, students, groups)
  static async findByIdWithFullData(id) {
    try {
      const db = admin.firestore();
      
      // Lấy course
      const courseDoc = await db.collection('courses').doc(id).get();
      if (!courseDoc.exists) {
        return null;
      }
      
      const course = { id: courseDoc.id, ...courseDoc.data() };
      
      // Lấy teacher info
      const teacherDoc = await db.collection('users').doc(course.teacherId).get();
      const teacher = teacherDoc.exists ? { uid: teacherDoc.id, ...teacherDoc.data() } : null;
      
      // Lấy assignments
      const assignmentsSnapshot = await db.collection('assignments')
        .where('courseId', '==', id)
        .get();
      const assignments = assignmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      // Lấy quizzes
      const quizzesSnapshot = await db.collection('quizzes')
        .where('courseId', '==', id)
        .get();
      const quizzes = quizzesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      // Lấy materials
      const materialsSnapshot = await db.collection('materials')
        .where('courseId', '==', id)
        .get();
      const materials = materialsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      // Lấy students
      const enrollmentsSnapshot = await db.collection('enrollments')
        .where('courseId', '==', id)
        .where('status', '==', 'active')
        .get();
      
      const studentIds = enrollmentsSnapshot.docs.map(doc => doc.data().studentId);
      let students = [];
      
      if (studentIds.length > 0) {
        const studentsSnapshot = await db.collection('users')
          .where('uid', 'in', studentIds)
          .get();
        students = studentsSnapshot.docs.map(doc => ({
          uid: doc.id,
          ...doc.data()
        }));
      }
      
      // Lấy groups
      const groupsSnapshot = await db.collection('groups')
        .where('courseId', '==', id)
        .get();
      const groups = groupsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      return {
        course,
        teacher,
        assignments,
        quizzes,
        materials,
        students,
        groups
      };
    } catch (error) {
      throw new Error(`Error finding course with full data: ${error.message}`);
    }
  }

  // Cập nhật course
  static async update(id, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('courses').doc(id).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, ...updateData };
    } catch (error) {
      throw new Error(`Error updating course: ${error.message}`);
    }
  }

  // Xóa course
  static async delete(id) {
    try {
      const db = admin.firestore();
      await db.collection('courses').doc(id).delete();
      return { id };
    } catch (error) {
      throw new Error(`Error deleting course: ${error.message}`);
    }
  }

  // Enroll student vào course
  static async enrollStudent(courseId, studentId) {
    try {
      const db = admin.firestore();
      const enrollmentId = `${studentId}_${courseId}`;
      
      await db.collection('enrollments').doc(enrollmentId).set({
        studentId,
        courseId,
        enrolledAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'active',
        progress: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { enrollmentId, studentId, courseId };
    } catch (error) {
      throw new Error(`Error enrolling student: ${error.message}`);
    }
  }

  // Unenroll student khỏi course
  static async unenrollStudent(courseId, studentId) {
    try {
      const db = admin.firestore();
      const enrollmentId = `${studentId}_${courseId}`;
      
      await db.collection('enrollments').doc(enrollmentId).delete();
      return { enrollmentId, studentId, courseId };
    } catch (error) {
      throw new Error(`Error unenrolling student: ${error.message}`);
    }
  }
}

module.exports = Course;


