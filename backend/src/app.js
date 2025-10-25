// ========================================
// FILE: app.js
// MÔ TẢ: Cấu hình Express application
// ========================================

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { initializeFirebase } = require('./config/firebase');

// Import routes
const authRoutes = require('../routes/auth');
const courseRoutes = require('../routes/course.routes');
const assignmentRoutes = require('../routes/assignment.routes');
const studentRoutes = require('../routes/student.routes');
const teacherRoutes = require('../routes/teacher.routes');

// ========================================
// HÀM: createApp
// MÔ TẢ: Tạo và cấu hình Express app
// ========================================
const createApp = () => {
  const app = express();

  // ========================================
  // PHẦN: Middleware cơ bản
  // MÔ TẢ: Cấu hình các middleware cần thiết
  // ========================================
  
  // CORS - cho phép Flutter/web truy cập
  app.use(cors({
    origin: process.env.FRONTEND_URL || '*',
    credentials: true
  }));

  // Body parser
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // Logging
  app.use(morgan('combined'));

  // ========================================
  // PHẦN: Routes
  // MÔ TẢ: Định nghĩa các API endpoints
  // ========================================
  
  // Health check
  app.get('/health', (req, res) => {
    res.json({ 
      status: 'OK', 
      timestamp: new Date().toISOString(),
      service: 'E-Learning Backend API'
    });
  });

  // API routes
  app.use('/api/auth', authRoutes);
  app.use('/api/courses', courseRoutes);
  app.use('/api/assignments', assignmentRoutes);
  app.use('/api/students', studentRoutes);
  app.use('/api/teachers', teacherRoutes);

  // ========================================
  // PHẦN: Error handling
  // MÔ TẢ: Xử lý lỗi toàn cục
  // ========================================
  
  // 404 handler
  app.use('*', (req, res) => {
    res.status(404).json({
      success: false,
      message: 'API endpoint not found',
      path: req.originalUrl
    });
  });

  // Global error handler
  app.use((error, req, res, next) => {
    console.error('Global error handler:', error);
    
    res.status(error.status || 500).json({
      success: false,
      message: error.message || 'Internal server error',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
  });

  return app;
};

// ========================================
// HÀM: initializeApp
// MÔ TẢ: Khởi tạo ứng dụng
// ========================================
const initializeApp = async () => {
  try {
    // Khởi tạo Firebase
    await initializeFirebase();
    
    // Tạo Express app
    const app = createApp();
    
    return app;
  } catch (error) {
    console.error('Failed to initialize app:', error);
    throw error;
  }
};

module.exports = { createApp, initializeApp };



