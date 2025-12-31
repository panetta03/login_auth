# Google OAuth Consent Screen Setup Guide

## Step-by-Step Instructions

### 1. Navigate to OAuth Consent Screen

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create one if you don't have one)
3. Navigate to: **APIs & Services** → **OAuth consent screen**
   - Direct link: https://console.cloud.google.com/apis/credentials/consent

### 2. Choose User Type

**For Development/Testing:**
- Select **External** (unless you have Google Workspace)
- Click **Create**

**For Production (Google Workspace only):**
- Select **Internal** (only available if you have Google Workspace)
- Click **Create**

### 3. Fill in App Information

**Required Fields:**

1. **App name**: Enter your application name (e.g., "Omnipan Auth Service" or "Auth Service")
2. **User support email**: Your email address
3. **App logo** (optional): Upload a logo if desired
4. **Application home page** (optional): Your website URL
5. **Application privacy policy link** (optional): Privacy policy URL
6. **Application terms of service link** (optional): Terms of service URL
7. **Authorized domains** (optional): Your domain (e.g., `omnipan.com`)

**Developer contact information:**
- **Email addresses**: Your email address (required)

Click **Save and Continue**

### 4. Configure Scopes

This is the critical step for `openid`, `email`, and `profile` scopes.

1. Click **Add or Remove Scopes**

2. You'll see a list of scopes. The scopes you need are:
   - ✅ **openid** - OpenID Connect (usually automatically included)
   - ✅ **email** - See your primary Google Account email address
   - ✅ **profile** - See your personal info, including any personal info you've made publicly available

3. **How to find them:**
   - Look for scopes under **"Sensitive"** or **"User data"** sections
   - Or use the search box to find:
     - Search for "openid" → Select **"openid"**
     - Search for "email" → Select **".../auth/userinfo.email"** (email scope)
     - Search for "profile" → Select **".../auth/userinfo.profile"** (profile scope)

4. **Important:** The scope names in GCP are:
   - `openid` (or `https://www.googleapis.com/auth/openid`)
   - `https://www.googleapis.com/auth/userinfo.email`
   - `https://www.googleapis.com/auth/userinfo.profile`

5. Select the scopes you need and click **Update**

6. Click **Save and Continue**

### 5. Test Users (For External Apps in Testing Mode)

If your app is **External** and in **Testing** mode:

1. Click **Add Users**
2. Add your email address (and any other test users)
3. Click **Add**

**Note:** Only test users can use the app until you publish it.

Click **Save and Continue**

### 6. Summary

Review your configuration and click **Back to Dashboard**

### 7. Publishing Status

**For Testing:**
- Your app will be in **Testing** mode
- Only test users can authenticate
- This is fine for development

**For Production:**
- Click **Publish App** when ready
- Requires verification if using sensitive scopes
- Can take several days for Google to review

## Quick Reference: Scope Names

When configuring scopes, look for these exact scope names:

| Scope Display Name | Full Scope URI |
|-------------------|----------------|
| openid | `https://www.googleapis.com/auth/openid` |
| email | `https://www.googleapis.com/auth/userinfo.email` |
| profile | `https://www.googleapis.com/auth/userinfo.profile` |

**Note:** In your application code, you use the short names (`openid email profile`), but GCP shows the full URIs in the consent screen configuration.

## Verification

After setup, verify:

1. Go to **OAuth consent screen**
2. Check that your scopes are listed under **"Scopes"** section
3. You should see:
   - `https://www.googleapis.com/auth/openid`
   - `https://www.googleapis.com/auth/userinfo.email`
   - `https://www.googleapis.com/auth/userinfo.profile`

## Common Issues

### Issue: Can't find the scopes
**Solution:** 
- Use the search box in the "Add or Remove Scopes" dialog
- Search for "userinfo" to find email and profile scopes
- Search for "openid" to find the openid scope

### Issue: App is in Testing mode
**Solution:**
- This is normal for development
- Add yourself as a test user
- For production, you'll need to publish the app (may require verification)

### Issue: "Sensitive scopes require verification"
**Solution:**
- For testing: Stay in Testing mode and add test users
- For production: You'll need to submit for verification (can take days)

## Next Steps

After configuring the consent screen:

1. ✅ Configure OAuth 2.0 Client ID (see `GCP_OAUTH_CHECKLIST.md`)
2. ✅ Add authorized redirect URI
3. ✅ Test the OAuth flow

