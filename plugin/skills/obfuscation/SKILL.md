---
name: obfuscation-tool
description: >-
  Obfuscate Swift/Objective-C iOS projects: prefix replacement, camelCase/snake_case
  conversion, Swift structure shuffling, and prefix scanning. Use when the user
  asks to obfuscate code, rename prefixes, scan symbol prefixes, or run
  obfuscation.json.
---

# Obfuscation Tool

## When to use

- User wants to obfuscate Swift or Objective-C source code
- User needs to replace symbol/file prefixes (e.g. `BF_` → `ZZ_`)
- User wants to scan for uncovered prefixes before obfuscation
- User mentions `obfuscation.json` or this repository's CLI

## MCP tools

| Tool | Purpose |
|------|---------|
| `obfuscate_run` | Execute obfuscation with a config file |
| `obfuscate_scan_prefixes` | Find prefixes not in official rules (JSON output) |
| `obfuscate_validate_config` | Validate config without writing files |
| `obfuscate_example_config` | Return the SmokeTest example config |

## Workflow

1. Call `obfuscate_example_config` if the user has no config yet.
2. Write or edit `obfuscation.json` at the project root with `input`, `output`, and rules.
3. Call `obfuscate_validate_config` before the first run.
4. Call `obfuscate_scan_prefixes` to discover missing prefix rules.
5. Call `obfuscate_run` to write obfuscated output.

## Config format (CLI)

```json
{
  "input": "path/to/source",
  "output": "path/to/output",
  "keepDirectory": true,
  "replace": {
    "map": { "BF_": "ZZ_", "bf_": "zz_" },
    "onlyPrefix": true
  },
  "camelToSnake": [{ "prefix": "BF_", "toLowercase": false }],
  "shuffule": { "order": true }
}
```

Paths in `input` and `output` are relative to `workingDirectory` (the project root where the agent runs commands).

## Safety

- Default workflow writes to a separate `output` directory; do not point `output` at the source tree unless the user explicitly requests in-place obfuscation.
- Always confirm `input` and `output` paths with the user before `obfuscate_run`.

## CLI (manual)

```bash
# Build once (or set OBFUSCATION_CLI to the Command binary)
xcodebuild -project ObfuscationTool/ObfuscationTool.xcodeproj -scheme Commond -configuration Release build

./Command run -c obfuscation.json
./Command scan -c obfuscation.json
./Command validate -c obfuscation.json
```
