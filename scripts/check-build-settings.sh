#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
set -euo pipefail

expected_settings() {
  cat <<'EOF'
SWIFT_VERSION 6.0
IPHONEOS_DEPLOYMENT_TARGET 17.0
SWIFT_STRICT_CONCURRENCY complete
SWIFT_TREAT_WARNINGS_AS_ERRORS YES
TARGETED_DEVICE_FAMILY 1
PRODUCT_BUNDLE_IDENTIFIER dev.djawadi.joghd.ios
SUPPORTS_MACCATALYST NO
EOF
}

failures=0
settings="$(cat)"

setting_value() {
  printf '%s\n' "$settings" |
    awk -v key="$1" '
      $0 ~ "^[[:space:]]*" key "[[:space:]]*=[[:space:]]*" {
        sub("^[[:space:]]*" key "[[:space:]]*=[[:space:]]*", "")
        print
        exit
      }
    '
}

while read -r key expected; do
  actual="$(setting_value "$key")"
  if [[ "$actual" != "$expected" ]]; then
    printf 'Pinned build setting drifted: %s is "%s", expected "%s"\n' \
      "$key" "$actual" "$expected" >&2
    failures=$((failures + 1))
  fi
done < <(expected_settings)

if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  tracked="$(git -C "$git_root" ls-files -- Joghd.xcodeproj)"
  if [[ -n "$tracked" ]]; then
    printf 'The generated project must stay untracked, but git tracks:\n%s\n' \
      "$tracked" >&2
    failures=$((failures + 1))
  fi
else
  echo "error: not inside a git work tree; cannot verify Joghd.xcodeproj is untracked" >&2
  failures=$((failures + 1))
fi

if (( failures > 0 )); then
  echo "Pinned build settings check failed with ${failures} violation(s)." >&2
  exit 1
fi

echo "Pinned build settings check passed."
