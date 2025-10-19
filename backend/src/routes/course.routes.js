// ========================================
// FILE: course.routes.js
// MÔ TẢ: API routes cho courses
// ========================================

const express = require('express');
const router = express.Router();
const CourseController = require('../controllers/course.controller');
const { verifyFirebaseToken, requireRole } = require('../middlewares/firebaseAuth');

// ========================================
// PHẦN: Public routes (không cần authentication)
// MÔ TẢ: Các route công khai
// ========================================

// GET /api/courses - Lấy tất cả khóa học
router.get('/', CourseController.getAllCourses);

// GET /api/courses/:id - Lấy khóa học theo ID
router.get('/:id', CourseController.getCourseById);

// ========================================
// PHẦN: Protected routes (cần authentication)
// MÔ TẢ: Các route cần xác thực
// ========================================

// POST /api/courses - Tạo khóa học mới (chỉ Teacher)
router.post('/', verifyFirebaseToken, requireRole(['teacher']), CourseController.createCourse);

// PUT /api/courses/:id - Cập nhật khóa học (chỉ Teacher)
router.put('/:id', verifyFirebaseToken, requireRole(['teacher']), CourseController.updateCourse);

// DELETE /api/courses/:id - Xóa khóa học (chỉ Teacher)
router.delete('/:id', verifyFirebaseToken, requireRole(['teacher']), CourseController.deleteCourse);

// GET /api/courses/teacher/:teacherId - Lấy khóa học theo giảng viên
router.get('/teacher/:teacherId', CourseController.getCoursesByTeacher);

module.exports = router;



