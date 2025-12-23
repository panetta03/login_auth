import { z } from 'zod';

// Auth endpoint schemas
export const loginParamsSchema = z.object({
  provider: z.enum(['google']), // Add more providers as they're implemented
});

export const callbackQuerySchema = z.object({
  code: z.string().min(1),
  state: z.string().min(1),
  error: z.string().optional(),
});

// Token endpoint schemas
export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1),
});

export const validateTokenSchema = z.object({
  token: z.string().min(1),
});

// User endpoint schemas (no request body schemas needed for GET endpoints)

// Common validation helpers
export function validateRequest<T>(
  schema: z.ZodSchema<T>,
  data: unknown
): T {
  return schema.parse(data);
}




