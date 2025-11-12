// ========================================
// ROUTES: Authentication Routes
// MÔ TẢ: Xử lý authentication và session
// ========================================

const express = require('express');
const router = express.Router();
const { requireAuth, checkSession, checkUserExists, createSession } = require('../middleware/authMiddleware');

// ========================================
// ENDPOINT: Kiểm tra session hiện tại
// ========================================
router.get('/check-session', checkSession, async (req, res) => {
  try {
    console.log('DEBUG: 🔍 Checking current session...');
    
    if (req.hasSession && req.user) {
      console.log('DEBUG: ✅ Valid session found');
      return res.json({
        success: true,
        message: 'Session hợp lệ',
        data: {
          user: req.user,
          hasSession: true
        }
      });
    } else {
      console.log('DEBUG: ⚠️ No valid session found');
      return res.json({
        success: false,
        message: 'Không có session hợp lệ',
        data: {
          hasSession: false
        }
      });
    }
  } catch (error) {
    console.log('DEBUG: ❌ Error checking session:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi kiểm tra session',
      error: error.message
    });
  }
});

// ========================================
// ENDPOINT: Đăng nhập và tạo session
// ========================================
router.post('/login', requireAuth, checkUserExists, createSession, async (req, res) => {
  try {
    console.log('DEBUG: 🔑 User login successful:', req.user.uid);
    
    return res.json({
      success: true,
      message: 'Đăng nhập thành công',
      data: {
        user: req.user,
        session: res.locals.sessionData,
        hasSession: true
      }
    });
  } catch (error) {
    console.log('DEBUG: ❌ Login error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi đăng nhập',
      error: error.message
    });
  }
});

// ========================================
// ENDPOINT: Đăng xuất
// ========================================
router.post('/logout', requireAuth, async (req, res) => {
  try {
    console.log('DEBUG: 🚪 User logout:', req.user.uid);
    
    // Revoke token (nếu cần)
    // await admin.auth().revokeRefreshTokens(req.user.uid);
    
    return res.json({
      success: true,
      message: 'Đăng xuất thành công',
      data: {
        hasSession: false
      }
    });
  } catch (error) {
    console.log('DEBUG: ❌ Logout error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi đăng xuất',
      error: error.message
    });
  }
});

// ========================================
// ENDPOINT: Lấy thông tin user
// ========================================
router.get('/user-info', requireAuth, checkUserExists, async (req, res) => {
  try {
    console.log('DEBUG: 👤 Getting user info:', req.user.uid);
    
    return res.json({
      success: true,
      message: 'Lấy thông tin user thành công',
      data: {
        user: req.user,
        userData: req.userData
      }
    });
  } catch (error) {
    console.log('DEBUG: ❌ Error getting user info:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi lấy thông tin user',
      error: error.message
    });
  }
});

// ========================================
// ENDPOINT: Kiểm tra user có tồn tại không
// ========================================
router.get('/user-exists/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    console.log('DEBUG: 🔍 Checking if user exists:', uid);
    
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(uid)
      .get();
    
    const exists = userDoc.exists;
    console.log('DEBUG: User exists:', exists);
    
    return res.json({
      success: true,
      message: 'Kiểm tra user thành công',
      data: {
        uid: uid,
        exists: exists
      }
    });
  } catch (error) {
    console.log('DEBUG: ❌ Error checking user existence:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi kiểm tra user',
      error: error.message
    });
  }
});

module.exports = router;
