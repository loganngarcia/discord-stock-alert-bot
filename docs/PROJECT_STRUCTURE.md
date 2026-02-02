# Project Structure

```
discord-stock-alert-bot/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md          # Bug report template
│   │   └── feature_request.md     # Feature request template
│   ├── PULL_REQUEST_TEMPLATE.md   # PR template
│   └── workflows/
│       └── stock_alert.yml         # GitHub Actions workflow
│
├── docs/
│   ├── ARCHITECTURE.md            # System architecture
│   ├── API.md                     # API integration guide
│   ├── CONFIGURATION.md           # Configuration guide
│   ├── TROUBLESHOOTING.md         # Troubleshooting guide
│   └── PROJECT_STRUCTURE.md        # This file
│
├── bot.py                         # Main bot implementation
├── test_bot.py                    # Test suite
├── requirements.txt               # Python dependencies
│
├── .gitignore                     # Git ignore rules
├── LICENSE                        # MIT License
├── README.md                      # Main documentation
├── CONTRIBUTING.md                # Contribution guidelines
└── CHANGELOG.md                   # Version history
```

## File Descriptions

### Core Files

- **bot.py**: Main bot implementation with all core logic
- **test_bot.py**: Comprehensive test suite (8 tests)
- **requirements.txt**: Python package dependencies

### Documentation

- **README.md**: Main project documentation with quick start
- **CONTRIBUTING.md**: Guidelines for contributors
- **CHANGELOG.md**: Version history and changes
- **docs/**: Detailed documentation directory

### Configuration

- **.gitignore**: Files and directories to exclude from git
- **.github/workflows/**: GitHub Actions workflow definitions
- **.github/ISSUE_TEMPLATE/**: Issue templates for bug reports and features
- **.github/PULL_REQUEST_TEMPLATE.md**: PR template

### Excluded Files

These files are gitignored and should not be committed:

- `.secrets.local.md`: Local secrets reference (contains actual values)
- `venv/`: Python virtual environment
- `__pycache__/`: Python bytecode cache
- `.pytest_cache/`: Pytest cache

## Adding New Files

When adding new files:

1. **Code files**: Place in root or appropriate subdirectory
2. **Tests**: Add to `test_bot.py` or create `tests/` directory
3. **Documentation**: Add to `docs/` directory
4. **Scripts**: Add to root with descriptive names

## Code Organization

### Classes

- `GistStateManager`: State persistence
- `StockDataFetcher`: Market data retrieval
- `AnalystTargetFetcher`: Analyst target retrieval

### Functions

- `calculate_anchor()`: Anchor calculation algorithm
- `check_time_window()`: Market hours validation
- `format_discord_message()`: Message formatting
- `main()`: Entry point and orchestration

## Best Practices

- Keep functions focused and small
- Use type hints for all function signatures
- Write docstrings for all public functions/classes
- Follow PEP 8 style guidelines
- Add tests for new functionality
