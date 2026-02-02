# Discord Stock Alert Bot

A Python-based bot that monitors US stock market movers every 5 minutes on weekdays between 10:00am and 3:00pm PT. The bot alerts when a symbol gains ≥90% compared to its previous close, calculates a "Trimmed-and-Haircut Anchor" based on analyst targets, and ensures each symbol only alerts once per day.

## Features

- **Automated Monitoring**: Runs every 5 minutes during market hours (10am-3pm PT, weekdays only)
- **Smart Threshold Detection**: Only alerts on symbols gaining ≥90% compared to previous close
- **Analyst Target Analysis**: Calculates trimmed-and-haircut anchor from analyst price targets
- **Daily Deduplication**: Each symbol alerts only once per day using GitHub Gist state persistence
- **Silent Operation**: Exits silently if no symbols meet the threshold (no Discord heartbeat)

## How It Works

1. **Market Movers Detection**: Fetches top gainers from Twelve Data API
2. **Quote Verification**: Gets precise `previous_close` and `last_price` values for each symbol
3. **Threshold Check**: Calculates percentage change: `(last_price - previous_close) / previous_close * 100`
4. **Analyst Targets**: Fetches individual analyst targets or consensus from Financial Modeling Prep
5. **Anchor Calculation**: 
   - If ≥3 targets: Sort, drop highest/lowest, calculate trimmed mean, apply 12.5% haircut
   - If <3 targets: Use consensus mean, apply 12.5% haircut
6. **Discord Alert**: Posts formatted message with all qualifying symbols
7. **State Persistence**: Updates GitHub Gist to track alerted symbols for the day

## Setup

### Prerequisites

- Python 3.11+
- GitHub account with Personal Access Token (PAT) with `gist` scope
- Discord bot token and channel ID
- API keys:
  - Twelve Data API key
  - Financial Modeling Prep API key

### Installation

1. **Clone the repository**:
   ```bash
   git clone <your-repo-url>
   cd discord-stock-alert-bot
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Create a GitHub Gist for state persistence**:
   - Go to https://gist.github.com
   - Create a new secret gist with a file named `state.json`
   - Add initial content: `{}`
   - Copy the Gist ID from the URL (e.g., `abc123def456`)

4. **Set up GitHub Secrets**:
   Go to your repository → Settings → Secrets and variables → Actions, and add:
   - `TWELVE_DATA_API_KEY`: Your Twelve Data API key
   - `FMP_API_KEY`: Your Financial Modeling Prep API key
   - `DISCORD_BOT_TOKEN`: Your Discord bot token
   - `DISCORD_CHANNEL_ID`: Your Discord channel ID (numeric)
   - `GIST_ID`: The ID of your GitHub Gist
   - `GH_PAT`: Your GitHub Personal Access Token (with `gist` scope)
   - `ALERT_THRESHOLD_PCT`: `90` (optional, defaults to 90)
   - `HAIRCUT_RATE`: `0.125` (optional, defaults to 0.125 for 12.5%)

### Discord Bot Setup

1. **Create a Discord Application**:
   - Go to https://discord.com/developers/applications
   - Create a new application
   - Go to "Bot" section and create a bot
   - Copy the bot token

2. **Get Channel ID**:
   - Enable Developer Mode in Discord (User Settings → Advanced → Developer Mode)
   - Right-click on your channel → Copy ID

3. **Invite Bot to Server**:
   - Go to OAuth2 → URL Generator
   - Select `bot` scope
   - Select `Send Messages` permission
   - Copy the generated URL and open it to invite the bot

## Configuration

All configuration is done via environment variables (set as GitHub Secrets):

| Variable | Description | Default |
|----------|-------------|---------|
| `TWELVE_DATA_API_KEY` | Twelve Data API key | Required |
| `FMP_API_KEY` | Financial Modeling Prep API key | Required |
| `DISCORD_BOT_TOKEN` | Discord bot token | Required |
| `DISCORD_CHANNEL_ID` | Discord channel ID | Required |
| `GIST_ID` | GitHub Gist ID for state | Required |
| `GH_PAT` | GitHub Personal Access Token | Required |
| `ALERT_THRESHOLD_PCT` | Minimum % gain to alert | `90` |
| `HAIRCUT_RATE` | Haircut rate for anchor (0.125 = 12.5%) | `0.125` |

## Deployment

The bot is configured to run automatically via GitHub Actions:

- **Schedule**: Every 5 minutes between 10:00am-3:00pm PT on weekdays
- **Cron**: `*/5 17-23 * * 1-5` (UTC timezone)
- **Manual Trigger**: Available via GitHub Actions UI (`workflow_dispatch`)

The workflow file is located at `.github/workflows/stock_alert.yml`.

## Local Testing

To test locally:

1. **Set environment variables**:
   ```bash
   export TWELVE_DATA_API_KEY="your_key"
   export FMP_API_KEY="your_key"
   export DISCORD_BOT_TOKEN="your_token"
   export DISCORD_CHANNEL_ID="your_channel_id"
   export GIST_ID="your_gist_id"
   export GH_PAT="your_pat"
   ```

2. **Run the bot**:
   ```bash
   python bot.py
   ```

3. **Run tests**:
   ```bash
   pytest test_bot.py -v
   ```

## Message Format

The bot posts messages in the following format:

```
ALERT: ≥ 90% movers (10:35 PT)
ABC +132.4% | last $2.18 | prev $0.94 | anchor (12.5%) $4.40 | targets 7 (trimmed)
XYZ +91.0% | last $1.02 | prev $0.53 | anchor (12.5%) $1.80 | targets 3 (fallback)
```

## Testing

The test suite includes:

- Threshold boundary tests ($1.00 → $1.90 triggers, $1.00 → $1.89 does not)
- Trimmed mean calculation tests
- Anchor calculation with various target counts
- Fallback to consensus when <3 targets

Run tests with:
```bash
pytest test_bot.py -v
```

## Error Handling

- **API Rate Limits**: Bot fails silently if APIs are rate-limited
- **Missing Data**: Symbols with missing `previous_close` or `last_price` are skipped
- **Outside Market Hours**: Script exits silently if run outside 10am-3pm PT on weekdays
- **No Qualifying Symbols**: Script exits silently if no symbols meet threshold

## Timezone Handling

The bot uses `pytz` to ensure it only runs during Pacific Time market hours:
- Checks if current PT time is between 10:00 and 15:00
- Only runs on weekdays (Monday-Friday)
- Handles both PST and PDT automatically

## License

This project is provided as-is for educational and personal use.
