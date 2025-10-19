const express = require('express');
const router = express.Router();
const { verifyFirebaseToken, requireRole } = require('../middlewares/firebaseAuth');
const Assignment = require('../models/assignment');

// GET all assignments
router.get('/', async (req, res) => {
  try {
    const assignments = await Assignment.findAll();
    res.json(assignments);
  } catch (err) { 
    res.status(500).json({ message: err.message }); 
  }
});

// GET assignment by ID
router.get('/:id', async (req, res) => {
  try {
    const assignment = await Assignment.findById(req.params.id);
    if (!assignment) {
      return res.status(404).json({ message: 'Assignment not found' });
    }
    res.json(assignment);
  } catch (err) { 
    res.status(500).json({ message: err.message }); 
  }
});

// POST create assignment
router.post('/', verifyFirebaseToken, requireRole(['teacher']), async (req, res) => {
  try {
    const { title, description, classId, dueDate, createdBy } = req.body;
    const assignment = await Assignment.create({
      title, 
      description, 
      classId, 
      dueDate, 
      createdBy
    });
    res.status(201).json(assignment);
  } catch (err) { 
    res.status(400).json({ message: err.message }); 
  }
});

// PUT update assignment
router.put('/:id', verifyFirebaseToken, requireRole(['teacher']), async (req, res) => {
  try {
    const { title, description, classId, dueDate } = req.body;
    const assignment = await Assignment.update(req.params.id, {
      title, 
      description, 
      classId, 
      dueDate
    });
    res.json(assignment);
  } catch (err) { 
    res.status(400).json({ message: err.message }); 
  }
});

// DELETE assignment
router.delete('/:id', verifyFirebaseToken, requireRole(['teacher']), async (req, res) => {
  try {
    await Assignment.delete(req.params.id);
    res.json({ message: 'Assignment deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET assignments by class
router.get('/class/:classId', async (req, res) => {
  try {
    const assignments = await Assignment.findByClass(req.params.classId);
    res.json(assignments);
  } catch (err) { 
    res.status(500).json({ message: err.message }); 
  }
});

module.exports = router;