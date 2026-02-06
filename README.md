# Stockup - macOS Stock Alert App

> A beautiful, native macOS app for tracking stock market movers with real-time alerts and an elegant liquid glass interface.

[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Stockup helps you stay on top of the stock market with a clean, native macOS experience. Track movers across multiple time periods, filter by percentage thresholds, and get real-time data—all without any API keys or subscriptions.

## ✨ Features

- 🎨 **Native Liquid Glass Interface** - Authentic macOS frosted glass design using native APIs
- 📊 **Sortable Stock Table** - Click any column to sort by price, change, market cap, and more
- ⏱️ **Multiple Time Periods** - View performance across 1D, 1W, 1M, 6M, YTD, 1YR, 5YR, or MAX
- 🎚️ **Custom Threshold Filter** - Set your own percentage threshold (0-20%) to focus on what matters
- 🏢 **Real Company Names** - Automatically fetches and cleans company names from multiple free sources
- 💾 **Persistent Preferences** - Your settings are saved automatically
- 🚀 **100% Free** - No API keys, no subscriptions, no hidden costs

## 🚀 Quick Start

### Download & Build

1. **Clone the repository**
   ```bash
   git clone https://github.com/loganngarcia/stockup-app.git
   cd stockup-app
   ```

2. **Open in Xcode**
   - Double-click `Stockup.xcodeproj`
   - Press `⌘R` to build and run

3. **That's it!** The app will launch automatically.

### Requirements

- macOS 13.0 or later
- Xcode 14.0 or later (for building from source)

## 📸 Screenshots

*Coming soon - screenshots of the beautiful interface*

## 🎯 How It Works

Stockup uses free, public APIs to fetch real-time stock data:

- **Yahoo Finance** - Primary data source for prices, charts, and company info
- **Multiple Fallbacks** - Ensures reliability even if one API is down
- **Smart Caching** - Efficient data fetching with progressive UI updates
- **Clean Data** - Automatically removes corporate suffixes and formatting issues

## 🛠️ Building from Source

```bash
# Clone the repo
git clone https://github.com/loganngarcia/stockup-app.git
cd stockup-app

# Open in Xcode
open Stockup.xcodeproj

# Or build from command line
xcodebuild -project Stockup.xcodeproj -scheme Stockup -configuration Debug build
```

## 📁 Project Structure

```
stockup-app/
├── StockupApp.swift          # App entry point
├── ContentView.swift         # Main UI with sortable table
├── StockViewModel.swift      # Data fetching & state management
├── Stock.swift               # Data models
├── Stockup.xcodeproj/        # Xcode project
└── discord_stock_alert_bot/  # Discord bot (separate project)
```

## 🤝 Contributing

We love contributions! Whether it's bug fixes, new features, or documentation improvements, every contribution makes Stockup better. See our [Contributing Guide](CONTRIBUTING.md) for details.

**Quick ways to contribute:**
- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve documentation
- 🔧 Submit pull requests
- ⭐ Star the repository

## 📄 License

Stockup is open source and available under the [MIT License](LICENSE). Feel free to use it, modify it, and share it!

## 🙏 Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Data provided by free public APIs (Yahoo Finance, Alpha Vantage, Polygon.io)
- Logo APIs: IEX Cloud, EOD Historical Data, Clearbit

## 📮 Discord Bot

This repository also includes a Discord bot for automated stock alerts. Check out the [`discord_stock_alert_bot/`](discord_stock_alert_bot/) folder for more information.

## 💬 Support

- 🐛 **Found a bug?** [Open an issue](https://github.com/loganngarcia/stockup-app/issues)
- 💡 **Have an idea?** [Suggest a feature](https://github.com/loganngarcia/stockup-app/issues)
- 📧 **Questions?** Check our [Discussions](https://github.com/loganngarcia/stockup-app/discussions)

---

**Made with ❤️ for the macOS community**

*Stockup is not affiliated with any financial institution. This app is for informational purposes only.*
