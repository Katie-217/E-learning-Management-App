const admin = require('firebase-admin');

class Notification {
  constructor(data) {
    this.id = data.id || null;
    this.userId = data.userId || '';
    this.title = data.title || '';
    this.message = data.message || '';
    this.type = data.type || 'info';
    this.courseId = data.courseId || '';
    this.courseName = data.courseName || '';
    this.relatedId = data.relatedId || '';
    this.isRead = data.isRead !== undefined ? data.isRead : false;
    this.priority = data.priority || 'medium';
    this.createdAt = data.createdAt || new Date();
    this.readAt = data.readAt || null;
  }

  // Tạo notification mới
  static async create(notificationData) {
    try {
      const db = admin.firestore();
      const notificationRef = await db.collection('notifications').add({
        ...notificationData,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id: notificationRef.id, ...notificationData };
    } catch (error) {
      throw new Error(`Error creating notification: ${error.message}`);
    }
  }

  // Tạo notification cho nhiều users
  static async createBatch(notificationData, userIds) {
    try {
      const db = admin.firestore();
      const batch = db.batch();
      
      userIds.forEach(userId => {
        const notificationRef = db.collection('notifications').doc();
        batch.set(notificationRef, {
          ...notificationData,
          userId,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });
      
      await batch.commit();
      return { createdCount: userIds.length };
    } catch (error) {
      throw new Error(`Error creating batch notifications: ${error.message}`);
    }
  }

  // Lấy notification theo ID
  static async findById(id) {
    try {
      const db = admin.firestore();
      const notificationDoc = await db.collection('notifications').doc(id).get();
      if (!notificationDoc.exists) {
        return null;
      }
      return { id: notificationDoc.id, ...notificationDoc.data() };
    } catch (error) {
      throw new Error(`Error finding notification: ${error.message}`);
    }
  }

  // Lấy notifications theo user
  static async findByUser(userId, filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('notifications').where('userId', '==', userId);
      
      // Apply filters
      if (filters.isRead !== undefined) {
        query = query.where('isRead', '==', filters.isRead);
      }
      if (filters.type) {
        query = query.where('type', '==', filters.type);
      }
      if (filters.priority) {
        query = query.where('priority', '==', filters.priority);
      }
      if (filters.courseId) {
        query = query.where('courseId', '==', filters.courseId);
      }
      
      const notificationsSnapshot = await query
        .orderBy('createdAt', 'desc')
        .get();
      
      return notificationsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding notifications by user: ${error.message}`);
    }
  }

  // Lấy unread notifications
  static async findUnreadByUser(userId) {
    try {
      const db = admin.firestore();
      const notificationsSnapshot = await db.collection('notifications')
        .where('userId', '==', userId)
        .where('isRead', '==', false)
        .orderBy('createdAt', 'desc')
        .get();
      
      return notificationsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding unread notifications: ${error.message}`);
    }
  }

  // Lấy notifications theo course
  static async findByCourse(courseId) {
    try {
      const db = admin.firestore();
      const notificationsSnapshot = await db.collection('notifications')
        .where('courseId', '==', courseId)
        .orderBy('createdAt', 'desc')
        .get();
      
      return notificationsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding notifications by course: ${error.message}`);
    }
  }

  // Lấy notifications theo type
  static async findByType(type) {
    try {
      const db = admin.firestore();
      const notificationsSnapshot = await db.collection('notifications')
        .where('type', '==', type)
        .orderBy('createdAt', 'desc')
        .get();
      
      return notificationsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding notifications by type: ${error.message}`);
    }
  }

  // Cập nhật notification
  static async update(id, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('notifications').doc(id).update(updateData);
      return { id, ...updateData };
    } catch (error) {
      throw new Error(`Error updating notification: ${error.message}`);
    }
  }

  // Đánh dấu đã đọc
  static async markAsRead(id) {
    try {
      const db = admin.firestore();
      await db.collection('notifications').doc(id).update({
        isRead: true,
        readAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, isRead: true };
    } catch (error) {
      throw new Error(`Error marking notification as read: ${error.message}`);
    }
  }

  // Đánh dấu tất cả đã đọc
  static async markAllAsRead(userId) {
    try {
      const db = admin.firestore();
      const notificationsSnapshot = await db.collection('notifications')
        .where('userId', '==', userId)
        .where('isRead', '==', false)
        .get();
      
      const batch = db.batch();
      notificationsSnapshot.docs.forEach(doc => {
        batch.update(doc.ref, {
          isRead: true,
          readAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });
      
      await batch.commit();
      return { updatedCount: notificationsSnapshot.docs.length };
    } catch (error) {
      throw new Error(`Error marking all notifications as read: ${error.message}`);
    }
  }

  // Xóa notification
  static async delete(id) {
    try {
      const db = admin.firestore();
      await db.collection('notifications').doc(id).delete();
      return { id };
    } catch (error) {
      throw new Error(`Error deleting notification: ${error.message}`);
    }
  }

  // Xóa tất cả notifications của user
  static async deleteAllByUser(userId) {
    try {
      const db = admin.firestore();
      const notificationsSnapshot = await db.collection('notifications')
        .where('userId', '==', userId)
        .get();
      
      const batch = db.batch();
      notificationsSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      await batch.commit();
      return { deletedCount: notificationsSnapshot.docs.length };
    } catch (error) {
      throw new Error(`Error deleting all notifications by user: ${error.message}`);
    }
  }

  // Lấy thống kê notifications
  static async getStats(userId) {
    try {
      const db = admin.firestore();
      const notificationsSnapshot = await db.collection('notifications')
        .where('userId', '==', userId)
        .get();
      
      const notifications = notificationsSnapshot.docs.map(doc => doc.data());
      
      const total = notifications.length;
      const unread = notifications.filter(n => !n.isRead).length;
      const read = total - unread;
      
      const byType = notifications.reduce((acc, notification) => {
        const type = notification.type;
        acc[type] = (acc[type] || 0) + 1;
        return acc;
      }, {});
      
      const byPriority = notifications.reduce((acc, notification) => {
        const priority = notification.priority;
        acc[priority] = (acc[priority] || 0) + 1;
        return acc;
      }, {});
      
      return {
        total,
        unread,
        read,
        byType,
        byPriority
      };
    } catch (error) {
      throw new Error(`Error getting notification stats: ${error.message}`);
    }
  }

  // Tạo notification cho assignment
  static async createAssignmentNotification(assignmentId, courseId, courseName) {
    try {
      const db = admin.firestore();
      
      // Lấy students trong course
      const enrollmentsSnapshot = await db.collection('enrollments')
        .where('courseId', '==', courseId)
        .where('status', '==', 'active')
        .get();
      
      const studentIds = enrollmentsSnapshot.docs.map(doc => doc.data().studentId);
      
      if (studentIds.length === 0) {
        return { createdCount: 0 };
      }
      
      const notificationData = {
        title: 'New Assignment Available',
        message: `A new assignment has been posted in ${courseName}`,
        type: 'assignment',
        courseId,
        courseName,
        relatedId: assignmentId,
        priority: 'high'
      };
      
      return await this.createBatch(notificationData, studentIds);
    } catch (error) {
      throw new Error(`Error creating assignment notification: ${error.message}`);
    }
  }

  // Tạo notification cho quiz
  static async createQuizNotification(quizId, courseId, courseName) {
    try {
      const db = admin.firestore();
      
      // Lấy students trong course
      const enrollmentsSnapshot = await db.collection('enrollments')
        .where('courseId', '==', courseId)
        .where('status', '==', 'active')
        .get();
      
      const studentIds = enrollmentsSnapshot.docs.map(doc => doc.data().studentId);
      
      if (studentIds.length === 0) {
        return { createdCount: 0 };
      }
      
      const notificationData = {
        title: 'New Quiz Available',
        message: `A new quiz has been posted in ${courseName}`,
        type: 'quiz',
        courseId,
        courseName,
        relatedId: quizId,
        priority: 'high'
      };
      
      return await this.createBatch(notificationData, studentIds);
    } catch (error) {
      throw new Error(`Error creating quiz notification: ${error.message}`);
    }
  }
}

module.exports = Notification;
