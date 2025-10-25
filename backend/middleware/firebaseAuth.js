'use strict';

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Admin SDK once
if (!admin.apps.length) {
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT || path.join(__dirname, '..', 'serviceAccountKey.json');
  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

// Middleware: verify Firebase ID token from Authorization: Bearer <token>
async function verifyFirebaseToken(req, res, next) {
  try {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
    if (!token) return res.status(401).json({ error: 'Missing bearer token' });

    const decoded = await admin.auth().verifyIdToken(token);
    req.user = decoded;
    return next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token', detail: err?.message });
  }
}

module.exports = { verifyFirebaseToken };




// Role-based authorization middleware
// Usage: router.post('/path', verifyFirebaseToken, requireRole(['teacher']), handler)
function requireRole(roles) {
  return function (req, res, next) {
    try {
      const decoded = req.user; // set by verifyFirebaseToken
      const userRole = decoded?.role || decoded?.claims?.role; // support custom claims if present
      if (!userRole) {
        return res.status(403).json({ 
          success: false,
          error: 'Missing role in token' 
        });
      }
      if (Array.isArray(roles) ? roles.includes(userRole) : roles === userRole) {
        return next();
      }
      return res.status(403).json({ 
        success: false,
        error: 'Insufficient role',
        required: roles,
        current: userRole
      });
    } catch (err) {
      return res.status(403).json({ 
        success: false,
        error: 'Authorization error', 
        detail: err?.message 
      });
    }
  }
}

module.exports.requireRole = requireRole;