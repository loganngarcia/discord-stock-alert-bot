#!/usr/bin/env python3
"""
Discord Stock Alert Bot

A production-ready bot that monitors US stock market movers every 5 minutes during
market hours (10am-3pm PT, weekdays) and alerts on Discord when symbols gain ≥90%
compared to their previous close. Includes intelligent analyst target analysis using
a trimmed-and-haircut algorithm.

Features:
    - Automated monitoring via GitHub Actions
    - Smart threshold detection (≥90% gain)
    - Analyst target analysis with trimmed-and-haircut anchor
    - Daily deduplication using GitHub Gist
    - Silent operation (no alerts when no qualifying symbols)

Author: Logan Garcia
License: MIT
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
# Handle optional env vars - use defaults if empty or missing
_alert_threshold = os.getenv("ALERT_THRESHOLD_PCT", "90").strip()
_haircut_rate = os.getenv("HAIRCUT_RATE", "0.125").strip()
ALERT_THRESHOLD_PCT = float(_alert_threshold) if _alert_threshold else 90.0
HAIRCUT_RATE = float(_haircut_rate) if _haircut_rate else 0.125

# Constants
PT_TIMEZONE = pytz.timezone("America/Los_Angeles")
MARKET_OPEN_HOUR = 10
MARKET_CLOSE_HOUR = 15


class GistStateManager:
    """
    Manages daily alert state persistence using GitHub Gist.
    
    This class handles reading and writing the bot's state to a GitHub Gist,
    which tracks which symbols have already been alerted today to prevent
    duplicate alerts.
    
    Attributes:
        gist_id (str): The GitHub Gist ID for state storage
        github_token (str): GitHub Personal Access Token with gist scope
        base_url (str): GitHub API base URL
        headers (dict): HTTP headers for API requests
    
    Example:
        >>> manager = GistStateManager("gist_id", "ghp_token")
        >>> state = manager.get_state()
        >>> manager.update_state({"2026-02-01": ["AAPL", "TSLA"]})
    """
    
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
    """
    Fetches stock market data from the Twelve Data API.
    
    This class provides methods to retrieve market movers and detailed quote
    data for individual symbols. Includes fallback logic for when premium
    endpoints are unavailable.
    
    Attributes:
        api_key (str): Twelve Data API key
        base_url (str): Twelve Data API base URL
    
    Example:
        >>> fetcher = StockDataFetcher("api_key")
        >>> symbols = fetcher.get_market_movers()
        >>> quote = fetcher.get_quote("AAPL")
    """
    
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
    """
    Fetches analyst price targets from Financial Modeling Prep API.
    
    Retrieves individual analyst targets and consensus targets for calculating
    the trimmed-and-haircut anchor price used in alerts.
    
    Attributes:
        api_key (str): Financial Modeling Prep API key
        base_url (str): FMP API base URL
    
    Example:
        >>> fetcher = AnalystTargetFetcher("api_key")
        >>> targets = fetcher.get_individual_targets("AAPL")
        >>> consensus = fetcher.get_consensus_target("AAPL")
    """
    
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


def calculate_anchor(
    targets: List[float], 
    consensus_fallback: Optional[float], 
    haircut_rate: float
) -> Tuple[float, str]:
    """
    Calculate trimmed-and-haircut anchor price from analyst targets.
    
    Implements a robust anchor calculation algorithm:
    1. If ≥3 targets: Sort, drop highest/lowest, calculate trimmed mean, apply haircut
    2. If <3 targets: Use consensus mean, apply haircut
    3. If no targets: Return 0.0 with "none" label
    
    Args:
        targets: List of individual analyst price targets
        consensus_fallback: Consensus (mean) target if <3 individual targets
        haircut_rate: Haircut rate to apply (e.g., 0.125 for 12.5%)
    
    Returns:
        Tuple of (anchor_price, calculation_method) where method is:
        - "trimmed": Used trimmed mean of ≥3 targets
        - "fallback": Used consensus mean
        - "none": No targets available
    
    Example:
        >>> targets = [10.0, 12.0, 15.0, 18.0, 20.0]
        >>> anchor, method = calculate_anchor(targets, None, 0.125)
        >>> anchor  # 13.125 (trimmed mean of [12, 15, 18] with 12.5% haircut)
        >>> method  # "trimmed"
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
    """
    Check if current time is within market hours on a weekday.
    
    Validates that the current Pacific Time is:
    - Between 10:00 and 15:00 (10am-3pm)
    - On a weekday (Monday-Friday)
    
    Returns:
        True if within market hours and weekday, False otherwise
    
    Example:
        >>> check_time_window()  # Returns True if 10am-3pm PT on weekday
    """
    pt_now = datetime.now(PT_TIMEZONE)
    
    # Check if weekday (Monday=0, Friday=4)
    if pt_now.weekday() > 4:
        return False
    
    # Check if within market hours
    current_hour = pt_now.hour
    return MARKET_OPEN_HOUR <= current_hour < MARKET_CLOSE_HOUR


def format_discord_message(qualifying_symbols: List[Dict]) -> str:
    """
    Format Discord alert message with all qualifying symbols.
    
    Creates a formatted message containing:
    - Header with threshold and timestamp
    - One line per qualifying symbol with:
      * Symbol ticker
      * Percentage gain
      * Current and previous prices
      * Analyst anchor price
      * Target count and calculation method
    
    Args:
        qualifying_symbols: List of dicts containing symbol data:
            - symbol: Stock ticker
            - pct_change: Percentage gain
            - last_price: Current price
            - previous_close: Previous close price
            - anchor: Calculated anchor price
            - target_count: Number of analyst targets
            - anchor_type: Calculation method ("trimmed", "fallback", "none")
    
    Returns:
        Formatted message string ready for Discord
    
    Example:
        >>> symbols = [{"symbol": "ABC", "pct_change": 132.4, ...}]
        >>> message = format_discord_message(symbols)
        >>> print(message)
        ALERT: ≥ 90% movers (10:35 PT)
        ABC +132.4% | last $2.18 | prev $0.94 | anchor (12.5%) $4.40 | targets 7 (trimmed)
    """
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
    """
    Main execution function for the Discord Stock Alert Bot.
    
    Orchestrates the complete bot workflow:
    1. Validates time window (market hours, weekdays)
    2. Fetches market movers
    3. Filters symbols by threshold (≥90% gain)
    4. Calculates analyst anchors
    5. Checks daily deduplication state
    6. Posts Discord alerts for qualifying symbols
    
    Exits silently if:
    - Outside market hours
    - No market movers found
    - No symbols meet threshold
    
    Returns:
        0 on success or expected silent exits, 1 on critical errors
    """
    try:
        # Validate required environment variables
        required_vars = {
            "TWELVE_DATA_API_KEY": TWELVE_DATA_API_KEY,
            "FMP_API_KEY": FMP_API_KEY,
            "DISCORD_BOT_TOKEN": DISCORD_BOT_TOKEN,
            "DISCORD_CHANNEL_ID": DISCORD_CHANNEL_ID,
            "GIST_ID": GIST_ID,
            "GH_PAT": GH_PAT,
        }
        
        missing_vars = [var for var, value in required_vars.items() if not value]
        if missing_vars:
            print(f"ERROR: Missing required environment variables: {', '.join(missing_vars)}")
            print("Please ensure all required secrets are set in GitHub Actions.")
            return 1
        
        print(f"✅ Configuration loaded: threshold={ALERT_THRESHOLD_PCT}%, haircut={HAIRCUT_RATE*100:.1f}%")
        
        # Check time window
        if not check_time_window():
            print("Outside market hours or not a weekday. Exiting silently.")
            return 0
        
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
            return 0
        print(f"📊 Found {len(symbols)} market movers to check")
        
        # Process each symbol
        qualifying_symbols = []
        new_alerts = []
        checked_count = 0
        skipped_already_alerted = 0
        skipped_below_threshold = 0
        
        for symbol in symbols:
            # Skip if already alerted today
            if symbol in alerted_today:
                skipped_already_alerted += 1
                continue
            
            # Get quote data
            quote_data = stock_fetcher.get_quote(symbol)
            if not quote_data:
                continue
            
            checked_count += 1
            previous_close = quote_data["previous_close"]
            last_price = quote_data["last_price"]
            
            # Calculate percentage change
            pct_change = ((last_price - previous_close) / previous_close) * 100
            
            # Check threshold
            if pct_change < ALERT_THRESHOLD_PCT:
                skipped_below_threshold += 1
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
            print(f"📊 Summary: Checked {checked_count} symbols")
            print(f"   - Already alerted today: {skipped_already_alerted}")
            print(f"   - Below {ALERT_THRESHOLD_PCT}% threshold: {skipped_below_threshold}")
            print(f"   - Qualifying symbols: 0")
            print("No symbols meet threshold. Exiting silently.")
            return 0
        
        print(f"📊 Summary: Checked {checked_count} symbols")
        print(f"   - Already alerted today: {skipped_already_alerted}")
        print(f"   - Below {ALERT_THRESHOLD_PCT}% threshold: {skipped_below_threshold}")
        print(f"   - Qualifying symbols: {len(qualifying_symbols)}")
        
        # Update state
        if today_str not in state:
            state[today_str] = []
        state[today_str].extend(new_alerts)
        if not state_manager.update_state(state):
            print("WARNING: Failed to update Gist state, but continuing with Discord post.")
        
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
            
            # Check response status
            if response.status_code == 200:
                data = response.json()
                message_id = data.get("id")
                print(f"✅ Posted alert for {len(qualifying_symbols)} symbols to Discord.")
                print(f"   Message ID: {message_id}")
                
                # Verify message was actually posted by fetching it back
                try:
                    verify_response = requests.get(
                        f"https://discord.com/api/v10/channels/{DISCORD_CHANNEL_ID}/messages/{message_id}",
                        headers=headers,
                        timeout=10
                    )
                    if verify_response.status_code == 200:
                        verify_data = verify_response.json()
                        if verify_data.get("id") == message_id:
                            print(f"✅ Verified: Message confirmed in Discord channel")
                        else:
                            print(f"⚠️  WARNING: Message verification returned different ID")
                    else:
                        print(f"⚠️  WARNING: Could not verify message (status {verify_response.status_code})")
                except Exception as verify_error:
                    print(f"⚠️  WARNING: Could not verify message: {verify_error}")
                
                return 0
            else:
                # Handle specific error codes
                error_msg = f"Discord API returned {response.status_code}"
                if response.status_code == 401:
                    error_msg += " (Invalid bot token)"
                elif response.status_code == 403:
                    error_msg += " (Bot lacks permissions)"
                elif response.status_code == 404:
                    error_msg += " (Channel not found)"
                elif response.status_code == 429:
                    error_msg += " (Rate limited)"
                else:
                    error_msg += f": {response.text[:200]}"
                
                print(f"❌ ERROR: Failed to post to Discord - {error_msg}")
                return 1  # Fail the workflow for Discord errors
                
        except requests.exceptions.Timeout:
            print(f"❌ ERROR: Discord API timeout - message may not have been sent")
            return 1
        except requests.exceptions.RequestException as e:
            print(f"❌ ERROR: Discord API request failed: {e}")
            return 1
        except Exception as e:
            print(f"❌ ERROR: Unexpected error posting to Discord: {e}")
            import traceback
            traceback.print_exc()
            return 1
            
    except KeyboardInterrupt:
        print("Interrupted by user.")
        return 1
    except Exception as e:
        print(f"CRITICAL ERROR: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    exit(main())
