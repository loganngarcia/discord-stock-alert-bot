#!/usr/bin/env python3
"""
Script to automatically add all secrets to GitHub repository.
Requires: Repository owner, repository name, and GitHub token with admin access.
"""

import requests
import base64
import json
import sys
import os

# Secrets to add
# NOTE: Replace these with your actual values from .secrets.local.md
# This file should NOT contain real secrets - use environment variables or .secrets.local.md
SECRETS = {
    "TWELVE_DATA_API_KEY": "YOUR_TWELVE_DATA_API_KEY",
    "FMP_API_KEY": "YOUR_FMP_API_KEY",
    "DISCORD_BOT_TOKEN": "YOUR_DISCORD_BOT_TOKEN",
    "DISCORD_CHANNEL_ID": "YOUR_DISCORD_CHANNEL_ID",
    "GIST_ID": "YOUR_GIST_ID",
    "GH_PAT": "YOUR_GITHUB_PAT_TOKEN",
    "ALERT_THRESHOLD_PCT": "90",
    "HAIRCUT_RATE": "0.125"
}

def get_public_key(owner, repo, token):
    """Get the repository's public key for encrypting secrets."""
    url = f"https://api.github.com/repos/{owner}/{repo}/actions/secrets/public-key"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    response = requests.get(url, headers=headers, timeout=10)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"❌ Error getting public key: {response.status_code}")
        print(f"   {response.text[:200]}")
        return None

def encrypt_secret(public_key, secret_value):
    """Encrypt secret using repository's public key."""
    from cryptography.hazmat.primitives import hashes
    from cryptography.hazmat.primitives.asymmetric import padding
    from cryptography.hazmat.primitives.serialization import load_pem_public_key, load_der_public_key
    import base64
    
    try:
        # GitHub's public key is base64-encoded DER format
        # Decode it to get DER bytes
        der_bytes = base64.b64decode(public_key)
        
        # Try loading as DER first (GitHub's format)
        try:
            key = load_der_public_key(der_bytes)
        except:
            # If DER fails, try wrapping in PEM format
            pem_data = base64.b64encode(der_bytes).decode('utf-8')
            # Add line breaks every 64 chars for PEM format
            pem_lines = '\n'.join([pem_data[i:i+64] for i in range(0, len(pem_data), 64)])
            pem_string = f"-----BEGIN PUBLIC KEY-----\n{pem_lines}\n-----END PUBLIC KEY-----"
            key = load_pem_public_key(pem_string.encode('utf-8'))
        
        # Encrypt the secret
        encrypted = key.encrypt(
            secret_value.encode('utf-8'),
            padding.OAEP(
                mgf=padding.MGF1(algorithm=hashes.SHA256()),
                algorithm=hashes.SHA256(),
                label=None
            )
        )
        
        return base64.b64encode(encrypted).decode('utf-8')
    except Exception as e:
        print(f"❌ Encryption error: {e}")
        return None

def add_secret(owner, repo, secret_name, encrypted_value, key_id, token):
    """Add a secret to the repository."""
    url = f"https://api.github.com/repos/{owner}/{repo}/actions/secrets/{secret_name}"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json",
        "Content-Type": "application/json"
    }
    
    payload = {
        "encrypted_value": encrypted_value,
        "key_id": key_id
    }
    
    response = requests.put(url, headers=headers, json=payload, timeout=10)
    return response.status_code in [201, 204]

def main():
    print("GitHub Secrets Auto-Adder")
    print("=" * 50)
    
    # Get repository info
    owner = os.getenv("GITHUB_OWNER") or input("\nGitHub username/organization: ").strip()
    repo = os.getenv("GITHUB_REPO") or input("Repository name: ").strip()
    token = os.getenv("GH_PAT") or os.getenv("GITHUB_TOKEN") or input("GitHub token (with repo/admin access): ").strip()
    
    if not owner or not repo or not token:
        print("\n❌ Missing required information!")
        sys.exit(1)
    
    print(f"\n📦 Repository: {owner}/{repo}")
    print(f"🔑 Token: {token[:10]}...")
    
    # Get public key
    print("\n1. Getting repository public key...")
    public_key_data = get_public_key(owner, repo, token)
    if not public_key_data:
        print("\n❌ Failed to get public key. Make sure:")
        print("   - Repository exists")
        print("   - Token has 'repo' scope")
        print("   - You have admin access to the repository")
        sys.exit(1)
    
    public_key = public_key_data["key"]
    key_id = public_key_data["key_id"]
    print(f"   ✅ Got public key (ID: {key_id})")
    
    # Add each secret
    print(f"\n2. Adding {len(SECRETS)} secrets...")
    success_count = 0
    failed = []
    
    for secret_name, secret_value in SECRETS.items():
        print(f"   Adding {secret_name}...", end=" ")
        
        # Encrypt the secret
        encrypted = encrypt_secret(public_key, secret_value)
        if not encrypted:
            print("❌ Encryption failed")
            failed.append(secret_name)
            continue
        
        # Add the secret
        if add_secret(owner, repo, secret_name, encrypted, key_id, token):
            print("✅")
            success_count += 1
        else:
            print("❌ Failed")
            failed.append(secret_name)
    
    # Summary
    print("\n" + "=" * 50)
    print(f"✅ Successfully added: {success_count}/{len(SECRETS)} secrets")
    
    if failed:
        print(f"❌ Failed: {', '.join(failed)}")
        print("\nYou may need to add these manually:")
        for name in failed:
            print(f"   - {name}")
    
    if success_count == len(SECRETS):
        print("\n🎉 All secrets added successfully!")
        print(f"\n✅ Your bot is ready to deploy!")
        print(f"   Repository: https://github.com/{owner}/{repo}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
