const express = require('express');
const router = express.Router();
const { verifyFirebaseToken, requireRole } = require('../middlewares/firebaseAuth');
const Teacher = require('../models/Teacher');
const ClassModel = require('../models/class');

// GET all teachers
router.get('/', async (req, res) => {
  try {
    const teachers = await Teacher.findAll();
    res.json(teachers);
  } catch (err) { 
    res.status(500).json({ message: err.message }); 
  }
});

// GET teacher by ID
router.get('/:id', async (req, res) => {
  try {
    const teacher = await Teacher.findById(req.params.id);
    if (!teacher) {
      return res.status(404).json({ message: 'Teacher not found' });
    }
    res.json(teacher);
  } catch (err) { 
    res.status(500).json({ message: err.message }); 
  }
});

// POST create teacher
router.post('/', verifyFirebaseToken, requireRole(['teacher']), async (req, res) => {
  try {
    const { name, email, subject } = req.body;
    const teacher = await Teacher.create({ name, email, subject });
    res.status(201).json(teacher);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// PUT update teacher
router.put('/:id', verifyFirebaseToken, requireRole(['teacher']), async (req, res) => {
  try {
    const { name, email, subject } = req.body;
    const teacher = await Teacher.update(req.params.id, { name, email, subject });
    res.json(teacher);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// DELETE teacher
router.delete('/:id', verifyFirebaseToken, requireRole(['teacher']), async (req, res) => {
  try {
    await Teacher.delete(req.params.id);
    res.json({ message: 'Teacher deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST assign class to teacher
router.post('/:id/assign-class', verifyFirebaseToken, requireRole(['teacher']), async (req, res) => {
  try {
    const teacher = await Teacher.findById(req.params.id);
    const { classId } = req.body;
    const cls = await ClassModel.findById(classId);
    if (!teacher || !cls) return res.status(404).json({ message: 'Not found' });

    // Update teacher's classes
    const updatedClasses = [...(teacher.classes || []), classId];
    await Teacher.update(req.params.id, { classes: updatedClasses });

    // Update class teacher
    await ClassModel.update(classId, { teacherId: req.params.id });

    res.json({ teacher: { ...teacher, classes: updatedClasses }, class: cls });
  } catch (err) { 
    res.status(500).json({ message: err.message }); 
  }
});

module.exports = router;