# Discord Stock Alert Bot

> **Note**: This is a subfolder within the Stockup repository. The main macOS app is at the root level. See [../README.md](../README.md) for the Stockup app documentation.

[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)

> A production-ready Discord bot that monitors US stock market movers and alerts on symbols gaining ≥90% compared to their previous close, with intelligent analyst target analysis.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/loganngarcia/stockup-app.git
cd stockup-app/discord_stock_alert_bot

# Install dependencies
pip install -r requirements.txt

# Set up environment variables (see Configuration section)
export TWELVE_DATA_API_KEY="your_key"
export FMP_API_KEY="your_key"
# ... (see full list in docs/CONFIGURATION.md)

# Run tests
pytest test_bot.py -v

# Run locally (will exit silently outside market hours)
python bot.py
```

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Deployment](#-deployment)
- [Usage](#-usage)
- [Development](#-development)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

- **🎯 Smart Threshold Detection**: Only alerts on symbols gaining ≥90% compared to previous close
- **📊 Analyst Target Analysis**: Calculates trimmed-and-haircut anchor from analyst price targets
- **🔄 Daily Deduplication**: Each symbol alerts only once per day using GitHub Gist state persistence
- **⏰ Market Hours Only**: Automatically runs during trading hours (10am-3pm PT, weekdays)
- **🔇 Silent Operation**: Exits silently if no symbols meet threshold (no unnecessary Discord messages)
- **☁️ Cloud-Hosted**: Runs automatically via GitHub Actions every 5 minutes
- **🧪 Fully Tested**: Comprehensive test suite with 100% coverage of core logic

## 🏗️ Architecture

```
discord-stock-alert-bot/
├── bot.py                 # Main bot implementation
├── test_bot.py            # Test suite
├── requirements.txt       # Python dependencies
├── .github/
│   └── workflows/
│       └── stock_alert.yml  # GitHub Actions workflow
├── docs/
│   ├── ARCHITECTURE.md    # System architecture documentation
│   ├── API.md             # API integration details
│   └── CONFIGURATION.md   # Configuration guide
└── README.md              # This file
```

### Core Components

1. **StockDataFetcher**: Fetches market movers and quote data from Twelve Data API
2. **AnalystTargetFetcher**: Retrieves analyst price targets from Financial Modeling Prep
3. **GistStateManager**: Manages daily alert state persistence via GitHub Gist
4. **Anchor Calculator**: Implements trimmed-and-haircut algorithm for price targets

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed architecture documentation.

## 📦 Installation

### Prerequisites

- Python 3.11 or higher
- GitHub account with Personal Access Token (PAT) with `gist` scope
- Discord bot token and channel ID
- API keys:
  - [Twelve Data API](https://twelvedata.com/) key
  - [Financial Modeling Prep](https://site.financialmodelingprep.com/) API key

### Step-by-Step Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/loganngarcia/discord-stock-alert-bot.git
   cd discord-stock-alert-bot
   ```

2. **Create a virtual environment** (recommended):
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up GitHub Gist for state persistence**:
   - Go to https://gist.github.com
   - Create a new **secret** gist
   - Add a file named `state.json` with content: `{}`
   - Copy the Gist ID from the URL

5. **Configure Discord Bot**:
   - Create a bot at https://discord.com/developers/applications
   - Copy the bot token
   - Get your channel ID (right-click channel → Copy ID in Developer Mode)
   - Invite bot to server with "Send Messages" permission

6. **Set up GitHub Secrets**:
   - Go to repository Settings → Secrets and variables → Actions
   - Add all required secrets (see [Configuration](#-configuration))

See [docs/CONFIGURATION.md](docs/CONFIGURATION.md) for detailed configuration instructions.

## ⚙️ Configuration

All configuration is done via environment variables (set as GitHub Secrets for production):

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `TWELVE_DATA_API_KEY` | Twelve Data API key | ✅ | - |
| `FMP_API_KEY` | Financial Modeling Prep API key | ✅ | - |
| `DISCORD_BOT_TOKEN` | Discord bot token | ✅ | - |
| `DISCORD_CHANNEL_ID` | Discord channel ID | ✅ | - |
| `GIST_ID` | GitHub Gist ID for state | ✅ | - |
| `GH_PAT` | GitHub Personal Access Token | ✅ | - |
| `ALERT_THRESHOLD_PCT` | Minimum % gain to alert | ❌ | `90` |
| `HAIRCUT_RATE` | Haircut rate for anchor (0.125 = 12.5%) | ❌ | `0.125` |

## 🚢 Deployment

The bot runs automatically via GitHub Actions:

- **Schedule**: Every 5 minutes between 10:00am-3:00pm PT on weekdays
- **Cron**: `*/5 17-23 * * 1-5` (UTC timezone)
- **Manual Trigger**: Available via GitHub Actions UI (`workflow_dispatch`)

The workflow automatically:
1. Checks out the code
2. Sets up Python 3.11
3. Installs dependenciesok
4. Runs the bot with secrets from GitHub Secrets

See [.github/workflows/stock_alert.yml](.github/workflows/stock_alert.yml) for the workflow configuration.

## 💻 Usage

### Local Development

```bash
# Set environment variables
export TWELVE_DATA_API_KEY="your_key"
export FMP_API_KEY="your_key"
export DISCORD_BOT_TOKEN="your_token"
export DISCORD_CHANNEL_ID="your_channel_id"
export GIST_ID="your_gist_id"
export GH_PAT="your_pat"

# Run the bot
python bot.py

# Run tests
pytest test_bot.py -v

# Run with verbose output
python bot.py --verbose  # (if implemented)
```

### Message Format

When a symbol meets the threshold, the bot posts a formatted message:

```
ALERT: ≥ 90% movers (10:35 PT)
ABC +132.4% | last $2.18 | prev $0.94 | anchor (12.5%) $4.40 | targets 7 (trimmed)
XYZ +91.0% | last $1.02 | prev $0.53 | anchor (12.5%) $1.80 | targets 3 (fallback)
```

**Message Components**:
- **Header**: Threshold and timestamp in Pacific Time
- **Symbol**: Stock ticker
- **Percentage Gain**: Current gain vs previous close
- **Last Price**: Current market price
- **Previous Close**: Previous day's closing price
- **Anchor**: Trimmed-and-haircut analyst target price
- **Targets**: Number of analyst targets and calculation method

## 🧪 Development

### Running Tests

```bash
# Run all tests
pytest test_bot.py -v

# Run with coverage
pytest test_bot.py --cov=bot --cov-report=html

# Run specific test
pytest test_bot.py::test_threshold_alert_trigger -v
```

### Code Style

This project follows PEP 8 style guidelines. Consider using:
- `black` for code formatting
- `flake8` or `pylint` for linting
- `mypy` for type checking

### Project Structure

```
.
├── bot.py                    # Main bot implementation
├── test_bot.py              # Test suite
├── requirements.txt         # Python dependencies
├── .github/
│   └── workflows/
│       └── stock_alert.yml  # CI/CD workflow
├── docs/                    # Documentation
│   ├── ARCHITECTURE.md
│   ├── API.md
│   └── CONFIGURATION.md
└── README.md                # This file
```

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on:

- Code of conduct
- Development setup
- Pull request process
- Coding standards

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Twelve Data](https://twelvedata.com/) for market data API
- [Financial Modeling Prep](https://site.financialmodelingprep.com/) for analyst target data
- Discord for the bot platform

## 📚 Documentation

- [Architecture Documentation](docs/ARCHITECTURE.md)
- [API Integration Guide](docs/API.md)
- [Configuration Guide](docs/CONFIGURATION.md)
- [Contributing Guidelines](CONTRIBUTING.md)

## 🐛 Troubleshooting

### Bot doesn't send messages

1. Check that all secrets are set in GitHub Secrets
2. Verify Discord bot token is valid
3. Ensure bot has "Send Messages" permission in channel
4. Check GitHub Actions logs for errors

### No symbols triggering alerts

- This is normal! The bot only alerts on ≥90% gains, which are rare
- Check that APIs are working: `python bot.py` should run without errors
- Verify market hours: Bot only runs 10am-3pm PT on weekdays

### API errors

- Check API keys are valid and have sufficient quota
- Twelve Data market movers endpoint requires paid plan (bot falls back to popular stocks)
- FMP API may require valid subscription

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more troubleshooting tips.

---

**Made with ❤️ for the trading community**
