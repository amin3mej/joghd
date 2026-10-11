#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
set -euo pipefail

# Every source file must carry the project's SPDX license identifier on its
# first line (or, for shell scripts, the line after the shebang). "Source
# files" are the Swift and shell sources; configuration such as YAML and JSON
# is out of scope.
readonly spdx_id='SPDX-License-Identifier: MPL-2.0'

# Print the comment the given source file must begin with, or fail if the file
# is not a source file this check covers.
expected_header() {
  case "$1" in
    *.swift) printf '// %s' "$spdx_id" ;;
    *.sh) printf '# %s' "$spdx_id" ;;
    *) return 1 ;;
  esac
}

# Print the first line of the file that is not a shebang.
first_code_line() {
  local line
  while IFS= read -r line; do
    [[ "$line" == '#!'* ]] && continue
    printf '%s' "$line"
    return 0
  done < "$1"
  return 0
}

# Exit non-zero, with a message, when the file's header is missing or wrong.
check_file() {
  local file="$1" expected actual
  expected="$(expected_header "$file")" || return 0
  actual="$(first_code_line "$file")"
  if [[ "$actual" != "$expected" ]]; then
    printf 'Missing or incorrect SPDX header: %s\n  expected: %s\n' \
      "$file" "$expected" >&2
    return 1
  fi
  return 0
}

# List the source files to check. With no arguments, every source file tracked
# by git; otherwise the source files under each given path.
source_files() {
  if (($# == 0)); then
    git ls-files -- '*.swift' '*.sh'
    return
  fi
  local root
  for root in "$@"; do
    if [[ -d "$root" ]]; then
      find "$root" -type f \( -name '*.swift' -o -name '*.sh' \) \
        -not -path '*/.git/*'
    else
      printf '%s\n' "$root"
    fi
  done
}

if (($# == 0)); then
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'error: not inside a git work tree; pass paths to check explicitly\n' >&2
    exit 1
  fi
else
  for root in "$@"; do
    if [[ ! -e "$root" ]]; then
      printf 'error: path not found: %s\n' "$root" >&2
      exit 1
    fi
  done
fi

failures=0
while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  if ! check_file "$file"; then
    failures=$((failures + 1))
  fi
done < <(source_files "$@" | sort -u)

if ((failures > 0)); then
  printf 'SPDX header check failed with %d violation(s).\n' "$failures" >&2
  exit 1
fi

echo "SPDX header check passed."
