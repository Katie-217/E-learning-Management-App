const admin = require('firebase-admin');

class Submission {
  constructor(data) {
    this.id = data.id || null;
    this.assignmentId = data.assignmentId || '';
    this.studentId = data.studentId || '';
    this.content = data.content || '';
    this.fileUrl = data.fileUrl || '';
    this.submittedAt = data.submittedAt || new Date();
    this.grade = data.grade || null;
    this.feedback = data.feedback || '';
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  static async create(submissionData) {
    try {
      const db = admin.firestore();
      const submissionRef = await db.collection('submissions').add({
        ...submissionData,
        submittedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id: submissionRef.id, ...submissionData };
    } catch (error) {
      throw new Error(`Error creating submission: ${error.message}`);
    }
  }

  static async findById(id) {
    try {
      const db = admin.firestore();
      const submissionDoc = await db.collection('submissions').doc(id).get();
      if (!submissionDoc.exists) {
        return null;
      }
      return { id: submissionDoc.id, ...submissionDoc.data() };
    } catch (error) {
      throw new Error(`Error finding submission: ${error.message}`);
    }
  }

  static async findByAssignment(assignmentId) {
    try {
      const db = admin.firestore();
      const submissionsSnapshot = await db.collection('submissions')
        .where('assignmentId', '==', assignmentId)
        .get();
      return submissionsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding submissions by assignment: ${error.message}`);
    }
  }

  static async findByStudent(studentId) {
    try {
      const db = admin.firestore();
      const submissionsSnapshot = await db.collection('submissions')
        .where('studentId', '==', studentId)
        .get();
      return submissionsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding submissions by student: ${error.message}`);
    }
  }

  static async findAll() {
    try {
      const db = admin.firestore();
      const submissionsSnapshot = await db.collection('submissions').get();
      return submissionsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding submissions: ${error.message}`);
    }
  }

  static async update(id, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('submissions').doc(id).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, ...updateData };
    } catch (error) {
      throw new Error(`Error updating submission: ${error.message}`);
    }
  }

  static async delete(id) {
    try {
      const db = admin.firestore();
      await db.collection('submissions').doc(id).delete();
      return { id };
    } catch (error) {
      throw new Error(`Error deleting submission: ${error.message}`);
    }
  }
}

module.exports = Submission;