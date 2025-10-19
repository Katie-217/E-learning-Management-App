// ========================================
// FILE: course.controller.js
// MÔ TẢ: Controller xử lý business logic cho courses
// ========================================

const { getFirestore } = require('../config/firebase');

class CourseController {
  // ========================================
  // HÀM: createCourse
  // MÔ TẢ: Tạo khóa học mới
  // ========================================
  static async createCourse(req, res) {
    try {
      const { name, description, teacherId, semester, year, code } = req.body;
      const db = getFirestore();
      
      const courseData = {
        name,
        description,
        teacherId,
        semester,
        year,
        code,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      
      const courseRef = await db.collection('courses').add(courseData);
      
      res.status(201).json({
        success: true,
        data: { id: courseRef.id, ...courseData },
        message: 'Course created successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error creating course',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getAllCourses
  // MÔ TẢ: Lấy tất cả khóa học
  // ========================================
  static async getAllCourses(req, res) {
    try {
      const db = getFirestore();
      const coursesSnapshot = await db.collection('courses').get();
      
      const courses = coursesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      res.json({
        success: true,
        data: courses,
        message: 'Courses retrieved successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error retrieving courses',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getCourseById
  // MÔ TẢ: Lấy khóa học theo ID
  // ========================================
  static async getCourseById(req, res) {
    try {
      const { id } = req.params;
      const db = getFirestore();
      
      const courseDoc = await db.collection('courses').doc(id).get();
      
      if (!courseDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Course not found'
        });
      }
      
      res.json({
        success: true,
        data: { id: courseDoc.id, ...courseDoc.data() },
        message: 'Course retrieved successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error retrieving course',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: updateCourse
  // MÔ TẢ: Cập nhật khóa học
  // ========================================
  static async updateCourse(req, res) {
    try {
      const { id } = req.params;
      const updateData = { ...req.body, updatedAt: new Date() };
      const db = getFirestore();
      
      await db.collection('courses').doc(id).update(updateData);
      
      res.json({
        success: true,
        data: { id, ...updateData },
        message: 'Course updated successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error updating course',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: deleteCourse
  // MÔ TẢ: Xóa khóa học
  // ========================================
  static async deleteCourse(req, res) {
    try {
      const { id } = req.params;
      const db = getFirestore();
      
      await db.collection('courses').doc(id).delete();
      
      res.json({
        success: true,
        message: 'Course deleted successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Error deleting course',
        error: error.message
      });
    }
  }

  // ========================================
  // HÀM: getCoursesByTeacher
  // MÔ TẢ: Lấy khóa học theo giảng viên
  // ========================================
  static async getCoursesByTeacher(req, res) {
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
}

module.exports = CourseController;



