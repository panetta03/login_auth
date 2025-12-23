import { Router, Request, Response } from 'express';
import { tokenService } from '../../../services/token/token.service';

const router = Router();

// JWKS endpoint for JWT public key
router.get('/', (_req: Request, res: Response) => {
  try {
    const jwks = tokenService.getJWKS();

    res.set('Cache-Control', 'public, max-age=600'); // 10 minutes
    res.json({
      keys: jwks,
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate JWKS' });
  }
});

export default router;

