// ========================================
// FILE: assignment.routes.js
// MÔ TẢ: API routes cho assignments
// ========================================

const express = require('express');
const router = express.Router();
const AssignmentController = require('../controllers/assignment.controller');
const { verifyFirebaseToken, requireRole } = require('../middleware/firebaseAuth');

// ========================================
// PHẦN: Public routes (không cần authentication)
// MÔ TẢ: Các route công khai
// ========================================

// GET /api/assignments - Lấy tất cả bài tập
router.get('/', AssignmentController.getAllAssignments);

// GET /api/assignments/:id - Lấy bài tập theo ID
router.get('/:id', AssignmentController.getAssignmentById);

// GET /api/assignments/course/:courseId - Lấy bài tập theo khóa học
router.get('/course/:courseId', AssignmentController.getAssignmentsByCourse);

// ========================================
// PHẦN: Protected routes (cần authentication)
// MÔ TẢ: Các route cần xác thực
// ========================================

// POST /api/assignments - Tạo bài tập mới (chỉ Teacher)
router.post('/', verifyFirebaseToken, requireRole(['teacher']), AssignmentController.createAssignment);

// PUT /api/assignments/:id - Cập nhật bài tập (chỉ Teacher)
router.put('/:id', verifyFirebaseToken, requireRole(['teacher']), AssignmentController.updateAssignment);

// DELETE /api/assignments/:id - Xóa bài tập (chỉ Teacher)
router.delete('/:id', verifyFirebaseToken, requireRole(['teacher']), AssignmentController.deleteAssignment);

// GET /api/assignments/teacher/:teacherId - Lấy bài tập theo giảng viên
router.get('/teacher/:teacherId', AssignmentController.getAssignmentsByTeacher);

module.exports = router;



