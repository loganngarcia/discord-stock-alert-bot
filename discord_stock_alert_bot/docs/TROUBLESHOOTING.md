# Troubleshooting Guide

Common issues and solutions for the Discord Stock Alert Bot.

## Table of Contents

- [Bot Not Sending Messages](#bot-not-sending-messages)
- [No Symbols Triggering Alerts](#no-symbols-triggering-alerts)
- [API Errors](#api-errors)
- [GitHub Actions Issues](#github-actions-issues)
- [State Persistence Issues](#state-persistence-issues)

## Bot Not Sending Messages

### Symptoms
- Bot runs but no Discord messages appear
- GitHub Actions shows successful runs

### Possible Causes & Solutions

1. **No qualifying symbols**
   - **Check**: This is normal! Bot only alerts on ≥90% gains
   - **Solution**: Wait for a stock that actually gains ≥90%

2. **Discord bot token invalid**
   - **Check**: Verify token in Discord Developer Portal
   - **Solution**: Regenerate token if needed, update GitHub Secret

3. **Bot lacks permissions**
   - **Check**: Bot needs "Send Messages" permission
   - **Solution**: Re-invite bot with correct permissions

4. **Wrong channel ID**
   - **Check**: Verify channel ID is correct
   - **Solution**: Get channel ID again (right-click → Copy ID)

5. **Outside market hours**
   - **Check**: Bot only runs 10am-3pm PT on weekdays
   - **Solution**: This is expected behavior

## No Symbols Triggering Alerts

### Symptoms
- Bot runs successfully but no alerts

### This is Normal!

The bot is designed to only alert on ≥90% gains, which are rare events. If no stocks meet this threshold, the bot exits silently (as designed).

### To Verify Bot is Working

1. **Check GitHub Actions logs**:
   - Go to Actions tab
   - Click on latest run
   - Check for "No symbols meet threshold" message

2. **Test with lower threshold** (temporarily):
   ```bash
   # In GitHub Secrets, temporarily set:
   ALERT_THRESHOLD_PCT = 10  # Test with 10% instead of 90%
   ```

3. **Run locally during market hours**:
   ```bash
   python bot.py
   # Should show processing messages if working
   ```

## API Errors

### Twelve Data API

**Error: Market movers endpoint requires paid plan**
- **Solution**: Bot automatically falls back to checking popular stocks
- **Impact**: Still works, just checks different stocks

**Error: Rate limit exceeded**
- **Solution**: Upgrade plan or wait for rate limit reset
- **Impact**: Bot will skip that run, try again next cycle

**Error: Invalid API key**
- **Solution**: Verify API key in GitHub Secrets
- **Check**: Key should start with your account identifier

### Financial Modeling Prep API

**Error: 401 Unauthorized**
- **Solution**: Verify API key is valid and active
- **Check**: Some endpoints may require subscription

**Error: No analyst targets**
- **Solution**: This is normal for some symbols
- **Impact**: Bot will show "N/A" for anchor, still alerts

### Discord API

**Error: 401 Unauthorized**
- **Solution**: Bot token may be invalid or expired
- **Fix**: Regenerate token in Discord Developer Portal

**Error: 403 Forbidden**
- **Solution**: Bot lacks permissions
- **Fix**: Re-invite bot with "Send Messages" permission

**Error: 404 Not Found**
- **Solution**: Channel ID is incorrect
- **Fix**: Get correct channel ID (right-click → Copy ID)

## GitHub Actions Issues

### Workflow Not Running

**Check**:
1. Workflow file exists: `.github/workflows/stock_alert.yml`
2. Cron schedule is correct: `*/5 17-23 * * 1-5`
3. Workflow is enabled in repository settings

**Solution**: Enable workflows in Settings → Actions → General

### Secrets Not Found

**Error**: `Secret not found: TWELVE_DATA_API_KEY`

**Solution**:
1. Verify secrets are in **Actions** secrets (not Codebases/Dependabot)
2. Check secret names match exactly (case-sensitive)
3. Ensure secrets are added to repository (not organization)

### Workflow Fails

**Check logs**:
1. Go to Actions tab
2. Click failed workflow run
3. Expand failed step
4. Check error messages

**Common fixes**:
- Verify all required secrets are set
- Check Python version compatibility
- Ensure dependencies install correctly

## State Persistence Issues

### Gist Not Updating

**Symptoms**: Same symbols alerting multiple times per day

**Possible causes**:
1. **GIST_ID incorrect**
   - **Solution**: Verify Gist ID from Gist URL

2. **GH_PAT lacks permissions**
   - **Solution**: Ensure token has `gist` scope

3. **Gist deleted or inaccessible**
   - **Solution**: Create new Gist and update GIST_ID secret

### State File Corrupted

**Symptoms**: Bot errors when reading state

**Solution**:
1. Go to Gist: https://gist.github.com/YOUR_USERNAME/GIST_ID
2. Edit `state.json`
3. Reset to: `{}`
4. Save

## Debugging Tips

### Enable Verbose Logging

Add debug prints to bot.py:
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Test Individual Components

```bash
# Test API connections
python -c "from bot import StockDataFetcher; sf = StockDataFetcher('key'); print(sf.get_quote('AAPL'))"

# Test state manager
python -c "from bot import GistStateManager; gm = GistStateManager('gist_id', 'pat'); print(gm.get_state())"

# Test Discord API
python -c "import requests; r = requests.post('https://discord.com/api/v10/channels/CHANNEL_ID/messages', headers={'Authorization': 'Bot TOKEN'}, json={'content': 'test'}); print(r.status_code)"
```

### Check Time Window

```python
from bot import check_time_window
print(f"In market hours: {check_time_window()}")
```

## Getting Help

If you're still experiencing issues:

1. **Check GitHub Issues**: Search existing issues
2. **Create New Issue**: Use the bug report template
3. **Include**:
   - Error messages
   - GitHub Actions logs
   - Environment details
   - Steps to reproduce

## Common Misconceptions

### "Bot should alert on every stock movement"
- **No**: Bot only alerts on ≥90% gains (rare events)

### "Bot should run 24/7"
- **No**: Bot only runs during market hours (10am-3pm PT, weekdays)

### "Bot should send heartbeat messages"
- **No**: Bot is designed to be silent when no qualifying symbols

### "All stocks should have analyst targets"
- **No**: Many stocks don't have analyst coverage, this is normal
