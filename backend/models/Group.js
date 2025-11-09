const admin = require('firebase-admin');

class Group {
  constructor(data) {
    this.id = data.id || null;
    this.name = data.name || '';
    this.courseId = data.courseId || '';
    this.courseName = data.courseName || '';
    this.teacherId = data.teacherId || '';
    this.teacherName = data.teacherName || '';
    this.members = data.members || [];
    this.memberNames = data.memberNames || [];
    this.leaderId = data.leaderId || '';
    this.leaderName = data.leaderName || '';
    this.description = data.description || '';
    this.maxMembers = data.maxMembers || 5;
    this.isActive = data.isActive !== undefined ? data.isActive : true;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Tạo group mới
  static async create(groupData) {
    try {
      const db = admin.firestore();
      const groupRef = await db.collection('groups').add({
        ...groupData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id: groupRef.id, ...groupData };
    } catch (error) {
      throw new Error(`Error creating group: ${error.message}`);
    }
  }

  // Lấy group theo ID
  static async findById(id) {
    try {
      const db = admin.firestore();
      const groupDoc = await db.collection('groups').doc(id).get();
      if (!groupDoc.exists) {
        return null;
      }
      return { id: groupDoc.id, ...groupDoc.data() };
    } catch (error) {
      throw new Error(`Error finding group: ${error.message}`);
    }
  }

  // Lấy tất cả groups
  static async findAll(filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('groups');
      
      // Apply filters
      if (filters.courseId) {
        query = query.where('courseId', '==', filters.courseId);
      }
      if (filters.teacherId) {
        query = query.where('teacherId', '==', filters.teacherId);
      }
      if (filters.isActive !== undefined) {
        query = query.where('isActive', '==', filters.isActive);
      }
      
      const groupsSnapshot = await query.get();
      return groupsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding groups: ${error.message}`);
    }
  }

  // Lấy groups theo course
  static async findByCourse(courseId) {
    try {
      const db = admin.firestore();
      const groupsSnapshot = await db.collection('groups')
        .where('courseId', '==', courseId)
        .where('isActive', '==', true)
        .get();
      
      return groupsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding groups by course: ${error.message}`);
    }
  }

  // Lấy groups theo teacher
  static async findByTeacher(teacherId) {
    try {
      const db = admin.firestore();
      const groupsSnapshot = await db.collection('groups')
        .where('teacherId', '==', teacherId)
        .get();
      
      return groupsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding groups by teacher: ${error.message}`);
    }
  }

  // Lấy groups của student
  static async findByStudent(studentId) {
    try {
      const db = admin.firestore();
      const groupsSnapshot = await db.collection('groups')
        .where('members', 'array-contains', studentId)
        .where('isActive', '==', true)
        .get();
      
      return groupsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding groups by student: ${error.message}`);
    }
  }

  // Cập nhật group
  static async update(id, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('groups').doc(id).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, ...updateData };
    } catch (error) {
      throw new Error(`Error updating group: ${error.message}`);
    }
  }

  // Xóa group
  static async delete(id) {
    try {
      const db = admin.firestore();
      await db.collection('groups').doc(id).delete();
      return { id };
    } catch (error) {
      throw new Error(`Error deleting group: ${error.message}`);
    }
  }

  // Thêm member vào group
  static async addMember(id, studentId, studentName) {
    try {
      const db = admin.firestore();
      const groupDoc = await db.collection('groups').doc(id).get();
      
      if (!groupDoc.exists) {
        throw new Error('Group not found');
      }
      
      const group = groupDoc.data();
      
      // Check if group is full
      if (group.members.length >= group.maxMembers) {
        throw new Error('Group is full');
      }
      
      // Check if student is already in group
      if (group.members.includes(studentId)) {
        throw new Error('Student is already in group');
      }
      
      await db.collection('groups').doc(id).update({
        members: admin.firestore.FieldValue.arrayUnion(studentId),
        memberNames: admin.firestore.FieldValue.arrayUnion(studentName),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { id, studentId, studentName };
    } catch (error) {
      throw new Error(`Error adding member to group: ${error.message}`);
    }
  }

  // Xóa member khỏi group
  static async removeMember(id, studentId, studentName) {
    try {
      const db = admin.firestore();
      await db.collection('groups').doc(id).update({
        members: admin.firestore.FieldValue.arrayRemove(studentId),
        memberNames: admin.firestore.FieldValue.arrayRemove(studentName),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { id, studentId, studentName };
    } catch (error) {
      throw new Error(`Error removing member from group: ${error.message}`);
    }
  }

  // Set group leader
  static async setLeader(id, leaderId, leaderName) {
    try {
      const db = admin.firestore();
      const groupDoc = await db.collection('groups').doc(id).get();
      
      if (!groupDoc.exists) {
        throw new Error('Group not found');
      }
      
      const group = groupDoc.data();
      
      // Check if leader is a member of the group
      if (!group.members.includes(leaderId)) {
        throw new Error('Leader must be a member of the group');
      }
      
      await db.collection('groups').doc(id).update({
        leaderId,
        leaderName,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return { id, leaderId, leaderName };
    } catch (error) {
      throw new Error(`Error setting group leader: ${error.message}`);
    }
  }

  // Deactivate group
  static async deactivate(id) {
    try {
      const db = admin.firestore();
      await db.collection('groups').doc(id).update({
        isActive: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, isActive: false };
    } catch (error) {
      throw new Error(`Error deactivating group: ${error.message}`);
    }
  }

  // Activate group
  static async activate(id) {
    try {
      const db = admin.firestore();
      await db.collection('groups').doc(id).update({
        isActive: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, isActive: true };
    } catch (error) {
      throw new Error(`Error activating group: ${error.message}`);
    }
  }

  // Lấy thống kê group
  static async getStats(id) {
    try {
      const db = admin.firestore();
      const groupDoc = await db.collection('groups').doc(id).get();
      
      if (!groupDoc.exists) {
        throw new Error('Group not found');
      }
      
      const group = groupDoc.data();
      
      return {
        id,
        name: group.name,
        totalMembers: group.members.length,
        maxMembers: group.maxMembers,
        isFull: group.members.length >= group.maxMembers,
        leaderName: group.leaderName,
        isActive: group.isActive
      };
    } catch (error) {
      throw new Error(`Error getting group stats: ${error.message}`);
    }
  }
}

module.exports = Group;
