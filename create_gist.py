#!/usr/bin/env python3
"""
Script to create a GitHub Gist for bot state persistence.
Run this script to create the gist, then add the GIST_ID to your GitHub Secrets.
"""

import requests
import json
import os
import sys

def create_gist(github_token: str):
    """Create a secret gist for bot state."""
    
    headers = {
        "Authorization": f"token {github_token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    payload = {
        "description": "Discord Stock Alert Bot - State persistence",
        "public": False,  # Secret gist
        "files": {
            "state.json": {
                "content": json.dumps({}, indent=2)
            }
        }
    }
    
    try:
        response = requests.post(
            "https://api.github.com/gists",
            headers=headers,
            json=payload,
            timeout=10
        )
        
        if response.status_code == 201:
            gist_data = response.json()
            gist_id = gist_data["id"]
            gist_url = gist_data["html_url"]
            
            print("✅ Gist created successfully!")
            print(f"\n📋 Gist Details:")
            print(f"   Gist ID: {gist_id}")
            print(f"   URL: {gist_url}")
            print(f"\n🔐 Next Steps:")
            print(f"   1. Copy this GIST_ID: {gist_id}")
            print(f"   2. Add it to your GitHub Secrets as 'GIST_ID'")
            print(f"   3. The bot will use this gist to track daily alerts")
            
            return gist_id
        else:
            print(f"❌ Error creating gist: {response.status_code}")
            print(f"Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None


if __name__ == "__main__":
    print("GitHub Gist Creator for Discord Stock Alert Bot\n")
    print("=" * 50)
    
    # Get token from environment or prompt
    github_token = os.getenv("GH_PAT") or os.getenv("GITHUB_TOKEN")
    
    if not github_token:
        print("\n⚠️  No GitHub token found in environment variables.")
        print("\nPlease provide your GitHub Personal Access Token:")
        print("(You can create one at: https://github.com/settings/tokens)")
        print("\nOption 1: Set as environment variable:")
        print("   export GH_PAT='your_token_here'")
        print("   python create_gist.py")
        print("\nOption 2: Enter it now (will not be saved):")
        github_token = input("\nGitHub Token: ").strip()
        
        if not github_token:
            print("\n❌ No token provided. Exiting.")
            sys.exit(1)
    
    print(f"\n🔑 Using GitHub token: {github_token[:10]}...")
    print("\nCreating secret gist...")
    
    gist_id = create_gist(github_token)
    
    if gist_id:
        print(f"\n✅ Setup complete! Add GIST_ID={gist_id} to your GitHub Secrets.")
