#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python_bin=""
for candidate in python3 python; do
  if command -v "$candidate" >/dev/null 2>&1; then
    python_bin="$candidate"
    break
  fi
done

if [ -z "$python_bin" ]; then
  echo "Python 3.11 or newer is required but was not found on PATH." >&2
  exit 1
fi

exec "$python_bin" "$here/release.py" "$@"
