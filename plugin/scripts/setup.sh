#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/plugin/mcp-server"

if [[ ! -d node_modules ]]; then
  npm install
fi

npm run build

echo "ObfuscationTool plugin ready."
echo ""
echo "Cursor: restart Cursor to load .cursor/mcp.json"
echo "Codex:  codex plugin marketplace add ./.agents/plugins && restart Codex"
