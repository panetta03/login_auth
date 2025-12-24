import { Router } from 'express';
import { userController } from '../controllers/user.controller';
import { authMiddleware } from '../../middleware/auth.middleware';

const router = Router();

// Get current user profile
router.get('/me', authMiddleware, userController.getMe);

// Get user sessions
router.get('/sessions', authMiddleware, userController.getSessions);

export default router;
