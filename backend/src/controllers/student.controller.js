// ========================================
// FILE: student.controller.js
// MÔ TẢ: Controller xử lý business logic cho students
// ========================================

const { getFirestore, getAuth } = require('../config/firebase');

class StudentController {
  // ========================================
  // HÀM: createStudent
  // MÔ TẢ: Tạo sinh viên mới
  // ========================================
  static async createStudent(req, res) {
    try {
      const { name, email, studentId, classId, semester } = req.body;
      const db = getFirestore();
      const auth = getAuth();
      
      // Tạo user trong Firebase Auth
      const userRecord = await auth.createUser({
        email: email,
        displayName: name,
        password: 'defaultPassword123' // Sẽ được thay đổi sau
      });
      
      // Lưu thông tin sinh viên vào Firestore
      const studentData = {
        name,
        email,
        studentId,
        classId,
        semester,
        uid: userRecord.uid,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      await db.collection('students').doc(userRecord.uid).set(studentData);
      
      res.status(201).json({
        success: true,
        data: { uid: userRecord.uid, ...studentData },
        message: 'Student created successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error creating student',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getAllStudents
  // MÔ TẢ: Lấy tất cả sinh viên
  // ========================================
  static async getAllStudents(req, res) {
    try {
      const db = getFirestore();
      const studentsSnapshot = await db.collection('students').get();
      
      const students = studentsSnapshot.docs.map(doc => ({
        uid: doc.id,
        ...doc.data()
      }));
      
      res.json({
        success: true,
        data: students,
        message: 'Students retrieved successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error retrieving students',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getStudentById
  // MÔ TẢ: Lấy sinh viên theo ID
  // ========================================
  static async getStudentById(req, res) {
    try {
      const { id } = req.params;
      const db = getFirestore();
      
      const studentDoc = await db.collection('students').doc(id).get();
      
      if (!studentDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Student not found'
        });
      }
      
      res.json({
        success: true,
        data: { uid: studentDoc.id, ...studentDoc.data() },
        message: 'Student retrieved successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error retrieving student',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: updateStudent
  // MÔ TẢ: Cập nhật sinh viên
  // ========================================
  static async updateStudent(req, res) {
    try {
      const { id } = req.params;
      const updateData = { ...req.body, updatedAt: new Date() };
      const db = getFirestore();
      
      await db.collection('students').doc(id).update(updateData);
      
      res.json({
        success: true,
        data: { uid: id, ...updateData },
        message: 'Student updated successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error updating student',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: deleteStudent
  // MÔ TẢ: Xóa sinh viên
  // ========================================
  static async deleteStudent(req, res) {
    try {
      const { id } = req.params;
      const db = getFirestore();
      const auth = getAuth();
      
      // Xóa user khỏi Firebase Auth
      await auth.deleteUser(id);
      
      // Xóa thông tin sinh viên khỏi Firestore
      await db.collection('students').doc(id).delete();
      
      res.json({
        success: true,
        message: 'Student deleted successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error deleting student',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getStudentsByClass
  // MÔ TẢ: Lấy sinh viên theo lớp
  // ========================================
  static async getStudentsByClass(req, res) {
    try {
      const { classId } = req.params;
      const db = getFirestore();
      
      const studentsSnapshot = await db.collection('students')
        .where('classId', '==', classId)
        .get();
      
      const students = studentsSnapshot.docs.map(doc => ({
        uid: doc.id,
        ...doc.data()
      }));
      
      res.json({
        success: true,
        data: students,
        message: 'Class students retrieved successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error retrieving class students',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: importStudentsFromCSV
  // MÔ TẢ: Import sinh viên từ CSV
  // ========================================
  static async importStudentsFromCSV(req, res) {
    try {
      const { students, classId, semester } = req.body;
      const db = getFirestore();
      const auth = getAuth();
      
      const results = [];
      
      for (const student of students) {
        try {
          // Tạo user trong Firebase Auth
          const userRecord = await auth.createUser({
            email: student.email,
            displayName: student.name,
            password: 'defaultPassword123'
          });
          
          // Lưu thông tin sinh viên vào Firestore
          const studentData = {
            name: student.name,
            email: student.email,
            studentId: student.studentId,
            classId,
            semester,
            uid: userRecord.uid,
            createdAt: new Date(),
            updatedAt: new Date()
          };
          
          await db.collection('students').doc(userRecord.uid).set(studentData);
          
          results.push({ success: true, data: studentData });
        } catch (error) {
          results.push({ success: false, error: error.message, data: student });
        }
      }
      
      res.json({
        success: true,
        data: results,
        message: 'CSV import completed'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error importing students from CSV',
        error: error.message
      });
    }
  }
}

module.exports = StudentController;



