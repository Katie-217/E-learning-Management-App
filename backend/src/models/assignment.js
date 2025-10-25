const admin = require('firebase-admin');

class Assignment {
  constructor(data) {
    this.id = data.id || null;
    this.title = data.title || '';
    this.description = data.description || '';
    this.classId = data.classId || '';
    this.dueDate = data.dueDate || null;
    this.createdBy = data.createdBy || '';
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  static async create(assignmentData) {
    try {
      const db = admin.firestore();
      const assignmentRef = await db.collection('assignments').add({
        ...assignmentData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id: assignmentRef.id, ...assignmentData };
    } catch (error) {
      throw new Error(`Error creating assignment: ${error.message}`);
    }
  }

  static async findById(id) {
    try {
      const db = admin.firestore();
      const assignmentDoc = await db.collection('assignments').doc(id).get();
      if (!assignmentDoc.exists) {
        return null;
      }
      return { id: assignmentDoc.id, ...assignmentDoc.data() };
    } catch (error) {
      throw new Error(`Error finding assignment: ${error.message}`);
    }
  }

  static async findByClass(classId) {
    try {
      const db = admin.firestore();
      const assignmentsSnapshot = await db.collection('assignments')
        .where('classId', '==', classId)
        .get();
      return assignmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding assignments by class: ${error.message}`);
    }
  }

  static async findAll() {
    try {
      const db = admin.firestore();
      const assignmentsSnapshot = await db.collection('assignments').get();
      return assignmentsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding assignments: ${error.message}`);
    }
  }

  static async update(id, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('assignments').doc(id).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, ...updateData };
    } catch (error) {
      throw new Error(`Error updating assignment: ${error.message}`);
    }
  }

  static async delete(id) {
    try {
      const db = admin.firestore();
      await db.collection('assignments').doc(id).delete();
      return { id };
    } catch (error) {
      throw new Error(`Error deleting assignment: ${error.message}`);
    }
  }
}

module.exports = Assignment;