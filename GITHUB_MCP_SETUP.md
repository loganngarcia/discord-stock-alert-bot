# GitHub MCP Setup Instructions

## Current Status

✅ GitHub MCP is already configured in your Cursor settings at `~/.cursor/mcp.json`

## What You Need to Do

### Step 1: Create GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens/new
2. Give it a name: `Cursor MCP Server`
3. Select scopes (recommended):
   - ✅ `repo` (Full control of private repositories)
   - ✅ `gist` (Create gists)
   - ✅ `workflow` (Update GitHub Action workflows)
   - ✅ `read:org` (Read org and team membership, read org projects)
4. Click "Generate token"
5. **Copy the token immediately** (starts with `ghp_...`)

### Step 2: Add Token to MCP Configuration

You have two options:

#### Option A: Edit the config file directly

Edit `~/.cursor/mcp.json` and replace the empty token:

```json
"env": {
  "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token_here"
}
```

#### Option B: Use environment variable (more secure)

Instead of putting the token in the config file, you can set it as an environment variable:

1. Add to your shell profile (`~/.zshrc` or `~/.bash_profile`):
   ```bash
   export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"
   ```

2. Update `~/.cursor/mcp.json` to reference the env var (it should already work if the env var is set)

### Step 3: Restart Cursor

After adding the token, restart Cursor completely for the changes to take effect.

## Verify It's Working

After restarting Cursor, you should be able to:
- Use GitHub MCP tools in chat
- Create gists programmatically
- Access repository information
- Manage issues and pull requests

## Current Configuration

Your GitHub MCP is configured to use:
- **Package**: `@githubnext/github-mcp-server`
- **Method**: npx (no Docker required)
- **Token**: Currently empty (needs to be set)

## Troubleshooting

If the MCP server doesn't work:

1. **Check the package name**: The package `@githubnext/github-mcp-server` might need to be verified. If it doesn't work, try:
   - `@modelcontextprotocol/server-github` (archived, but might work)
   - Or use the Docker version (original config)

2. **Verify token permissions**: Make sure your token has the required scopes

3. **Check Cursor logs**: Look for MCP-related errors in Cursor's output

4. **Test the package**: Try running manually:
   ```bash
   npx -y @githubnext/github-mcp-server
   ```

## Alternative: Use Docker Version

If the npx version doesn't work, you can switch back to Docker:

```json
"GitHub": {
  "command": "docker",
  "args": [
    "run",
    "-i",
    "--rm",
    "-e",
    "GITHUB_PERSONAL_ACCESS_TOKEN",
    "ghcr.io/github/github-mcp-server"
  ],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token_here"
  }
}
```

(Requires Docker to be installed and running)
