import { Router } from 'express';

export const authRouter = Router();

authRouter.post('/login', (req, res) => {
  // TODO: Implement real auth
  const { username, password } = req.body;
  if (username === 'admin' && password === 'admin') {
    return res.json({ token: 'mock-token', role: 'instructor' });
  }
  return res.status(401).json({ message: 'Invalid credentials' });
});















