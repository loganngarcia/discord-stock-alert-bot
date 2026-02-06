# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-01

### Added
- Initial release of Discord Stock Alert Bot
- Automated monitoring of US stock market movers
- 90% gain threshold detection
- Trimmed-and-haircut anchor calculation from analyst targets
- Daily deduplication using GitHub Gist state persistence
- GitHub Actions workflow for automated execution
- Comprehensive test suite (8 tests)
- Full documentation (README, Architecture, API, Configuration)
- Contributing guidelines
- MIT License

### Features
- Monitors stocks every 5 minutes during market hours (10am-3pm PT, weekdays)
- Only alerts on symbols gaining ≥90% compared to previous close
- Calculates analyst target anchor with 12.5% haircut
- Posts formatted Discord messages with symbol details
- Silent operation (exits silently if no qualifying symbols)

### Security
- All secrets stored in GitHub Secrets
- Private repository by default
- No hardcoded credentials
- Comprehensive .gitignore

### Documentation
- Professional README with quick start guide
- Architecture documentation
- API integration guide
- Configuration guide
- Contributing guidelines

## [Unreleased]

### Planned
- Support for multiple Discord channels
- Configurable alert thresholds per symbol
- Webhook endpoint for manual triggers
- Metrics and monitoring dashboard
- Retry logic with exponential backoff
- Enhanced error reporting
