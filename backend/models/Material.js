const admin = require('firebase-admin');

class Material {
  constructor(data) {
    this.id = data.id || null;
    this.title = data.title || '';
    this.description = data.description || '';
    this.courseId = data.courseId || '';
    this.courseName = data.courseName || '';
    this.uploadedBy = data.uploadedBy || '';
    this.uploadedByName = data.uploadedByName || '';
    this.fileUrl = data.fileUrl || '';
    this.fileName = data.fileName || '';
    this.fileType = data.fileType || '';
    this.fileSize = data.fileSize || 0;
    this.category = data.category || 'resource';
    this.isPublic = data.isPublic !== undefined ? data.isPublic : true;
    this.downloadCount = data.downloadCount || 0;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Tạo material mới
  static async create(materialData) {
    try {
      const db = admin.firestore();
      const materialRef = await db.collection('materials').add({
        ...materialData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id: materialRef.id, ...materialData };
    } catch (error) {
      throw new Error(`Error creating material: ${error.message}`);
    }
  }

  // Lấy material theo ID
  static async findById(id) {
    try {
      const db = admin.firestore();
      const materialDoc = await db.collection('materials').doc(id).get();
      if (!materialDoc.exists) {
        return null;
      }
      return { id: materialDoc.id, ...materialDoc.data() };
    } catch (error) {
      throw new Error(`Error finding material: ${error.message}`);
    }
  }

  // Lấy tất cả materials
  static async findAll(filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('materials');
      
      // Apply filters
      if (filters.courseId) {
        query = query.where('courseId', '==', filters.courseId);
      }
      if (filters.fileType) {
        query = query.where('fileType', '==', filters.fileType);
      }
      if (filters.category) {
        query = query.where('category', '==', filters.category);
      }
      if (filters.uploadedBy) {
        query = query.where('uploadedBy', '==', filters.uploadedBy);
      }
      if (filters.isPublic !== undefined) {
        query = query.where('isPublic', '==', filters.isPublic);
      }
      
      const materialsSnapshot = await query.orderBy('createdAt', 'desc').get();
      return materialsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding materials: ${error.message}`);
    }
  }

  // Lấy materials theo course
  static async findByCourse(courseId) {
    try {
      const db = admin.firestore();
      const materialsSnapshot = await db.collection('materials')
        .where('courseId', '==', courseId)
        .orderBy('createdAt', 'desc')
        .get();
      
      return materialsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding materials by course: ${error.message}`);
    }
  }

  // Lấy materials theo user
  static async findByUser(userId) {
    try {
      const db = admin.firestore();
      const materialsSnapshot = await db.collection('materials')
        .where('uploadedBy', '==', userId)
        .orderBy('createdAt', 'desc')
        .get();
      
      return materialsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding materials by user: ${error.message}`);
    }
  }

  // Lấy materials theo category
  static async findByCategory(category) {
    try {
      const db = admin.firestore();
      const materialsSnapshot = await db.collection('materials')
        .where('category', '==', category)
        .where('isPublic', '==', true)
        .orderBy('createdAt', 'desc')
        .get();
      
      return materialsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding materials by category: ${error.message}`);
    }
  }

  // Lấy materials theo file type
  static async findByFileType(fileType) {
    try {
      const db = admin.firestore();
      const materialsSnapshot = await db.collection('materials')
        .where('fileType', '==', fileType)
        .where('isPublic', '==', true)
        .orderBy('createdAt', 'desc')
        .get();
      
      return materialsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding materials by file type: ${error.message}`);
    }
  }

  // Cập nhật material
  static async update(id, updateData) {
    try {
      const db = admin.firestore();
      await db.collection('materials').doc(id).update({
        ...updateData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id, ...updateData };
    } catch (error) {
      throw new Error(`Error updating material: ${error.message}`);
    }
  }

  // Xóa material
  static async delete(id) {
    try {
      const db = admin.firestore();
      await db.collection('materials').doc(id).delete();
      return { id };
    } catch (error) {
      throw new Error(`Error deleting material: ${error.message}`);
    }
  }

  // Tăng download count
  static async incrementDownloadCount(id) {
    try {
      const db = admin.firestore();
      await db.collection('materials').doc(id).update({
        downloadCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { id };
    } catch (error) {
      throw new Error(`Error incrementing download count: ${error.message}`);
    }
  }

  // Lấy materials phổ biến (theo download count)
  static async findPopular(limit = 10) {
    try {
      const db = admin.firestore();
      const materialsSnapshot = await db.collection('materials')
        .where('isPublic', '==', true)
        .orderBy('downloadCount', 'desc')
        .limit(limit)
        .get();
      
      return materialsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding popular materials: ${error.message}`);
    }
  }

  // Lấy materials mới nhất
  static async findRecent(limit = 10) {
    try {
      const db = admin.firestore();
      const materialsSnapshot = await db.collection('materials')
        .where('isPublic', '==', true)
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get();
      
      return materialsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      throw new Error(`Error finding recent materials: ${error.message}`);
    }
  }

  // Tìm kiếm materials
  static async search(searchTerm, filters = {}) {
    try {
      const db = admin.firestore();
      let query = db.collection('materials');
      
      // Apply filters
      if (filters.courseId) {
        query = query.where('courseId', '==', filters.courseId);
      }
      if (filters.fileType) {
        query = query.where('fileType', '==', filters.fileType);
      }
      if (filters.category) {
        query = query.where('category', '==', filters.category);
      }
      if (filters.isPublic !== undefined) {
        query = query.where('isPublic', '==', filters.isPublic);
      }
      
      const materialsSnapshot = await query.get();
      
      // Filter by search term (client-side filtering for now)
      const materials = materialsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      if (searchTerm) {
        const searchLower = searchTerm.toLowerCase();
        return materials.filter(material => 
          material.title.toLowerCase().includes(searchLower) ||
          material.description.toLowerCase().includes(searchLower) ||
          material.fileName.toLowerCase().includes(searchLower)
        );
      }
      
      return materials;
    } catch (error) {
      throw new Error(`Error searching materials: ${error.message}`);
    }
  }
}

module.exports = Material;
