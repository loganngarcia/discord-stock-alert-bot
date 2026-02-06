# Project Structure

```
stockup-app/                          # Main repository (Stockup macOS app)
├── StockupApp.swift                  # Main app entry point
├── ContentView.swift                  # Main UI
├── StockViewModel.swift               # Data & API logic
├── Stock.swift                        # Data model
├── StockRowView.swift                 # Row component
├── Stockup.xcodeproj/                 # Xcode project
├── README.md                          # Stockup app documentation
├── .gitignore                         # Git ignore rules
│
└── discord_stock_alert_bot/           # Discord bot subfolder
    ├── .github/
    │   ├── ISSUE_TEMPLATE/
    │   │   ├── bug_report.md          # Bug report template
    │   │   └── feature_request.md     # Feature request template
    │   ├── PULL_REQUEST_TEMPLATE.md   # PR template
    │   └── workflows/
    │       ├── stock_alert.yml        # Main workflow (cron schedule)
    │       └── test_discord.yml       # Test workflow
    │
    ├── bot.py                         # Main bot script
    ├── requirements.txt               # Python dependencies
    ├── test_bot.py                    # Pytest test cases
    ├── test_discord_send.py           # Discord connection test
    │
    ├── README.md                      # Bot documentation
    ├── CHANGELOG.md                   # Version history
    ├── CONTRIBUTING.md                # Contribution guidelines
    ├── LICENSE                        # MIT License
    │
    └── docs/
        ├── API.md                     # API integration details
        ├── ARCHITECTURE.md            # System architecture
        ├── CONFIGURATION.md           # Configuration guide
        ├── PROJECT_STRUCTURE.md       # This file
        └── TROUBLESHOOTING.md         # Common issues & solutions
```

## Key Files

### Bot Scripts
- **`bot.py`** - Main bot script with core logic:
  - Market movers fetching (Twelve Data)
  - Quote data retrieval
  - Analyst target calculation (FMP)
  - Discord message formatting
  - State persistence (GitHub Gist)

### Tests
- **`test_bot.py`** - Pytest test cases for core functionality
- **`test_discord_send.py`** - Discord connection verification

### Configuration
- **`requirements.txt`** - Python dependencies
- **`.github/workflows/stock_alert.yml`** - GitHub Actions workflow with cron schedule

### Documentation
- **`README.md`** - Quick start and overview
- **`docs/API.md`** - External API details (Twelve Data, FMP, Discord)
- **`docs/ARCHITECTURE.md`** - System design and data flow
- **`docs/CONFIGURATION.md`** - Environment variables and secrets setup
- **`docs/TROUBLESHOOTING.md`** - Common issues and solutions

## Notes

- The Discord bot is now a subfolder within the Stockup repository
- The main Stockup macOS app files are at the repository root
- All Discord bot-specific files are contained in `discord_stock_alert_bot/`
