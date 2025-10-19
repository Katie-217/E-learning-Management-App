// ========================================
// FILE: student.routes.js
// MÔ TẢ: API routes cho students
// ========================================

const express = require('express');
const router = express.Router();
const StudentController = require('../controllers/student.controller');
const { verifyFirebaseToken, requireRole } = require('../middlewares/firebaseAuth');

// ========================================
// PHẦN: Public routes (không cần authentication)
// MÔ TẢ: Các route công khai
// ========================================

// GET /api/students - Lấy tất cả sinh viên
router.get('/', StudentController.getAllStudents);

// GET /api/students/:id - Lấy sinh viên theo ID
router.get('/:id', StudentController.getStudentById);

// GET /api/students/class/:classId - Lấy sinh viên theo lớp
router.get('/class/:classId', StudentController.getStudentsByClass);

// ========================================
// PHẦN: Protected routes (cần authentication)
// MÔ TẢ: Các route cần xác thực
// ========================================

// POST /api/students - Tạo sinh viên mới (chỉ Teacher)
router.post('/', verifyFirebaseToken, requireRole(['teacher']), StudentController.createStudent);

// PUT /api/students/:id - Cập nhật sinh viên (chỉ Teacher)
router.put('/:id', verifyFirebaseToken, requireRole(['teacher']), StudentController.updateStudent);

// DELETE /api/students/:id - Xóa sinh viên (chỉ Teacher)
router.delete('/:id', verifyFirebaseToken, requireRole(['teacher']), StudentController.deleteStudent);

// POST /api/students/import-csv - Import sinh viên từ CSV (chỉ Teacher)
router.post('/import-csv', verifyFirebaseToken, requireRole(['teacher']), StudentController.importStudentsFromCSV);

module.exports = router;



