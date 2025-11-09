const express = require('express');
const router = express.Router();
const { verifyFirebaseToken, requireRole } = require('../middleware/firebaseAuth');
const { Course } = require('../models');

// GET all classes
router.get('/', async (req, res) => {
  try {
    const classes = await Course.findAll();
    res.json(classes);
  } catch (err) { 
    res.status(500).json({ message: err.message }); 
  }
});

// GET class by ID
router.get('/:id', async (req, res) => {
  try {
    const classData = await ClassModel.findById(req.params.id);
    if (!classData) {
      return res.status(404).json({ message: 'Class not found' });
    }
    res.json(classData);
  } catch (err) { 
    res.status(500).json({ message: err.message }); 
  }
});

// POST create class
router.post('/', verifyFirebaseToken, requireRole(['teacher']), async (req, res) => {
  try {
    const { name, description, teacherId, semester, year } = req.body;
    const classData = await ClassModel.create({ 
      name, 
      description, 
      teacherId, 
      semester, 
      year 
    });
    res.status(201).json(classData);
  } catch (err) { 
    res.status(400).json({ message: err.message }); 
  }
});

// PUT update class
router.put('/:id', verifyFirebaseToken, requireRole(['teacher']), async (req, res) => {
  try {
    const { name, description, teacherId, semester, year } = req.body;
    const classData = await ClassModel.update(req.params.id, { 
      name, 
      description, 
      teacherId, 
      semester, 
      year 
    });
    res.json(classData);
  } catch (err) { 
    res.status(400).json({ message: err.message }); 
  }
});

// DELETE class
router.delete('/:id', verifyFirebaseToken, requireRole(['teacher']), async (req, res) => {
  try {
    await ClassModel.delete(req.params.id);
    res.json({ message: 'Class deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET classes by teacher
router.get('/teacher/:teacherId', async (req, res) => {
  try {
    const classes = await ClassModel.findByTeacher(req.params.teacherId);
    res.json(classes);
  } catch (err) { 
    res.status(500).json({ message: err.message }); 
  }
});

module.exports = router;