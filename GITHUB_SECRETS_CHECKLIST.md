# GitHub Secrets Checklist - ALL Required Secrets

## 🔐 Complete List of Secrets to Add

You need to add **ALL** of these to your GitHub repository secrets:

### Required Secrets (Must Add):

1. **`TWELVE_DATA_API_KEY`**
   - Value: `your_twelve_data_key`
   - Purpose: Access to Twelve Data API for stock quotes

2. **`FMP_API_KEY`**
   - Value: `your_fmp_key`
   - Purpose: Access to Financial Modeling Prep API for analyst targets

3. **`DISCORD_BOT_TOKEN`**
   - Value: `your_discord_bot_token`
   - Purpose: Discord bot authentication token
   - ⚠️ **SECURITY**: Keep this secret! Anyone with this token can control your bot

4. **`DISCORD_CHANNEL_ID`**
   - Value: `your_channel_id`
   - Purpose: Target Discord channel for alerts
   - Note: This is less sensitive but still good to keep in secrets

5. **`GIST_ID`**
   - Value: `your_gist_id`
   - Purpose: GitHub Gist ID for state persistence

6. **`GH_PAT`**
   - Value: `YOUR_GITHUB_PAT_TOKEN` (get from GitHub Settings → Developer settings → Personal access tokens)
   - Purpose: GitHub Personal Access Token for gist access
   - ⚠️ **SECURITY**: Keep this secret! This token has repo and gist access

### Optional Secrets (Have Defaults):

7. **`ALERT_THRESHOLD_PCT`** (Optional)
   - Value: `90`
   - Purpose: Minimum percentage gain to trigger alert
   - Default: 90 if not set

8. **`HAIRCUT_RATE`** (Optional)
   - Value: `0.125`
   - Purpose: Haircut rate for anchor calculation (12.5%)
   - Default: 0.125 if not set

---

## 📋 How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. For each secret above:
   - **Name**: Use the exact name (e.g., `TWELVE_DATA_API_KEY`)
   - **Value**: Paste the corresponding value
   - Click **Add secret**

---

## ✅ Verification Checklist

After adding all secrets, verify:

- [ ] `TWELVE_DATA_API_KEY` added
- [ ] `FMP_API_KEY` added
- [ ] `DISCORD_BOT_TOKEN` added
- [ ] `DISCORD_CHANNEL_ID` added
- [ ] `GIST_ID` added
- [ ] `GH_PAT` added
- [ ] `ALERT_THRESHOLD_PCT` added (optional)
- [ ] `HAIRCUT_RATE` added (optional)

---

## 🔒 Security Notes

### ⚠️ IMPORTANT: Never Commit Secrets!

- ✅ **DO**: Store all secrets in GitHub Secrets
- ✅ **DO**: Use environment variables in code
- ❌ **DON'T**: Commit API keys or tokens to git
- ❌ **DON'T**: Hardcode secrets in code files
- ❌ **DON'T**: Share secrets in public repositories

### Files to Check:

- ✅ `bot.py` - Uses `os.getenv()` (correct!)
- ✅ `.github/workflows/stock_alert.yml` - Uses `${{ secrets.* }}` (correct!)
- ⚠️ Test files - May contain test keys (should be cleaned up or gitignored)

### If Secrets Are Exposed:

If you accidentally commit secrets:
1. **Immediately revoke/regenerate** the exposed tokens/keys
2. Remove from git history (if possible)
3. Add new secrets to GitHub Secrets
4. Update `.gitignore` to prevent future commits

---

## 🧹 Cleanup

Test files with hardcoded keys should be:
- Deleted if not needed, OR
- Added to `.gitignore`, OR
- Use environment variables instead
