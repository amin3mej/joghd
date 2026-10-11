#!/usr/bin/env bash
set -euo pipefail

# Import-layer rule: the domain layer must not depend on UI frameworks. The
# domain types (see ../GLOSSARY.md) are plain Swift; they may import Foundation
# and other non-UI frameworks only. Importing SwiftUI, UIKit, or AppKit here
# would leak presentation concerns into the domain.
#
# Usage: scripts/check-import-layer.sh [domain-dir]
# Exits non-zero if any Swift file under the domain directory imports a UI
# framework, printing the offending lines.

domain_dir="${1:-Joghd/Domain}"

if [[ ! -d "$domain_dir" ]]; then
  echo "error: domain directory not found: $domain_dir" >&2
  exit 1
fi

matches="$(
  grep -rnE \
    '^import[[:space:]]+(SwiftUI|UIKit|AppKit)\b' \
    --include='*.swift' \
    "$domain_dir" || true
)"

if [[ -n "$matches" ]]; then
  echo "Import-layer violation: the domain layer must not import UI frameworks." >&2
  echo "$matches" >&2
  exit 1
fi

echo "Import-layer check passed: no UI framework imports under $domain_dir"
