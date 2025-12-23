import { Router } from 'express';
import { authController } from '../controllers/auth.controller';
import { authRateLimiter } from '../../middleware/rateLimit.middleware';

const router = Router();

// OAuth login initiation
router.get('/login/:provider', authRateLimiter, authController.initiateLogin);

// OAuth callback
router.get('/callback/:provider', authRateLimiter, authController.handleCallback);

// Logout
router.post('/logout', authController.logout);

// Logout all sessions
router.post('/logout/all', authController.logoutAll);

export default router;

