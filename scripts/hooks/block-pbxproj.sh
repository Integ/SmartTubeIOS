#!/usr/bin/env bash
# PreToolUse hook: refuse Edit/Write/MultiEdit against project.pbxproj or anything
# under an .xcodeproj bundle. Reads the tool-input JSON from stdin.
set -euo pipefail

input="$(cat)"
path="$(printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("tool_input",{}).get("file_path",""))' 2>/dev/null || true)"

if [[ -z "$path" ]]; then
    exit 0
fi

if [[ "$path" == *.xcodeproj/* || "$path" == *.pbxproj ]]; then
    echo "Blocked: agents must not hand-edit the Xcode project ($path). Use Xcode, or ask the maintainer. See docs/RULES.md." >&2
    exit 2
fi

exit 0
