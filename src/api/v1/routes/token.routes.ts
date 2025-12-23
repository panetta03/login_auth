import { Router } from 'express';
import { tokenController } from '../controllers/token.controller';
import { authRateLimiter } from '../../middleware/rateLimit.middleware';

const router = Router();

// Refresh token
router.post('/refresh', authRateLimiter, tokenController.refresh);

// Validate token (introspection endpoint)
router.post('/validate', tokenController.validate);

// Get token info
router.get('/info', tokenController.getInfo);

export default router;

