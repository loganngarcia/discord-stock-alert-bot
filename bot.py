#!/usr/bin/env python3
"""
Discord Stock Alert Bot
Monitors US stock market movers and alerts on symbols gaining ≥90% compared to previous close.
"""

import os
import json
import time
from datetime import datetime, timezone
from typing import List, Dict, Optional, Tuple
import requests
import pytz


# Configuration from environment variables
TWELVE_DATA_API_KEY = os.getenv("TWELVE_DATA_API_KEY", "")
FMP_API_KEY = os.getenv("FMP_API_KEY", "")
DISCORD_BOT_TOKEN = os.getenv("DISCORD_BOT_TOKEN", "")
DISCORD_CHANNEL_ID = os.getenv("DISCORD_CHANNEL_ID", "")
GIST_ID = os.getenv("GIST_ID", "")
GH_PAT = os.getenv("GH_PAT", "")
ALERT_THRESHOLD_PCT = float(os.getenv("ALERT_THRESHOLD_PCT", "90"))
HAIRCUT_RATE = float(os.getenv("HAIRCUT_RATE", "0.125"))

# Constants
PT_TIMEZONE = pytz.timezone("America/Los_Angeles")
MARKET_OPEN_HOUR = 10
MARKET_CLOSE_HOUR = 15


class GistStateManager:
    """Manages daily alert state using GitHub Gist."""
    
    def __init__(self, gist_id: str, github_token: str):
        self.gist_id = gist_id
        self.github_token = github_token
        self.base_url = "https://api.github.com/gists"
        self.headers = {
            "Authorization": f"token {github_token}",
            "Accept": "application/vnd.github.v3+json"
        }
    
    def get_state(self) -> Dict[str, List[str]]:
        """Fetch current state from Gist."""
        try:
            response = requests.get(
                f"{self.base_url}/{self.gist_id}",
                headers=self.headers,
                timeout=10
            )
            response.raise_for_status()
            gist_data = response.json()
            # Get the first file's content
            files = gist_data.get("files", {})
            if files:
                file_content = list(files.values())[0].get("content", "{}")
                return json.loads(file_content)
            return {}
        except Exception as e:
            print(f"Error fetching Gist state: {e}")
            return {}
    
    def update_state(self, state: Dict[str, List[str]]) -> bool:
        """Update state in Gist."""
        try:
            # Get current Gist to find filename
            response = requests.get(
                f"{self.base_url}/{self.gist_id}",
                headers=self.headers,
                timeout=10
            )
            response.raise_for_status()
            gist_data = response.json()
            files = gist_data.get("files", {})
            filename = list(files.keys())[0] if files else "state.json"
            
            # Update Gist
            update_response = requests.patch(
                f"{self.base_url}/{self.gist_id}",
                headers=self.headers,
                json={
                    "files": {
                        filename: {
                            "content": json.dumps(state, indent=2)
                        }
                    }
                },
                timeout=10
            )
            update_response.raise_for_status()
            return True
        except Exception as e:
            print(f"Error updating Gist state: {e}")
            return False


class StockDataFetcher:
    """Fetches stock data from Twelve Data API."""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://api.twelvedata.com"
    
    def get_market_movers(self) -> List[str]:
        """Get list of top gainers from market movers endpoint or use alternative."""
        try:
            response = requests.get(
                f"{self.base_url}/market_movers/stocks",
                params={"apikey": self.api_key},
                timeout=10
            )
            response.raise_for_status()
            data = response.json()
            
            # Check if endpoint requires paid plan
            if isinstance(data, dict) and data.get("status") == "error":
                # Market movers requires paid plan, use alternative approach
                # Check a list of active/popular stocks instead
                return self._get_active_stocks_list()
            
            # Extract symbols from the response
            if isinstance(data, dict) and "data" in data:
                movers = data["data"]
            elif isinstance(data, list):
                movers = data
            else:
                movers = []
            
            symbols = []
            for mover in movers:
                if isinstance(mover, dict) and "symbol" in mover:
                    symbols.append(mover["symbol"])
                elif isinstance(mover, str):
                    symbols.append(mover)
            
            return symbols[:50] if symbols else self._get_active_stocks_list()
        except Exception as e:
            print(f"Error fetching market movers: {e}")
            # Fallback to active stocks list
            return self._get_active_stocks_list()
    
    def _get_active_stocks_list(self) -> List[str]:
        """Get a list of active/popular stocks to check (fallback when market movers unavailable)."""
        # List of popular/active stocks that are commonly traded
        # This is a fallback when market movers endpoint requires paid plan
        return [
            "AAPL", "MSFT", "GOOGL", "AMZN", "NVDA", "META", "TSLA", "BRK.B",
            "V", "JNJ", "WMT", "JPM", "MA", "PG", "UNH", "HD", "DIS",
            "BAC", "ADBE", "NFLX", "NKE", "CMCSA", "PFE", "T", "INTC", "CSCO",
            "XOM", "CVX", "ABBV", "COST", "AVGO", "MRK", "PEP", "TMO", "ACN",
            "ABT", "DHR", "VZ", "ADP", "WFC", "LIN", "BMY", "PM", "NEE",
            "RTX", "TXN", "HON", "QCOM", "AMGN", "SPGI", "LOW"
        ]
    
    def get_quote(self, symbol: str) -> Optional[Dict[str, float]]:
        """Get quote data including previous_close and close (last_price)."""
        try:
            response = requests.get(
                f"{self.base_url}/quote",
                params={
                    "symbol": symbol,
                    "apikey": self.api_key
                },
                timeout=10
            )
            response.raise_for_status()
            data = response.json()
            
            # Extract previous_close and close
            previous_close = None
            last_price = None
            
            if isinstance(data, dict):
                previous_close = data.get("previous_close") or data.get("prev_close")
                last_price = data.get("close") or data.get("last_price") or data.get("price")
            
            # Convert to float if they're strings
            if previous_close is not None:
                try:
                    previous_close = float(previous_close)
                except (ValueError, TypeError):
                    previous_close = None
            
            if last_price is not None:
                try:
                    last_price = float(last_price)
                except (ValueError, TypeError):
                    last_price = None
            
            if previous_close and last_price and previous_close > 0:
                return {
                    "previous_close": previous_close,
                    "last_price": last_price
                }
            return None
        except Exception as e:
            print(f"Error fetching quote for {symbol}: {e}")
            return None


class AnalystTargetFetcher:
    """Fetches analyst targets from Financial Modeling Prep API."""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://financialmodelingprep.com/api/v4"
    
    def get_individual_targets(self, symbol: str) -> List[float]:
        """Get individual analyst price targets."""
        try:
            response = requests.get(
                f"{self.base_url}/price-target",
                params={"symbol": symbol, "apikey": self.api_key},
                timeout=10
            )
            response.raise_for_status()
            data = response.json()
            
            if isinstance(data, list):
                targets = []
                for entry in data:
                    if isinstance(entry, dict):
                        target = entry.get("target") or entry.get("priceTarget")
                        if target:
                            try:
                                targets.append(float(target))
                            except (ValueError, TypeError):
                                continue
                return targets
            return []
        except Exception as e:
            print(f"Error fetching individual targets for {symbol}: {e}")
            return []
    
    def get_consensus_target(self, symbol: str) -> Optional[float]:
        """Get consensus (mean) target."""
        try:
            response = requests.get(
                f"{self.base_url}/price-target-consensus",
                params={"symbol": symbol, "apikey": self.api_key},
                timeout=10
            )
            response.raise_for_status()
            data = response.json()
            
            if isinstance(data, list) and len(data) > 0:
                entry = data[0]
                if isinstance(entry, dict):
                    consensus = entry.get("targetConsensus") or entry.get("consensus") or entry.get("mean")
                    if consensus:
                        try:
                            return float(consensus)
                        except (ValueError, TypeError):
                            pass
            return None
        except Exception as e:
            print(f"Error fetching consensus target for {symbol}: {e}")
            return None


def calculate_anchor(targets: List[float], consensus_fallback: Optional[float], haircut_rate: float) -> Tuple[float, str]:
    """
    Calculate trimmed-and-haircut anchor.
    Returns (anchor_value, label) where label is either "trimmed" or "fallback".
    """
    if len(targets) >= 3:
        # Sort and trim
        sorted_targets = sorted(targets)
        trimmed = sorted_targets[1:-1]  # Drop highest and lowest
        trimmed_mean = sum(trimmed) / len(trimmed)
        anchor = trimmed_mean * (1 - haircut_rate)
        return anchor, "trimmed"
    elif consensus_fallback is not None:
        anchor = consensus_fallback * (1 - haircut_rate)
        return anchor, "fallback"
    else:
        # No targets available
        return 0.0, "none"


def check_time_window() -> bool:
    """Check if current time is within market hours (10am-3pm PT) on a weekday."""
    pt_now = datetime.now(PT_TIMEZONE)
    
    # Check if weekday (Monday=0, Friday=4)
    if pt_now.weekday() > 4:
        return False
    
    # Check if within market hours
    current_hour = pt_now.hour
    return MARKET_OPEN_HOUR <= current_hour < MARKET_CLOSE_HOUR


def format_discord_message(qualifying_symbols: List[Dict]) -> str:
    """Format Discord message with all qualifying symbols."""
    pt_now = datetime.now(PT_TIMEZONE)
    time_str = pt_now.strftime("%H:%M")
    
    lines = [f"ALERT: ≥ {ALERT_THRESHOLD_PCT}% movers ({time_str} PT)"]
    
    for symbol_data in qualifying_symbols:
        symbol = symbol_data["symbol"]
        pct_change = symbol_data["pct_change"]
        last_price = symbol_data["last_price"]
        previous_close = symbol_data["previous_close"]
        anchor = symbol_data["anchor"]
        target_count = symbol_data["target_count"]
        anchor_type = symbol_data["anchor_type"]
        
        anchor_str = f"${anchor:.2f}" if anchor > 0 else "N/A"
        target_info = f"targets {target_count} ({anchor_type})"
        
        lines.append(
            f"{symbol} +{pct_change:.1f}% | "
            f"last ${last_price:.2f} | "
            f"prev ${previous_close:.2f} | "
            f"anchor ({HAIRCUT_RATE*100:.1f}%) {anchor_str} | "
            f"{target_info}"
        )
    
    return "\n".join(lines)


def main():
    """Main execution function."""
    # Check time window
    if not check_time_window():
        print("Outside market hours or not a weekday. Exiting silently.")
        return
    
    # Initialize components
    state_manager = GistStateManager(GIST_ID, GH_PAT)
    stock_fetcher = StockDataFetcher(TWELVE_DATA_API_KEY)
    analyst_fetcher = AnalystTargetFetcher(FMP_API_KEY)
    
    # Get today's date string
    pt_now = datetime.now(PT_TIMEZONE)
    today_str = pt_now.strftime("%Y-%m-%d")
    
    # Load state
    state = state_manager.get_state()
    alerted_today = set(state.get(today_str, []))
    
    # Get market movers
    symbols = stock_fetcher.get_market_movers()
    if not symbols:
        print("No market movers found. Exiting silently.")
        return
    
    # Process each symbol
    qualifying_symbols = []
    new_alerts = []
    
    for symbol in symbols:
        # Skip if already alerted today
        if symbol in alerted_today:
            continue
        
        # Get quote data
        quote_data = stock_fetcher.get_quote(symbol)
        if not quote_data:
            continue
        
        previous_close = quote_data["previous_close"]
        last_price = quote_data["last_price"]
        
        # Calculate percentage change
        pct_change = ((last_price - previous_close) / previous_close) * 100
        
        # Check threshold
        if pct_change < ALERT_THRESHOLD_PCT:
            continue
        
        # Get analyst targets
        individual_targets = analyst_fetcher.get_individual_targets(symbol)
        consensus_target = None
        if len(individual_targets) < 3:
            consensus_target = analyst_fetcher.get_consensus_target(symbol)
        
        # Calculate anchor
        anchor, anchor_type = calculate_anchor(individual_targets, consensus_target, HAIRCUT_RATE)
        
        # Store qualifying symbol
        qualifying_symbols.append({
            "symbol": symbol,
            "pct_change": pct_change,
            "last_price": last_price,
            "previous_close": previous_close,
            "anchor": anchor,
            "target_count": len(individual_targets),
            "anchor_type": anchor_type
        })
        
        new_alerts.append(symbol)
    
    # If no qualifying symbols, exit silently
    if not qualifying_symbols:
        print("No symbols meet threshold. Exiting silently.")
        return
    
    # Update state
    if today_str not in state:
        state[today_str] = []
    state[today_str].extend(new_alerts)
    state_manager.update_state(state)
    
    # Post to Discord
    message = format_discord_message(qualifying_symbols)
    
    try:
        # Use Discord REST API to send message
        headers = {
            "Authorization": f"Bot {DISCORD_BOT_TOKEN}",
            "Content-Type": "application/json"
        }
        payload = {
            "content": message
        }
        response = requests.post(
            f"https://discord.com/api/v10/channels/{DISCORD_CHANNEL_ID}/messages",
            headers=headers,
            json=payload,
            timeout=10
        )
        response.raise_for_status()
        print(f"Posted alert for {len(qualifying_symbols)} symbols to Discord.")
    except Exception as e:
        print(f"Error posting to Discord: {e}")


if __name__ == "__main__":
    main()
