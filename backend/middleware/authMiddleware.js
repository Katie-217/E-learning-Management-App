

const admin = require('firebase-admin');

// Authentication middleware
const requireAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'No authorization token',
        code: 'NO_TOKEN'
      });
    }

    const token = authHeader.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      name: decodedToken.name,
      picture: decodedToken.picture
    };
    
    next();
  } catch (error) {
    console.log('DEBUG: ❌ Token verification failed:', error.message);
    return res.status(401).json({
      success: false,
      message: 'Token không hợp lệ hoặc đã hết hạn',
      code: 'INVALID_TOKEN'
    });
  }
};

// Middleware kiểm tra session (không bắt buộc)
const checkSession = async (req, res, next) => {
  try {
    console.log('DEBUG: 🔍 SessionMiddleware - Checking session...');
    
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.log('DEBUG: ⚠️ No session found');
      req.hasSession = false;
      return next();
    }

    const token = authHeader.split('Bearer ')[1];
    
    try {
      const decodedToken = await admin.auth().verifyIdToken(token);
      console.log('DEBUG: ✅ Valid session found for user:', decodedToken.uid);
      
      req.user = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        name: decodedToken.name,
        picture: decodedToken.picture
      };
      req.hasSession = true;
    } catch (error) {
      console.log('DEBUG: ⚠️ Invalid session:', error.message);
      req.hasSession = false;
    }
    
    next();
  } catch (error) {
    console.log('DEBUG: ❌ Session check failed:', error.message);
    req.hasSession = false;
    next();
  }
};

// Middleware kiểm tra user có tồn tại trong database không
const checkUserExists = async (req, res, next) => {
  try {
    if (!req.user || !req.user.uid) {
      return res.status(401).json({
        success: false,
        message: 'Không có thông tin user',
        code: 'NO_USER_INFO'
      });
    }

    console.log('DEBUG: 🔍 Checking if user exists in database:', req.user.uid);
    
    // Kiểm tra user có tồn tại trong Firestore không
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(req.user.uid)
      .get();
    
    if (!userDoc.exists) {
      console.log('DEBUG: ⚠️ User not found in database');
      return res.status(404).json({
        success: false,
        message: 'User không tồn tại trong hệ thống',
        code: 'USER_NOT_FOUND'
      });
    }
    
    console.log('DEBUG: ✅ User exists in database');
    req.userData = userDoc.data();
    next();
  } catch (error) {
    console.log('DEBUG: ❌ Error checking user existence:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi kiểm tra user',
      code: 'USER_CHECK_ERROR'
    });
  }
};

// Middleware tạo session mới
const createSession = async (req, res, next) => {
  try {
    if (!req.user || !req.user.uid) {
      return res.status(401).json({
        success: false,
        message: 'Không có thông tin user',
        code: 'NO_USER_INFO'
      });
    }

    console.log('DEBUG: 🔄 Creating new session for user:', req.user.uid);
    
    // Tạo custom token cho session
    const customToken = await admin.auth().createCustomToken(req.user.uid);
    
    // Lưu session info vào response
    res.locals.sessionData = {
      uid: req.user.uid,
      email: req.user.email,
      name: req.user.name,
      customToken: customToken,
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours
    };
    
    console.log('DEBUG: ✅ Session created successfully');
    next();
  } catch (error) {
    console.log('DEBUG: ❌ Error creating session:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Lỗi tạo session',
      code: 'SESSION_CREATE_ERROR'
    });
  }
};

module.exports = {
  requireAuth,
  checkSession,
  checkUserExists,
  createSession
};
