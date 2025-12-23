-- Create sessions table
-- Note: Sessions represent logical login contexts; refresh tokens represent credentials used to extend those sessions.
CREATE TABLE sessions (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  access_token_jti TEXT NOT NULL UNIQUE, -- JWT ID (jti claim), not the full token
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  last_activity_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMP WITH TIME ZONE,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_access_token_jti ON sessions(access_token_jti);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);

