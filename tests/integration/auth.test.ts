import request from 'supertest';
import app from '../../src/app';
import { ensureRedisConnected } from '../../src/config/redis';

describe('Auth API Integration Tests', () => {
  beforeAll(async () => {
    // Ensure Redis is connected before running tests
    await ensureRedisConnected();
  });
  describe('GET /api/v1/auth/login/:provider', () => {
    it('should redirect to OAuth provider', async () => {
      const response = await request(app)
        .get('/api/v1/auth/login/google')
        .expect(302);

      expect(response.headers.location).toContain('accounts.google.com');
    });

    it('should return 400 for invalid provider', async () => {
      await request(app)
        .get('/api/v1/auth/login/invalid')
        .expect(400);
    });
  });

  describe('GET /health', () => {
    it('should return 200 OK', async () => {
      await request(app)
        .get('/health')
        .expect(200)
        .expect((res) => {
          expect(res.body.status).toBe('ok');
        });
    });
  });
});




