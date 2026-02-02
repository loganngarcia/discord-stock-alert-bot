# API Integration Guide

This document describes the external APIs used by the Discord Stock Alert Bot and how they're integrated.

## Twelve Data API

### Endpoints Used

#### 1. Market Movers (`/market_movers/stocks`)

**Purpose**: Get list of top gainers

**Endpoint**: `https://api.twelvedata.com/market_movers/stocks`

**Parameters**:
- `apikey`: Your API key

**Response**: List or dict containing market movers

**Note**: This endpoint requires a paid plan. The bot falls back to checking popular stocks if unavailable.

#### 2. Quote (`/quote`)

**Purpose**: Get detailed quote data including previous close and current price

**Endpoint**: `https://api.twelvedata.com/quote`

**Parameters**:
- `symbol`: Stock ticker symbol
- `apikey`: Your API key

**Response**:
```json
{
  "symbol": "AAPL",
  "previous_close": "150.00",
  "close": "155.00",
  ...
}
```

**Usage**: Used to get precise `previous_close` and `last_price` values for percentage calculation

### Error Handling

- Rate limits: Bot fails silently
- Invalid symbols: Skipped
- Missing data: Symbol skipped if `previous_close` or `close` is missing/zero

## Financial Modeling Prep API

### Endpoints Used

#### 1. Price Target (`/api/v4/price-target`)

**Purpose**: Get individual analyst price targets

**Endpoint**: `https://financialmodelingprep.com/api/v4/price-target`

**Parameters**:
- `symbol`: Stock ticker symbol
- `apikey`: Your API key

**Response**: Array of analyst targets
```json
[
  {
    "target": 20.5,
    "analyst": "Analyst Name",
    ...
  },
  ...
]
```

#### 2. Price Target Consensus (`/api/v4/price-target-consensus`)

**Purpose**: Get consensus (mean) price target

**Endpoint**: `https://financialmodelingprep.com/api/v4/price-target-consensus`

**Parameters**:
- `symbol`: Stock ticker symbol
- `apikey`: Your API key

**Response**: Array with consensus data
```json
[
  {
    "targetConsensus": 18.5,
    ...
  }
]
```

**Usage**: Fallback when <3 individual targets available

### Error Handling

- 401 Unauthorized: API key may be invalid
- Rate limits: Bot continues without analyst data
- Missing targets: Uses consensus or returns "none"

## Discord API

### Endpoint Used

#### Send Message (`POST /channels/{channel_id}/messages`)

**Purpose**: Post alert message to Discord channel

**Endpoint**: `https://discord.com/api/v10/channels/{DISCORD_CHANNEL_ID}/messages`

**Headers**:
- `Authorization`: `Bot {DISCORD_BOT_TOKEN}`
- `Content-Type`: `application/json`

**Body**:
```json
{
  "content": "ALERT: ≥ 90% movers (10:35 PT)\nABC +132.4% | ..."
}
```

**Error Handling**:
- 401: Invalid bot token
- 403: Bot lacks permissions
- 404: Channel not found
- All errors: Logged, bot continues

## GitHub Gist API

### Endpoints Used

#### 1. Get Gist (`GET /gists/{gist_id}`)

**Purpose**: Retrieve current state

**Endpoint**: `https://api.github.com/gists/{GIST_ID}`

**Headers**:
- `Authorization`: `token {GH_PAT}`
- `Accept`: `application/vnd.github.v3+json`

#### 2. Update Gist (`PATCH /gists/{gist_id}`)

**Purpose**: Update state with new alerts

**Endpoint**: `https://api.github.com/gists/{GIST_ID}`

**Body**:
```json
{
  "files": {
    "state.json": {
      "content": "{\"2026-02-01\": [\"SYMBOL1\"]}"
    }
  }
}
```

## Rate Limits

### Twelve Data
- Free tier: 8 API credits/day
- Market movers: Requires paid plan

### Financial Modeling Prep
- Varies by subscription tier
- Bot handles rate limits gracefully

### Discord
- 50 requests/second per bot
- Bot makes minimal requests (1 per run)

### GitHub
- 5,000 requests/hour for authenticated requests
- Gist operations are minimal

## API Key Management

**Never commit API keys to the repository!**

All API keys are stored in:
- GitHub Secrets (for production)
- Environment variables (for local development)
- `.secrets.local.md` (local reference, gitignored)

## Testing APIs

To test API integrations:

```bash
# Test Twelve Data
python -c "from bot import StockDataFetcher; sf = StockDataFetcher('your_key'); print(sf.get_quote('AAPL'))"

# Test FMP
python -c "from bot import AnalystTargetFetcher; af = AnalystTargetFetcher('your_key'); print(af.get_individual_targets('AAPL'))"
```

## Troubleshooting

### API Errors

1. **401 Unauthorized**: Check API key is valid
2. **403 Forbidden**: Check API key has required permissions
3. **429 Rate Limited**: Wait and retry, or upgrade plan
4. **404 Not Found**: Check endpoint URL and parameters

### Common Issues

- **Market movers not working**: Endpoint requires paid plan, bot uses fallback
- **No analyst targets**: Some symbols may not have analyst coverage
- **Discord message fails**: Check bot token and channel permissions
