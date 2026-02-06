# Configuration Guide

Complete guide to configuring the Discord Stock Alert Bot.

## Table of Contents

- [Environment Variables](#environment-variables)
- [GitHub Secrets Setup](#github-secrets-setup)
- [Discord Setup](#discord-setup)
- [API Keys](#api-keys)
- [GitHub Gist Setup](#github-gist-setup)
- [Advanced Configuration](#advanced-configuration)

## Environment Variables

All configuration is done via environment variables. For production (GitHub Actions), these are set as GitHub Secrets.

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `TWELVE_DATA_API_KEY` | Twelve Data API key | `your_twelve_data_key` |
| `FMP_API_KEY` | Financial Modeling Prep API key | `your_fmp_key` |
| `DISCORD_BOT_TOKEN` | Discord bot token | `your_discord_bot_token` |
| `DISCORD_CHANNEL_ID` | Discord channel ID | `your_channel_id` |
| `GIST_ID` | GitHub Gist ID | `your_gist_id` |
| `GH_PAT` | GitHub Personal Access Token | `ghp_your_token_here` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ALERT_THRESHOLD_PCT` | Minimum % gain to trigger alert | `90` |
| `HAIRCUT_RATE` | Haircut rate for anchor (0.125 = 12.5%) | `0.125` |

## GitHub Secrets Setup

### Step 1: Navigate to Secrets

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

### Step 2: Add Each Secret

For each required secret:

1. **Name**: Enter the exact variable name (e.g., `TWELVE_DATA_API_KEY`)
2. **Value**: Paste the secret value
3. Click **Add secret**

Repeat for all 6 required secrets (and 2 optional if desired).

### Step 3: Verify

After adding secrets, verify they appear in the "Repository secrets" list.

## Discord Setup

### Creating a Discord Bot

1. Go to https://discord.com/developers/applications
2. Click **New Application**
3. Give it a name (e.g., "Stock Alert Bot")
4. Go to **Bot** section
5. Click **Add Bot** → **Yes, do it!**
6. Under **Token**, click **Reset Token** or **Copy**
7. **Save the token** - this is your `DISCORD_BOT_TOKEN`

### Getting Channel ID

1. Enable Developer Mode in Discord:
   - User Settings → Advanced → Developer Mode (ON)
2. Right-click on your target channel
3. Click **Copy ID**
4. This is your `DISCORD_CHANNEL_ID`

### Inviting Bot to Server

1. In Discord Developer Portal, go to **OAuth2** → **URL Generator**
2. Select scopes:
   - ✅ `bot`
3. Select permissions:
   - ✅ `Send Messages`
   - ✅ `View Channels` (usually needed)
4. Copy the generated URL
5. Open URL in browser to invite bot
6. Select your server and authorize

## API Keys

### Twelve Data API Key

1. Go to https://twelvedata.com/
2. Sign up for an account
3. Go to API Keys section
4. Copy your API key

**Note**: Market movers endpoint requires paid plan. Free tier works for quote endpoint.

### Financial Modeling Prep API Key

1. Go to https://site.financialmodelingprep.com/
2. Sign up for an account
3. Go to API section
4. Copy your API key

**Note**: Some endpoints may require subscription tier.

## GitHub Gist Setup

### Creating the Gist

1. Go to https://gist.github.com
2. Click **New gist** (or the "+" icon)
3. **Filename**: `state.json`
4. **Content**: `{}`
5. **Visibility**: Select **Create secret gist** (important!)
6. Click **Create secret gist**

### Getting Gist ID

After creating the gist:
- URL format: `https://gist.github.com/username/GIST_ID`
- Copy the `GIST_ID` part (long alphanumeric string)
- This is your `GIST_ID` secret

### GitHub Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click **Generate new token** → **Generate new token (classic)**
3. **Name**: `Discord Stock Bot`
4. **Expiration**: Choose (90 days or No expiration)
5. **Select scopes**:
   - ✅ `repo` (for repository access)
   - ✅ `gist` (for Gist access)
6. Click **Generate token**
7. **Copy immediately** - this is your `GH_PAT`

## Advanced Configuration

### Changing Alert Threshold

To change the minimum gain percentage:

```bash
# In GitHub Secrets
ALERT_THRESHOLD_PCT = 100  # Only alert on 100%+ gains
```

### Adjusting Haircut Rate

To change the anchor haircut:

```bash
# In GitHub Secrets
HAIRCUT_RATE = 0.20  # 20% haircut instead of 12.5%
```

### Local Development

For local testing, create a `.env` file (gitignored):

```bash
TWELVE_DATA_API_KEY=your_key
FMP_API_KEY=your_key
DISCORD_BOT_TOKEN=your_token
DISCORD_CHANNEL_ID=your_channel_id
GIST_ID=your_gist_id
GH_PAT=your_pat
ALERT_THRESHOLD_PCT=90
HAIRCUT_RATE=0.125
```

Then load with:
```python
from dotenv import load_dotenv
load_dotenv()
```

## Verification

### Test Configuration

```bash
# Test that all variables are set
python -c "
import os
required = ['TWELVE_DATA_API_KEY', 'FMP_API_KEY', 'DISCORD_BOT_TOKEN', 
            'DISCORD_CHANNEL_ID', 'GIST_ID', 'GH_PAT']
for var in required:
    val = os.getenv(var)
    print(f'{var}: {\"✅\" if val else \"❌\"}')"
```

### Test Bot

```bash
# Run bot (will exit silently outside market hours)
python bot.py

# Should see: 'Outside market hours or not a weekday. Exiting silently.'
```

## Troubleshooting

### Secrets Not Working

- Verify secrets are added to **Actions** secrets (not Codebases or Dependabot)
- Check secret names match exactly (case-sensitive)
- Ensure no extra spaces in secret values

### API Keys Invalid

- Verify API keys are active
- Check API key has required permissions
- Some endpoints may require paid plans

### Discord Bot Not Posting

- Verify bot token is correct
- Check bot has "Send Messages" permission
- Ensure channel ID is correct
- Check bot is invited to server

### Gist Not Updating

- Verify GIST_ID is correct
- Check GH_PAT has `gist` scope
- Ensure Gist is accessible (not deleted)
