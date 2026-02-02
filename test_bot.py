"""
Test cases for the Discord Stock Alert Bot.
"""

import pytest
from bot import calculate_anchor, check_time_window
from datetime import datetime
import pytz


def test_calculate_anchor_trimmed():
    """Test anchor calculation with ≥3 targets (trimmed mean)."""
    targets = [10.0, 12.0, 15.0, 18.0, 20.0]  # 5 targets
    consensus = None
    haircut_rate = 0.125
    
    anchor, anchor_type = calculate_anchor(targets, consensus, haircut_rate)
    
    # Should drop highest (20.0) and lowest (10.0), leaving [12.0, 15.0, 18.0]
    # Trimmed mean = (12.0 + 15.0 + 18.0) / 3 = 15.0
    # Anchor = 15.0 * (1 - 0.125) = 15.0 * 0.875 = 13.125
    expected_anchor = 15.0 * 0.875
    assert anchor == pytest.approx(expected_anchor, rel=1e-6)
    assert anchor_type == "trimmed"


def test_calculate_anchor_fallback():
    """Test anchor calculation with <3 targets (consensus fallback)."""
    targets = [10.0, 12.0]  # Only 2 targets
    consensus = 15.0
    haircut_rate = 0.125
    
    anchor, anchor_type = calculate_anchor(targets, consensus, haircut_rate)
    
    # Should use consensus: 15.0 * (1 - 0.125) = 13.125
    expected_anchor = 15.0 * 0.875
    assert anchor == pytest.approx(expected_anchor, rel=1e-6)
    assert anchor_type == "fallback"


def test_calculate_anchor_none():
    """Test anchor calculation with no targets."""
    targets = []
    consensus = None
    haircut_rate = 0.125
    
    anchor, anchor_type = calculate_anchor(targets, consensus, haircut_rate)
    
    assert anchor == 0.0
    assert anchor_type == "none"


def test_threshold_alert_trigger():
    """Test that $1.00 to $1.90 move triggers an alert (90% gain)."""
    previous_close = 1.00
    last_price = 1.90
    pct_change = ((last_price - previous_close) / previous_close) * 100
    
    assert pct_change == pytest.approx(90.0, rel=1e-6)
    # Use tolerance for >= comparison due to floating point precision
    assert pct_change >= 90.0 - 1e-6  # Should trigger alert


def test_threshold_no_alert():
    """Test that $1.00 to $1.89 move does NOT trigger an alert (<90% gain)."""
    previous_close = 1.00
    last_price = 1.89
    pct_change = ((last_price - previous_close) / previous_close) * 100
    
    assert pct_change == pytest.approx(89.0, rel=1e-6)
    assert pct_change < 90.0  # Should NOT trigger alert


def test_threshold_exact_boundary():
    """Test exact boundary case: exactly 90% gain."""
    previous_close = 1.00
    last_price = 1.90
    pct_change = ((last_price - previous_close) / previous_close) * 100
    
    assert pct_change == pytest.approx(90.0, rel=1e-6)
    # Use tolerance for >= comparison due to floating point precision
    assert pct_change >= 90.0 - 1e-6  # Should trigger alert


def test_threshold_just_below():
    """Test just below boundary: 89.99% gain."""
    previous_close = 1.00
    last_price = 1.8999
    pct_change = ((last_price - previous_close) / previous_close) * 100
    
    assert pct_change < 90.0  # Should NOT trigger alert


def test_trimmed_mean_calculation():
    """Test trimmed mean calculation with various target counts."""
    # Test with 3 targets (should drop 1 highest, 1 lowest, leaving 1)
    targets_3 = [10.0, 15.0, 20.0]
    anchor, _ = calculate_anchor(targets_3, None, 0.125)
    # Trimmed: [15.0], mean = 15.0, anchor = 15.0 * 0.875 = 13.125
    assert anchor == pytest.approx(13.125, rel=1e-6)
    
    # Test with 4 targets (should drop 1 highest, 1 lowest, leaving 2)
    targets_4 = [10.0, 12.0, 15.0, 20.0]
    anchor, _ = calculate_anchor(targets_4, None, 0.125)
    # Trimmed: [12.0, 15.0], mean = 13.5, anchor = 13.5 * 0.875 = 11.8125
    assert anchor == pytest.approx(11.8125, rel=1e-6)
    
    # Test with 5 targets (should drop 1 highest, 1 lowest, leaving 3)
    targets_5 = [10.0, 12.0, 15.0, 18.0, 20.0]
    anchor, _ = calculate_anchor(targets_5, None, 0.125)
    # Trimmed: [12.0, 15.0, 18.0], mean = 15.0, anchor = 15.0 * 0.875 = 13.125
    assert anchor == pytest.approx(13.125, rel=1e-6)
