// ========================================
// FILE: teacher.routes.js
// MÔ TẢ: API routes cho teachers
// ========================================

const express = require('express');
const router = express.Router();
const TeacherController = require('../controllers/teacher.controller');
const { verifyFirebaseToken, requireRole } = require('../middleware/firebaseAuth');

// ========================================
// PHẦN: Public routes (không cần authentication)
// MÔ TẢ: Các route công khai
// ========================================

// GET /api/teachers - Lấy tất cả giảng viên
router.get('/', TeacherController.getAllTeachers);

// GET /api/teachers/:id - Lấy giảng viên theo ID
router.get('/:id', TeacherController.getTeacherById);

// GET /api/teachers/:teacherId/courses - Lấy khóa học của giảng viên
router.get('/:teacherId/courses', TeacherController.getTeacherCourses);

// GET /api/teachers/:teacherId/assignments - Lấy bài tập của giảng viên
router.get('/:teacherId/assignments', TeacherController.getTeacherAssignments);

// ========================================
// PHẦN: Protected routes (cần authentication)
// MÔ TẢ: Các route cần xác thực
// ========================================

// POST /api/teachers - Tạo giảng viên mới (chỉ Admin)
router.post('/', verifyFirebaseToken, requireRole(['admin']), TeacherController.createTeacher);

// PUT /api/teachers/:id - Cập nhật giảng viên (chỉ Teacher hoặc Admin)
router.put('/:id', verifyFirebaseToken, requireRole(['teacher', 'admin']), TeacherController.updateTeacher);

// DELETE /api/teachers/:id - Xóa giảng viên (chỉ Admin)
router.delete('/:id', verifyFirebaseToken, requireRole(['admin']), TeacherController.deleteTeacher);

module.exports = router;



