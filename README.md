# Stockup - macOS Stock Alert App

A beautiful macOS SwiftUI application for monitoring stock alerts with a native liquid glass interface.

## Features

✅ **Native Liquid Glass Interface** - Uses `NSVisualEffectView` for authentic macOS frosted glass effect  
✅ **Bottom Center Slider** - Percentage threshold slider (0-20%) with saved state using `@AppStorage`  
✅ **Stock List** - Sortable table with multiple time periods (1D, 1W, 1M, 6M, YTD, 1YR, 5YR, MAX)  
✅ **Free API Integration** - Uses Yahoo Finance API (no API key required)  
✅ **Apple Design System** - Proper macOS design patterns and colors  
✅ **Real Company Names** - Fetches actual brand names from multiple free APIs  
✅ **Clean Names** - Automatically removes corporate suffixes (Inc., Corp., Limited, etc.) and trailing commas

## Quick Start

### Option 1: Open in Xcode (Recommended)

1. Double-click `Stockup.xcodeproj` to open in Xcode
2. Press `⌘R` to build and run
3. The app will launch automatically

### Option 2: Build from Command Line

```bash
xcodebuild -project Stockup.xcodeproj -scheme Stockup -configuration Debug build
open /Users/logangarcia/Library/Developer/Xcode/DerivedData/Stockup-*/Build/Products/Debug/Stockup.app
```

## Project Structure

```
.
├── StockupApp.swift      # App entry point
├── ContentView.swift      # Main view with liquid glass background and sortable table
├── StockRowView.swift     # Individual stock row component (legacy)
├── Stock.swift            # Data model (Identifiable, Codable)
├── StockViewModel.swift   # View model & API integration
├── Stockup.xcodeproj/     # Xcode project file
├── README.md              # This file
└── discord_stock_alert_bot/  # Discord bot subfolder (see below)
```

## Architecture

- **SwiftUI** - Modern declarative UI framework
- **MVVM Pattern** - `StockViewModel` manages state and API calls
- **Async/Await** - Modern Swift concurrency for API calls
- **@AppStorage** - Persistent user preferences (threshold percentage, time period)
- **@Published** - Reactive data binding
- **Table Component** - Native SwiftUI Table with sortable columns

## API Details

- **Yahoo Finance API** - Free, no authentication required
  - Chart endpoint: `https://query1.finance.yahoo.com/v8/finance/chart/{SYMBOL}`
  - Quote Summary: `https://query2.finance.yahoo.com/v10/finance/quoteSummary/{SYMBOL}`
  - Search: `https://query1.finance.yahoo.com/v1/finance/search`
- **Company Name APIs** - Multiple fallback sources:
  - Yahoo Finance (assetProfile, quoteType, chart metadata, search)
  - Alpha Vantage (company overview)
  - Polygon.io (ticker details)
- **Logo APIs** - IEX Cloud, EOD Historical Data, Clearbit

## Requirements

- macOS 13.0 or later
- Xcode 14.0 or later
- Swift 5.0+

## Building

The project is configured with:
- **Deployment Target**: macOS 13.0
- **Swift Version**: 5.0
- **Bundle Identifier**: `com.stockup.app`
- **Code Signing**: Automatic (Sign to Run Locally)

## Usage

1. Launch the app
2. Select a time period using the segmented control at the top (1D, 1W, 1M, etc.)
3. Adjust the threshold slider at the bottom (0-20%)
4. View stocks filtered by the selected percentage threshold
5. Click column headers to sort by different values
6. Each stock shows:
   - Company logo
   - Company name and ticker symbol
   - % Change (for selected time period)
   - Market Cap
   - Current Price
   - Analyst Target
   - Diff (percentage difference between price and analyst target)

## Notes

- The app fetches market movers from Yahoo Finance screener
- Falls back to comprehensive stock list if screener is unavailable
- Company names are cleaned automatically (removes Inc., Corp., Limited, etc. and trailing commas)
- Multiple API fallbacks ensure every stock has a brand name
- Threshold and time period preferences are saved automatically using UserDefaults

## Discord Bot

This repository also includes a Discord bot for stock alerts. See [discord_stock_alert_bot/README.md](./discord_stock_alert_bot/README.md) for details.
