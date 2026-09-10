#!/usr/bin/env bash
# PostToolUse hook: after an Edit/Write/MultiEdit, swift-format the touched file in place
# if it's a .swift file. Reads the tool-input JSON from stdin. Never fails the tool call.
set -uo pipefail

input="$(cat)"
path="$(printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("tool_input",{}).get("file_path",""))' 2>/dev/null || true)"

if [[ -z "$path" || "$path" != *.swift ]]; then
    exit 0
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
xcrun swift-format format --in-place --configuration "$root/.swift-format" "$path" 2>/dev/null || true

exit 0
