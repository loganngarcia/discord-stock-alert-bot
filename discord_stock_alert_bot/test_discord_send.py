#!/usr/bin/env python3
"""
Test script to send a Discord message.
Uses environment variables or prompts for token.
"""

import requests
import os
import sys

DISCORD_BOT_TOKEN = os.getenv("DISCORD_BOT_TOKEN", "")
DISCORD_CHANNEL_ID = os.getenv("DISCORD_CHANNEL_ID", "1467511972940746955")

if not DISCORD_BOT_TOKEN:
    print("❌ DISCORD_BOT_TOKEN not found in environment")
    print("   Set it with: export DISCORD_BOT_TOKEN='your_token'")
    sys.exit(1)

print("🧪 Testing Discord Message Send...")
print(f"   Channel ID: {DISCORD_CHANNEL_ID}")
print(f"   Token: {DISCORD_BOT_TOKEN[:20]}...")
print()

headers = {
    "Authorization": f"Bot {DISCORD_BOT_TOKEN}",
    "Content-Type": "application/json"
}

payload = {
    "content": "Hello world!"
}

try:
    response = requests.post(
        f"https://discord.com/api/v10/channels/{DISCORD_CHANNEL_ID}/messages",
        headers=headers,
        json=payload,
        timeout=10
    )
    
    if response.status_code == 200:
        data = response.json()
        print("✅ SUCCESS! Message sent to Discord!")
        print(f"   Message ID: {data.get('id', 'N/A')}")
        print(f"   Channel: {data.get('channel_id', 'N/A')}")
        print(f"   Content: '{data.get('content', 'N/A')}'")
        print()
        print("🎉 Check your #stock-alerts channel - you should see 'Hello world!'")
    elif response.status_code == 401:
        print("❌ 401 Unauthorized")
        print("   Bot token is invalid or expired.")
        print("   Please verify the token in Discord Developer Portal.")
    elif response.status_code == 403:
        print("❌ 403 Forbidden")
        print("   Bot may not have 'Send Messages' permission.")
        print("   Check bot permissions in Discord server settings.")
    elif response.status_code == 404:
        print("❌ 404 Not Found")
        print(f"   Channel ID {DISCORD_CHANNEL_ID} not found.")
        print("   Verify the channel ID is correct.")
    else:
        print(f"❌ Error {response.status_code}")
        print(f"   Response: {response.text[:200]}")
        
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
