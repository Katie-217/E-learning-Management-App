// ========================================
// FILE: server.js
// MÔ TẢ: Entry point cho backend application
// ========================================

require('dotenv').config();
const { initializeApp } = require('./src/app');

// ========================================
// HÀM: startServer
// MÔ TẢ: Khởi động server
// ========================================
const startServer = async () => {
  try {
    // Khởi tạo ứng dụng
    const app = await initializeApp();
    
    // Lấy port từ environment variables
    const PORT = process.env.PORT || 4000;
    
    // Khởi động server
    app.listen(PORT, () => {
      console.log('🚀 ========================================');
      console.log('🚀 E-Learning Backend API Server');
      console.log('🚀 ========================================');
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`🚀 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🚀 Health check: http://localhost:${PORT}/health`);
      console.log('🚀 ========================================');
    });
    
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Khởi động server
startServer();