const express = require('express');
const router = express.Router();
const { verifyFirebaseToken, requireRole } = require('../middleware/firebaseAuth');
const { Submission } = require('../models');

// GET all submissions
router.get('/', async (req, res) => {
  try {
    const submissions = await Submission.findAll();
    res.json(submissions);
  } catch (err) { 
    res.status(500).json({ message: err.message }); 
  }
});

// GET submission by ID
router.get('/:id', async (req, res) => {
  try {
    const submission = await Submission.findById(req.params.id);
    if (!submission) {
      return res.status(404).json({ message: 'Submission not found' });
    }
    res.json(submission);
  } catch (err) { 
    res.status(500).json({ message: err.message }); 
  }
});

// POST create submission
router.post('/', verifyFirebaseToken, async (req, res) => {
  try {
    const { assignmentId, studentId, content, fileUrl } = req.body;
    const submission = await Submission.create({
      assignmentId, 
      studentId, 
      content, 
      fileUrl
    });
    res.status(201).json(submission);
  } catch (err) { 
    res.status(400).json({ message: err.message }); 
  }
});

// PUT update submission
router.put('/:id', verifyFirebaseToken, async (req, res) => {
  try {
    const { content, fileUrl } = req.body;
    const submission = await Submission.update(req.params.id, {
      content, 
      fileUrl
    });
    res.json(submission);
  } catch (err) { 
    res.status(400).json({ message: err.message }); 
  }
});

// DELETE submission
router.delete('/:id', verifyFirebaseToken, async (req, res) => {
  try {
    await Submission.delete(req.params.id);
    res.json({ message: 'Submission deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET submissions by assignment
router.get('/assignment/:assignmentId', async (req, res) => {
  try {
    const submissions = await Submission.findByAssignment(req.params.assignmentId);
    res.json(submissions);
  } catch (err) { 
    res.status(500).json({ message: err.message }); 
  }
});

// GET submissions by student
router.get('/student/:studentId', verifyFirebaseToken, async (req, res) => {
  try {
    const submissions = await Submission.findByStudent(req.params.studentId);
    res.json(submissions);
  } catch (err) { 
    res.status(500).json({ message: err.message }); 
  }
});

// PUT grade submission
router.put('/:id/grade', verifyFirebaseToken, requireRole(['teacher']), async (req, res) => {
  try {
    const { grade, feedback } = req.body;
    const submission = await Submission.update(req.params.id, {
      grade, 
      feedback
    });
    res.json(submission);
  } catch (err) { 
    res.status(400).json({ message: err.message }); 
  }
});

module.exports = router;