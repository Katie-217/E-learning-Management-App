// ========================================
// FILE: assignment.controller.js
// MÔ TẢ: Controller xử lý business logic cho assignments
// ========================================

const { getFirestore } = require('../config/firebase');

class AssignmentController {
  // ========================================
  // HÀM: createAssignment
  // MÔ TẢ: Tạo bài tập mới
  // ========================================
  static async createAssignment(req, res) {
    try {
      const { title, description, courseId, dueDate, createdBy, maxPoints } = req.body;
      const db = getFirestore();
      
      const assignmentData = {
        title,
        description,
        courseId,
        dueDate: new Date(dueDate),
        createdBy,
        maxPoints: maxPoints || 100,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      const assignmentRef = await db.collection('assignments').add(assignmentData);
      
      res.status(201).json({
        success: true,
        data: { id: assignmentRef.id, ...assignmentData },
        message: 'Assignment created successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error creating assignment',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getAllAssignments
  // MÔ TẢ: Lấy tất cả bài tập
  // ========================================
  static async getAllAssignments(req, res) {
    try {
      const db = getFirestore();
      const assignmentsSnapshot = await db.collection('assignments').get();
      
      const assignments = assignmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      res.json({
        success: true,
        data: assignments,
        message: 'Assignments retrieved successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error retrieving assignments',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getAssignmentById
  // MÔ TẢ: Lấy bài tập theo ID
  // ========================================
  static async getAssignmentById(req, res) {
    try {
      const { id } = req.params;
      const db = getFirestore();
      
      const assignmentDoc = await db.collection('assignments').doc(id).get();
      
      if (!assignmentDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Assignment not found'
        });
      }
      
      res.json({
        success: true,
        data: { id: assignmentDoc.id, ...assignmentDoc.data() },
        message: 'Assignment retrieved successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error retrieving assignment',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: updateAssignment
  // MÔ TẢ: Cập nhật bài tập
  // ========================================
  static async updateAssignment(req, res) {
    try {
      const { id } = req.params;
      const updateData = { ...req.body, updatedAt: new Date() };
      const db = getFirestore();
      
      await db.collection('assignments').doc(id).update(updateData);
      
      res.json({
        success: true,
        data: { id, ...updateData },
        message: 'Assignment updated successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error updating assignment',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: deleteAssignment
  // MÔ TẢ: Xóa bài tập
  // ========================================
  static async deleteAssignment(req, res) {
    try {
      const { id } = req.params;
      const db = getFirestore();
      
      await db.collection('assignments').doc(id).delete();
      
      res.json({
        success: true,
        message: 'Assignment deleted successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error deleting assignment',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getAssignmentsByCourse
  // MÔ TẢ: Lấy bài tập theo khóa học
  // ========================================
  static async getAssignmentsByCourse(req, res) {
    try {
      const { courseId } = req.params;
      const db = getFirestore();
      
      const assignmentsSnapshot = await db.collection('assignments')
        .where('courseId', '==', courseId)
        .get();
      
      const assignments = assignmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      res.json({
        success: true,
        data: assignments,
        message: 'Course assignments retrieved successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error retrieving course assignments',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getAssignmentsByTeacher
  // MÔ TẢ: Lấy bài tập theo giảng viên
  // ========================================
  static async getAssignmentsByTeacher(req, res) {
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

module.exports = AssignmentController;



