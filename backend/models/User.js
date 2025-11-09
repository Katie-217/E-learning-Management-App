const admin = require('firebase-admin');

class User {
  constructor(data) {
    this.uid = data.uid || null;
    this.email = data.email || '';
    this.name = data.name || '';
    this.role = data.role || 'student';
    this.avatar = data.avatar || '';
    this.phone = data.phone || '';
    this.department = data.department || '';
    this.studentId = data.studentId || '';
    this.isActive = data.isActive !== undefined ? data.isActive : true;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Tạo user mới
  static async create(userData) {
    try {
      const db = admin.firestore();
      const userRef = await db.collection('users').doc(userData.uid).set({
        ...userData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { uid: userData.uid, ...userData };
    } catch (error) {
      throw new Error(`Error creating user: ${error.message}`);
    }
  }

  // Lấy user theo UID
  static async findById(uid) {
    try {
      const db = admin.firestore();
      const userDoc = await db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        return null;
      }
      return { uid: userDoc.id, ...userDoc.data() };
    } catch (error) {
      throw new Error(`Error finding user: ${error.message}`);
    }
  }

  // Lấy user theo email
  static async findByEmail(email) {
    try {
      const db = admin.firestore();
      const usersSnapshot = await db.collection('users')
        .where('email', '==', email)
        .limit(1)
        .get();
      
      if (usersSnapshot.empty) {
        return null;
      }
      
      const userDoc = usersSnapshot.docs[0];
      return { uid: userDoc.id, ...userDoc.data() };
    } catch (error) {
      throw new Error(`Error finding user by email: ${error.message}`);
    }
  }

  // Lấy tất cả users
  static async findAll(filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('users');
      
      // Apply filters
      if (filters.role) {
        query = query.where('role', '==', filters.role);
      }
      if (filters.department) {
        query = query.where('department', '==', filters.department);
      }
      if (filters.isActive !== undefined) {
        query = query.where('isActive', '==', filters.isActive);
      }
      
      const usersSnapshot = await query.get();
      return usersSnapshot.docs.map(doc => ({
        uid: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding users: ${error.message}`);
    }
  }

  // Lấy students theo course
  static async findStudentsByCourse(courseId) {
    try {
      const db = admin.firestore();
      const enrollmentsSnapshot = await db.collection('enrollments')
        .where('courseId', '==', courseId)
        .where('status', '==', 'active')
        .get();
      
      const studentIds = enrollmentsSnapshot.docs.map(doc => doc.data().studentId);
      
      if (studentIds.length === 0) {
        return [];
      }
      
      const usersSnapshot = await db.collection('users')
        .where('uid', 'in', studentIds)
        .where('role', '==', 'student')
        .get();
      
      return usersSnapshot.docs.map(doc => ({
        uid: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding students by course: ${error.message}`);
    }
  }

  // Cập nhật user
  static async update(uid, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('users').doc(uid).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { uid, ...updateData };
    } catch (error) {
      throw new Error(`Error updating user: ${error.message}`);
    }
  }

  // Xóa user
  static async delete(uid) {
    try {
      const db = admin.firestore();
      await db.collection('users').doc(uid).delete();
      return { uid };
    } catch (error) {
      throw new Error(`Error deleting user: ${error.message}`);
    }
  }

  // Lấy teachers
  static async findTeachers() {
    try {
      const db = admin.firestore();
      const teachersSnapshot = await db.collection('users')
        .where('role', '==', 'teacher')
        .where('isActive', '==', true)
        .get();
      
      return teachersSnapshot.docs.map(doc => ({
        uid: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding teachers: ${error.message}`);
    }
  }

  // Lấy students
  static async findStudents() {
    try {
      const db = admin.firestore();
      const studentsSnapshot = await db.collection('users')
        .where('role', '==', 'student')
        .where('isActive', '==', true)
        .get();
      
      return studentsSnapshot.docs.map(doc => ({
        uid: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding students: ${error.message}`);
    }
  }
}

module.exports = User;




