export interface Database {
  users: UserTable;
  sessions: SessionTable;
  refresh_tokens: RefreshTokenTable;
  audit_logs: AuditLogTable;
}

export interface UserTable {
  id: string;
  email: string;
  name: string | null;
  picture: string | null;
  provider: string;
  provider_id: string;
  created_at: Date;
  updated_at: Date;
  last_activity_at: Date | null;
}

export interface SessionTable {
  id: string;
  user_id: string;
  access_token_jti: string; // JWT ID (jti claim), not the full token
  expires_at: Date;
  last_activity_at: Date;
  revoked_at: Date | null;
  ip_address: string | null;
  user_agent: string | null;
  created_at: Date;
}

export interface RefreshTokenTable {
  id: string;
  session_id: string; // Links refresh token to session
  user_id: string;
  token: string; // Opaque refresh token (first-class credential)
  expires_at: Date;
  revoked_at: Date | null;
  last_used_at: Date | null; // Track last usage for inactivity enforcement
  created_at: Date;
}

export interface AuditLogTable {
  id: string;
  user_id: string | null;
  action: string;
  provider: string | null;
  ip_address: string | null;
  user_agent: string | null;
  success: boolean;
  error_message: string | null;
  metadata: Record<string, unknown> | null;
  created_at: Date;
}
