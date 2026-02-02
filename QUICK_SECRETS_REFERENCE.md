# Quick Secrets Reference

## 🚨 ALL 8 Secrets to Add to GitHub

Copy-paste this list when adding secrets:

| Secret Name | Value |
|------------|-------|
| `TWELVE_DATA_API_KEY` | `your_twelve_data_key` |
| `FMP_API_KEY` | `your_fmp_key` |
| `DISCORD_BOT_TOKEN` | `your_discord_bot_token` |
| `DISCORD_CHANNEL_ID` | `your_channel_id` |
| `GIST_ID` | `your_gist_id` |
| `GH_PAT` | `YOUR_GITHUB_PAT_TOKEN` |
| `ALERT_THRESHOLD_PCT` | `90` |
| `HAIRCUT_RATE` | `0.125` |

## Steps:

1. Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`
2. Click **"New repository secret"**
3. Add each secret above (name + value)
4. Repeat 8 times

## ✅ Security Status

- ✅ Test files with hardcoded keys: **DELETED**
- ✅ `.gitignore` created: **YES**
- ✅ Bot code uses env vars: **YES**
- ✅ Workflow uses secrets: **YES**
- ⚠️ **Action Required**: Add all 8 secrets to GitHub!

---

**Note**: The last 2 secrets (`ALERT_THRESHOLD_PCT` and `HAIRCUT_RATE`) are optional since they have defaults, but it's good practice to add them anyway.
