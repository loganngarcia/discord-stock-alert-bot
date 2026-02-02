# Architecture Documentation

## Overview

The Discord Stock Alert Bot is a cloud-hosted Python application that monitors US stock market movers and sends alerts to Discord when symbols gain ≥90% compared to their previous close.

## System Architecture

```
┌─────────────────┐
│  GitHub Actions │
│  (Scheduler)    │
└────────┬────────┘
         │ Every 5 min
         │ (Market Hours)
         ▼
┌─────────────────────────────────────┐
│         Bot Execution               │
│  ┌───────────────────────────────┐  │
│  │  1. Time Window Check         │  │
│  │     (10am-3pm PT, Weekdays)   │  │
│  └──────────────┬────────────────┘  │
│                 │                   │
│  ┌──────────────▼────────────────┐  │
│  │  2. Fetch Market Movers       │  │
│  │     (Twelve Data API)         │  │
│  └──────────────┬────────────────┘  │
│                 │                   │
│  ┌──────────────▼────────────────┐  │
│  │  3. Get Quote Data            │  │
│  │     (previous_close, price)   │  │
│  └──────────────┬────────────────┘  │
│                 │                   │
│  ┌──────────────▼────────────────┐  │
│  │  4. Calculate % Change       │  │
│  │     Filter ≥90% gainers      │  │
│  └──────────────┬────────────────┘  │
│                 │                   │
│  ┌──────────────▼────────────────┐  │
│  │  5. Get Analyst Targets       │  │
│  │     (Financial Modeling Prep)│  │
│  └──────────────┬────────────────┘  │
│                 │                   │
│  ┌──────────────▼────────────────┐  │
│  │  6. Calculate Anchor          │  │
│  │     (Trimmed & Haircut)      │  │
│  └──────────────┬────────────────┘  │
│                 │                   │
│  ┌──────────────▼────────────────┐  │
│  │  7. Check Daily State         │  │
│  │     (GitHub Gist)            │  │
│  └──────────────┬────────────────┘  │
│                 │                   │
│  ┌──────────────▼────────────────┐  │
│  │  8. Post to Discord           │  │
│  │     (If qualifying symbols) │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Component Details

### 1. StockDataFetcher

**Purpose**: Fetches stock market data from Twelve Data API

**Methods**:
- `get_market_movers()`: Retrieves list of top gainers
- `get_quote(symbol)`: Gets detailed quote data for a symbol

**Fallback Strategy**: If market movers endpoint requires paid plan, falls back to checking a list of popular stocks

### 2. AnalystTargetFetcher

**Purpose**: Retrieves analyst price targets from Financial Modeling Prep

**Methods**:
- `get_individual_targets(symbol)`: Gets list of individual analyst targets
- `get_consensus_target(symbol)`: Gets consensus (mean) target

**Fallback Strategy**: Uses consensus if <3 individual targets available

### 3. GistStateManager

**Purpose**: Manages daily alert state persistence using GitHub Gist

**Methods**:
- `get_state()`: Retrieves current state from Gist
- `update_state(state)`: Updates state in Gist

**State Format**:
```json
{
  "2026-02-01": ["SYMBOL1", "SYMBOL2"],
  "2026-02-02": ["SYMBOL3"]
}
```

### 4. Anchor Calculator

**Purpose**: Calculates trimmed-and-haircut anchor price from analyst targets

**Algorithm**:
1. If ≥3 targets:
   - Sort targets
   - Drop highest and lowest
   - Calculate trimmed mean
   - Apply haircut (default 12.5%)
2. If <3 targets:
   - Use consensus mean
   - Apply haircut
3. If no targets:
   - Return 0.0 with "none" label

## Data Flow

1. **Input**: GitHub Actions triggers bot every 5 minutes
2. **Processing**: Bot checks time window, fetches data, filters symbols
3. **State Management**: Checks/updates GitHub Gist for deduplication
4. **Output**: Posts formatted message to Discord if qualifying symbols found

## Error Handling

- **API Failures**: Bot fails silently (no Discord heartbeat)
- **Missing Data**: Symbols with missing data are skipped
- **Rate Limits**: API errors are caught and logged, bot continues
- **Outside Hours**: Bot exits silently if not in market hours

## Security

- All secrets stored in GitHub Secrets (never in code)
- Repository is private by default
- State persistence uses private GitHub Gist
- No sensitive data logged or exposed

## Scalability Considerations

- **API Rate Limits**: Bot respects API rate limits
- **State Size**: Gist state grows daily but is cleaned automatically
- **Concurrent Runs**: GitHub Actions prevents concurrent executions
- **Error Recovery**: Bot handles failures gracefully without crashing

## Future Improvements

- Add retry logic for API calls
- Implement exponential backoff
- Add metrics/monitoring
- Support multiple Discord channels
- Add webhook endpoint for manual triggers
