# Google Cloud Platform OAuth Configuration Checklist

## Required GCP Configuration

### 1. OAuth 2.0 Client ID Setup

**Location:** Google Cloud Console → APIs & Services → Credentials

**Required Settings:**

#### Authorized JavaScript origins
Add these if your frontend will make direct OAuth calls:
```
https://2tqnibdpg0.execute-api.us-east-2.amazonaws.com
```

**Note:** For server-side OAuth flow (which this service uses), JavaScript origins are typically not required.

#### Authorized redirect URIs
**CRITICAL:** Must match exactly (including trailing slash, if any):

```
https://2tqnibdpg0.execute-api.us-east-2.amazonaws.com/dev/api/v1/auth/callback/google
```

**Important:**
- Must use `https://` (not `http://`)
- Must include the `/dev` environment prefix
- Must match the exact path: `/api/v1/auth/callback/google`
- Case-sensitive
- No trailing slash (unless your app expects it)

#### OAuth Client Type
- Should be: **Web application**

#### Application Type
- Should be: **Web server**

### 2. OAuth Consent Screen

**Location:** Google Cloud Console → APIs & Services → OAuth consent screen

**Required Settings:**
- **User Type:** External (for testing) or Internal (for Google Workspace)
- **App name:** Your application name (e.g., "Omnipan Auth Service")
- **User support email:** Your email
- **Developer contact information:** Your email
- **Scopes:** 
  - `openid`
  - `email`
  - `profile`

### 3. API Enablement

**Location:** Google Cloud Console → APIs & Services → Library

**Required APIs:**
- ❌ **None required!** 

The OAuth 2.0 flow uses public Google endpoints that don't require API enablement:
- `https://accounts.google.com/o/oauth2/v2/auth` (authorization)
- `https://oauth2.googleapis.com/token` (token exchange)
- `https://www.googleapis.com/oauth2/v3/certs` (JWKS for ID token verification)

User information (email, name, picture) is extracted directly from the ID token payload, so no People API or Google+ API is needed.

### 4. Client ID and Secret

**Location:** Google Cloud Console → APIs & Services → Credentials

**Required:**
- **Client ID:** Should be in format `xxxxx-xxxxx.apps.googleusercontent.com`
- **Client Secret:** Should start with `GOCSPX-`

**Storage:**
- These should be stored in AWS Secrets Manager as:
  ```json
  {
    "GOOGLE_CLIENT_ID": "your-client-id",
    "GOOGLE_CLIENT_SECRET": "your-client-secret"
  }
  ```

## Verification Steps

### 1. Check Redirect URI Match

The redirect URI in GCP must **exactly match** what your application sends:

**What your app sends (from `config.oauth.google.redirectUri`):**
```
https://2tqnibdpg0.execute-api.us-east-2.amazonaws.com/dev/api/v1/auth/callback/google
```

**What should be in GCP:**
```
https://2tqnibdpg0.execute-api.us-east-2.amazonaws.com/dev/api/v1/auth/callback/google
```

### 2. Check OAuth Scopes

Your app requests these scopes:
- `openid`
- `email`
- `profile`

Make sure these are approved in the OAuth consent screen.

### 3. Test OAuth Flow

1. Visit: `https://2tqnibdpg0.execute-api.us-east-2.amazonaws.com/dev/api/v1/auth/login/google`
2. Should redirect to Google OAuth consent page
3. After consent, should redirect back to callback URL with `code` and `state` parameters

### 4. Common Issues

#### Issue: "redirect_uri_mismatch" error
**Cause:** Redirect URI in GCP doesn't match what the app sends
**Fix:** 
- Check exact URL in GCP (case-sensitive, no trailing slash)
- Verify the URL includes `/dev` environment prefix
- Ensure `https://` not `http://`

#### Issue: "invalid_client" error
**Cause:** Client ID or Secret is incorrect
**Fix:**
- Verify Client ID and Secret in AWS Secrets Manager match GCP
- Check for typos or extra spaces
- Ensure secret starts with `GOCSPX-`

#### Issue: "access_denied" error
**Cause:** User denied consent or scopes not approved
**Fix:**
- Check OAuth consent screen configuration
- Verify required scopes are approved
- Check if app is in testing mode (limited to test users)

#### Issue: Timeout on login endpoint
**Cause:** Usually not a GCP issue, but could be if:
- OAuth consent screen is misconfigured
**Fix:**
- Check OAuth consent screen is published (if not in testing mode)

## Quick Verification Commands

### Check AWS Secrets Manager
```bash
aws secretsmanager get-secret-value --secret-id googleoauth --region us-east-2 --query 'SecretString' --output text
```

Should return JSON with `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`.

### Check Application Configuration
The app uses:
- **Redirect URI:** From `GOOGLE_REDIRECT_URI` env var or default
- **Scopes:** `openid email profile`
- **Response Type:** `code` (authorization code flow)

## GCP Console Links

- **Credentials:** https://console.cloud.google.com/apis/credentials
- **OAuth Consent Screen:** https://console.cloud.google.com/apis/credentials/consent
- **API Library:** https://console.cloud.google.com/apis/library

