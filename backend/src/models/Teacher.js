const admin = require('firebase-admin');

class Teacher {
  constructor(data) {
    this.id = data.id || null;
    this.name = data.name || '';
    this.email = data.email || '';
    this.subject = data.subject || '';
    this.classes = data.classes || [];
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  static async create(teacherData) {
    try {
      const db = admin.firestore();
      const teacherRef = await db.collection('teachers').add({
        ...teacherData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id: teacherRef.id, ...teacherData };
    } catch (error) {
      throw new Error(`Error creating teacher: ${error.message}`);
    }
  }

  static async findById(id) {
    try {
      const db = admin.firestore();
      const teacherDoc = await db.collection('teachers').doc(id).get();
      if (!teacherDoc.exists) {
        return null;
      }
      return { id: teacherDoc.id, ...teacherDoc.data() };
    } catch (error) {
      throw new Error(`Error finding teacher: ${error.message}`);
    }
  }

  static async findAll() {
    try {
      const db = admin.firestore();
      const teachersSnapshot = await db.collection('teachers').get();
      return teachersSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding teachers: ${error.message}`);
    }
  }

  static async update(id, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('teachers').doc(id).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, ...updateData };
    } catch (error) {
      throw new Error(`Error updating teacher: ${error.message}`);
    }
  }

  static async delete(id) {
    try {
      const db = admin.firestore();
      await db.collection('teachers').doc(id).delete();
      return { id };
    } catch (error) {
      throw new Error(`Error deleting teacher: ${error.message}`);
    }
  }
}

module.exports = Teacher;