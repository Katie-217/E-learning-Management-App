// ========================================
// FILE: teacher.controller.js
// MÔ TẢ: Controller xử lý business logic cho teachers
// ========================================

const { getFirestore, getAuth } = require('../config/firebase');

class TeacherController {
  // ========================================
  // HÀM: createTeacher
  // MÔ TẢ: Tạo giảng viên mới
  // ========================================
  static async createTeacher(req, res) {
    try {
      const { name, email, subject, department } = req.body;
      const db = getFirestore();
      const auth = getAuth();
      
      // Tạo user trong Firebase Auth
      const userRecord = await auth.createUser({
        email: email,
        displayName: name,
        password: 'defaultPassword123' // Sẽ được thay đổi sau
      });
      
      // Lưu thông tin giảng viên vào Firestore
      const teacherData = {
        name,
        email,
        subject,
        department,
        uid: userRecord.uid,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      await db.collection('teachers').doc(userRecord.uid).set(teacherData);
      
      res.status(201).json({
        success: true,
        data: { uid: userRecord.uid, ...teacherData },
        message: 'Teacher created successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error creating teacher',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getAllTeachers
  // MÔ TẢ: Lấy tất cả giảng viên
  // ========================================
  static async getAllTeachers(req, res) {
    try {
      const db = getFirestore();
      const teachersSnapshot = await db.collection('teachers').get();
      
      const teachers = teachersSnapshot.docs.map(doc => ({
        uid: doc.id,
        ...doc.data()
      }));
      
      res.json({
        success: true,
        data: teachers,
        message: 'Teachers retrieved successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error retrieving teachers',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getTeacherById
  // MÔ TẢ: Lấy giảng viên theo ID
  // ========================================
  static async getTeacherById(req, res) {
    try {
      const { id } = req.params;
      const db = getFirestore();
      
      const teacherDoc = await db.collection('teachers').doc(id).get();
      
      if (!teacherDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Teacher not found'
        });
      }
      
      res.json({
        success: true,
        data: { uid: teacherDoc.id, ...teacherDoc.data() },
        message: 'Teacher retrieved successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error retrieving teacher',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: updateTeacher
  // MÔ TẢ: Cập nhật giảng viên
  // ========================================
  static async updateTeacher(req, res) {
    try {
      const { id } = req.params;
      const updateData = { ...req.body, updatedAt: new Date() };
      const db = getFirestore();
      
      await db.collection('teachers').doc(id).update(updateData);
      
      res.json({
        success: true,
        data: { uid: id, ...updateData },
        message: 'Teacher updated successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error updating teacher',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: deleteTeacher
  // MÔ TẢ: Xóa giảng viên
  // ========================================
  static async deleteTeacher(req, res) {
    try {
      const { id } = req.params;
      const db = getFirestore();
      const auth = getAuth();
      
      // Xóa user khỏi Firebase Auth
      await auth.deleteUser(id);
      
      // Xóa thông tin giảng viên khỏi Firestore
      await db.collection('teachers').doc(id).delete();
      
      res.json({
        success: true,
        message: 'Teacher deleted successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error deleting teacher',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getTeacherCourses
  // MÔ TẢ: Lấy khóa học của giảng viên
  // ========================================
  static async getTeacherCourses(req, res) {
    try {
      const { teacherId } = req.params;
      const db = getFirestore();
      
      const coursesSnapshot = await db.collection('courses')
        .where('teacherId', '==', teacherId)
        .get();
      
      const courses = coursesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      res.json({
        success: true,
        data: courses,
        message: 'Teacher courses retrieved successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error retrieving teacher courses',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getTeacherAssignments
  // MÔ TẢ: Lấy bài tập của giảng viên
  // ========================================
  static async getTeacherAssignments(req, res) {
    try {
      const { teacherId } = req.params;
      const db = getFirestore();
      
      const assignmentsSnapshot = await db.collection('assignments')
        .where('createdBy', '==', teacherId)
        .get();
      
      const assignments = assignmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      res.json({
        success: true,
        data: assignments,
        message: 'Teacher assignments retrieved successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error retrieving teacher assignments',
        error: error.message
      });
    }
  }
}

module.exports = TeacherController;



