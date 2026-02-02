# GitHub Gist and PAT Setup Guide

## Quick Setup

### Option 1: Automated (Recommended)

1. **Create GitHub Personal Access Token** (see instructions below)
2. **Run the setup script**:
   ```bash
   export GH_PAT='your_github_token_here'
   python create_gist.py
   ```
3. Copy the GIST_ID from the output
4. Add it to GitHub Secrets

### Option 2: Manual Setup

Follow the manual instructions below.

---

## Step 1: Create GitHub Personal Access Token (PAT)

1. **Go to GitHub Settings**:
   - Visit: https://github.com/settings/tokens
   - Or: GitHub → Your Profile → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Generate New Token**:
   - Click "Generate new token" → "Generate new token (classic)"
   - Give it a descriptive name: `Discord Stock Bot - Gist Access`
   - Set expiration (recommended: 90 days or No expiration for automation)
   - **Select scopes**: Check `gist` (this is the only required scope)
   - Click "Generate token"

3. **Copy the Token**:
   - ⚠️ **IMPORTANT**: Copy the token immediately - you won't be able to see it again!
   - It will look like: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

4. **Save the Token**:
   - Add it to your GitHub Secrets as `GH_PAT`
   - Repository → Settings → Secrets and variables → Actions → New repository secret
   - Name: `GH_PAT`
   - Value: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

## Step 2: Create GitHub Gist

### Method A: Using the Script (Easiest)

1. **Run the script**:
   ```bash
   cd "/Users/logangarcia/Downloads/discord stock alert bot"
   source venv/bin/activate
   export GH_PAT='your_token_from_step_1'
   python create_gist.py
   ```

2. **Copy the GIST_ID** from the output

3. **Add to GitHub Secrets**:
   - Name: `GIST_ID`
   - Value: `[the_gist_id_from_output]`

### Method B: Manual Creation

1. **Go to GitHub Gists**:
   - Visit: https://gist.github.com
   - Click "New gist" (or the "+" icon)

2. **Create the Gist**:
   - **Filename**: `state.json`
   - **Content**: 
     ```json
     {}
     ```
   - **Visibility**: Select "Create secret gist" (important!)
   - Click "Create secret gist"

3. **Get the Gist ID**:
   - After creating, the URL will be: `https://gist.github.com/[username]/[gist_id]`
   - Copy the `[gist_id]` part (the long alphanumeric string)
   - Example: If URL is `https://gist.github.com/user/abc123def456`, the ID is `abc123def456`

4. **Add to GitHub Secrets**:
   - Name: `GIST_ID`
   - Value: `[gist_id]`

---

## Step 3: Verify Setup

After setting up both:

1. **Check GitHub Secrets**:
   - Go to: Repository → Settings → Secrets and variables → Actions
   - Verify you have:
     - `GH_PAT` (your GitHub token)
     - `GIST_ID` (the gist ID)

2. **Test the Setup** (optional):
   ```bash
   export GH_PAT='your_token'
   export GIST_ID='your_gist_id'
   python create_gist.py  # Should show existing gist info
   ```

---

## Security Notes

- ✅ **Gist is Secret**: The gist is private, only you can see it
- ✅ **Minimal Permissions**: PAT only has `gist` scope (read/write gists only)
- ✅ **Token Safety**: Never commit tokens to git - always use GitHub Secrets
- ✅ **State Privacy**: The gist only stores which symbols were alerted today (no sensitive data)

---

## Troubleshooting

### "Invalid token" error:
- Verify token has `gist` scope
- Check if token expired
- Regenerate token if needed

### "Gist not found" error:
- Verify GIST_ID is correct
- Check that gist exists and is accessible
- Ensure PAT has access to the gist

### Script doesn't work:
- Make sure `requests` is installed: `pip install requests`
- Check that token is valid
- Try manual creation method instead

---

## Quick Reference

**Required GitHub Secrets:**
- `GH_PAT`: GitHub Personal Access Token (with `gist` scope)
- `GIST_ID`: ID of the secret gist for state storage

**Gist Structure:**
```json
{
  "2026-02-01": ["SYMBOL1", "SYMBOL2"],
  "2026-02-02": ["SYMBOL3"]
}
```

The bot automatically updates this file to track which symbols have been alerted each day.
