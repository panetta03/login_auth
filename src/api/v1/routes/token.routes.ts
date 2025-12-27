import { Router } from 'express';
import { tokenController } from '../controllers/token.controller';
import { authRateLimiter } from '../../middleware/rateLimit.middleware';

const router = Router();

// Refresh token
router.post('/refresh', authRateLimiter, tokenController.refresh);

// Validate token (introspection endpoint for debugging/admin)
router.post('/validate', tokenController.validate);

export default router;
