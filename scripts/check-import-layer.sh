#!/usr/bin/env bash
set -euo pipefail

domain_dir="${1:-Joghd/Domain}"

if [[ ! -d "$domain_dir" ]]; then
  echo "error: domain directory not found: $domain_dir" >&2
  exit 1
fi

matches="$(
  grep -rnE \
    '^[[:space:]]*(@preconcurrency[[:space:]]+)?((public|package|internal|fileprivate|private)[[:space:]]+)?import[[:space:]]+((typealias|struct|class|enum|protocol|let|var|func)[[:space:]]+)?(SwiftUI|UIKit|AppKit)\b' \
    --include='*.swift' \
    "$domain_dir" || true
)"

if [[ -n "$matches" ]]; then
  echo "Import-layer violation: the domain layer must not import UI frameworks." >&2
  echo "$matches" >&2
  exit 1
fi

echo "Import-layer check passed: no UI framework imports under $domain_dir"
