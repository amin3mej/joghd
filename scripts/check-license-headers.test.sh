#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
check="$script_dir/check-license-headers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

failures=0
output=""
status=0

# Run the check against a directory, capturing its combined output and exit
# status without tripping `set -e`.
run_check() {
  set +e
  output="$("$check" "$1" 2>&1)"
  status=$?
  set -e
}

expect_exit() {
  local description="$1" expected="$2" dir="$3"
  run_check "$dir"
  if [[ "$status" -ne "$expected" ]]; then
    printf 'not ok: %s (expected exit %s, got %s)\n%s\n' \
      "$description" "$expected" "$status" "$output"
    failures=$((failures + 1))
  else
    printf 'ok: %s\n' "$description"
  fi
}

expect_message() {
  local description="$1" pattern="$2" dir="$3"
  run_check "$dir"
  if [[ "$output" != *"$pattern"* ]]; then
    printf 'not ok: %s (output did not mention %q)\n%s\n' "$description" "$pattern" "$output"
    failures=$((failures + 1))
  else
    printf 'ok: %s\n' "$description"
  fi
}

# A compliant tree: a Swift file, a shell script whose header follows its
# shebang, and a non-source file that is ignored.
mkdir -p "$tmp/compliant"
printf '// SPDX-License-Identifier: MPL-2.0\nimport Foundation\n' > "$tmp/compliant/Good.swift"
printf '#!/usr/bin/env bash\n# SPDX-License-Identifier: MPL-2.0\necho hi\n' > "$tmp/compliant/good.sh"
printf '{"info": {}}\n' > "$tmp/compliant/config.json"
expect_exit "compliant source files pass" 0 "$tmp/compliant"

# A header is still present when the file is a single line with no trailing
# newline.
mkdir -p "$tmp/no-trailing-newline"
printf '// SPDX-License-Identifier: MPL-2.0' > "$tmp/no-trailing-newline/HeaderOnly.swift"
expect_exit "a header-only file with no trailing newline passes" 0 "$tmp/no-trailing-newline"

# A Swift file with no header at all.
mkdir -p "$tmp/missing"
printf 'import Foundation\n' > "$tmp/missing/NoHeader.swift"
expect_exit "a Swift file with no header fails" 1 "$tmp/missing"
expect_message "the offending file is named" "NoHeader.swift" "$tmp/missing"

# A Swift file carrying a different license.
mkdir -p "$tmp/wrong"
printf '// SPDX-License-Identifier: MIT\nimport Foundation\n' > "$tmp/wrong/Wrong.swift"
expect_exit "a Swift file with the wrong header fails" 1 "$tmp/wrong"
expect_message "the expected license is reported" "MPL-2.0" "$tmp/wrong"

# A shell script with a shebang but no header.
mkdir -p "$tmp/shell-missing"
printf '#!/usr/bin/env bash\necho hi\n' > "$tmp/shell-missing/no-header.sh"
expect_exit "a shell script with no header fails" 1 "$tmp/shell-missing"

# Only the first line's shebang is skipped, so a header buried below other
# shebang-like lines does not count.
mkdir -p "$tmp/buried-header"
printf '#!not-a-shebang\n#!also-not-a-shebang\n# SPDX-License-Identifier: MPL-2.0\n' \
  > "$tmp/buried-header/header-on-third.sh"
expect_exit "a header below two shebang-like lines fails" 1 "$tmp/buried-header"

if ((failures > 0)); then
  printf 'SPDX header check tests failed with %d failure(s).\n' "$failures" >&2
  exit 1
fi

echo "SPDX header check tests passed."
