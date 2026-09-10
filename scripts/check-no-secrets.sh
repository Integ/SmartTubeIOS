#!/usr/bin/env bash
set -euo pipefail
if git ls-files | grep -E '(^|/)GoogleService-Info\.plist$|(^|/)Secrets\.xcconfig$' ; then
  echo "ERROR: secret file is tracked" >&2; exit 1
fi
echo "ok: no secrets tracked"
