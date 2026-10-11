#!/usr/bin/env bash
set -euo pipefail

# Self-test for scripts/check-build-settings.sh. It feeds the check synthetic
# build-setting dumps and asserts it accepts the pinned values and rejects every
# drift, missing settings, and a tracked generated project.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
check="$here/check-build-settings.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cd "$work"
git init -q
mkdir -p Joghd.xcodeproj
: > Joghd.xcodeproj/project.pbxproj

# Deliberately mirrors the pins in the check, as an independent source of truth.
# A new pin must be added here too, or the check's "missing setting" case would
# not cover it.
good="$work/settings.good"
cat > "$good" <<'EOF'
    SWIFT_VERSION = 6.0
    IPHONEOS_DEPLOYMENT_TARGET = 17.0
    SWIFT_STRICT_CONCURRENCY = complete
    SWIFT_TREAT_WARNINGS_AS_ERRORS = YES
    TARGETED_DEVICE_FAMILY = 1
    PRODUCT_BUNDLE_IDENTIFIER = dev.djawadi.joghd.ios
    SUPPORTS_MACCATALYST = NO
EOF

failures=0

expect_pass() {
  if ! "$check" < "$1" >/dev/null 2>&1; then
    echo "FAIL: expected a pass for $2" >&2
    failures=$((failures + 1))
  fi
}

expect_fail() {
  if "$check" < "$1" >/dev/null 2>&1; then
    echo "FAIL: expected a failure for $2" >&2
    failures=$((failures + 1))
  fi
}

expect_pass "$good" "the pinned settings"

# Each pinned setting must fail the check when its value drifts.
while read -r line; do
  [[ -n "$line" ]] || continue
  key="$(printf '%s\n' "$line" | awk '{print $1}')"
  mutated="$work/settings.$key"
  sed "s/^\([[:space:]]*$key = \).*$/\1__drift__/" "$good" > "$mutated"
  expect_fail "$mutated" "$key = __drift__"
done < "$good"

# A build-settings dump with the pins missing must fail.
: > "$work/settings.empty"
expect_fail "$work/settings.empty" "no build settings"

# A generated project that got committed must fail.
git add Joghd.xcodeproj/project.pbxproj
expect_fail "$good" "a tracked generated project"

if (( failures > 0 )); then
  echo "check-build-settings self-test failed with ${failures} case(s)." >&2
  exit 1
fi

echo "check-build-settings self-test passed."
