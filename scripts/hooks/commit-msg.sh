#!/usr/bin/env bash
# git commit-msg hook: reject subjects that don't follow Conventional Commits.
# Install with: ln -s ../../scripts/hooks/commit-msg.sh .git/hooks/commit-msg
set -euo pipefail

msg_file="$1"
subject="$(head -1 "$msg_file")"
pattern='^(feat|fix|refactor|docs|build|ci|test|chore|perf|style)(\(.+\))?!?: .+'

if ! [[ "$subject" =~ $pattern ]]; then
    echo "error: commit subject doesn't follow Conventional Commits:" >&2
    echo "  $subject" >&2
    echo "expected: type(scope)?: subject — types: feat fix refactor docs build ci test chore perf style" >&2
    exit 1
fi
