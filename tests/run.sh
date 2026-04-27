#!/usr/bin/env bash
# claude-think-twice test harness.
#
# Sources pre-push.sh and exercises classify_file in isolation against every
# extension the scan matrix knows about, plus the fallback case. The full
# pipeline (stdin parsing, git diff, JSON output) is intentionally not tested
# here — it depends on a real git repo and Claude Code's hook payload format,
# both of which would make the harness slow and brittle. The classification
# logic is the part that grows when contributors add scan-matrix rows, so
# that's the part we lock in.
#
# Usage: tests/run.sh
# Exit code: number of failed cases (0 = all pass).

set -u

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$REPO_DIR/.claude/hooks/pre-push.sh"

if [ ! -f "$HOOK" ]; then
  echo "ERROR: hook not found at $HOOK" >&2
  exit 99
fi

# shellcheck source=/dev/null
source "$HOOK"

if ! declare -F classify_file >/dev/null; then
  echo "ERROR: classify_file function not exported by pre-push.sh" >&2
  exit 99
fi

PASS=0
FAIL=0
FAIL_NAMES=()

assert_contains() {
  local name="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    PASS=$((PASS + 1))
    printf "  PASS  %s\n" "$name"
  else
    FAIL=$((FAIL + 1))
    FAIL_NAMES+=("$name")
    printf "  FAIL  %s\n" "$name"
    printf "        expected to contain: %s\n" "$needle"
    printf "        actual:              %s\n" "$haystack"
  fi
}

echo "== claude-think-twice test harness =="
echo "  hook: $HOOK"
echo

echo "-- shell --"
assert_contains "*.sh → bash -n" \
  "test.sh → bash -n test.sh" "$(classify_file test.sh)"

echo "-- python --"
assert_contains "*.py → py_compile" \
  "test.py → python -m py_compile test.py" "$(classify_file test.py)"
assert_contains "*.py → pytest reminder" \
  "pytest on touched modules" "$(classify_file test.py)"

echo "-- frontend / build --"
assert_contains "*.ts → npm run build" \
  "test.ts → npm run build" "$(classify_file test.ts)"
assert_contains "*.tsx → npm run build" \
  "Component.tsx → npm run build" "$(classify_file Component.tsx)"
assert_contains "*.js → npm run build" \
  "lib.js → npm run build" "$(classify_file lib.js)"
assert_contains "*.jsx → npm run build" \
  "App.jsx → npm run build" "$(classify_file App.jsx)"
assert_contains "*.css → npm run build" \
  "style.css → npm run build" "$(classify_file style.css)"
assert_contains "*.scss → npm run build" \
  "theme.scss → npm run build" "$(classify_file theme.scss)"

echo "-- sql --"
assert_contains "*.sql → grep INSERT/UPDATE" \
  "0042_add_user.sql → grep INSERT/UPDATE/SELECT call sites" \
  "$(classify_file 0042_add_user.sql)"

echo "-- config --"
assert_contains "*.json → grep config call sites" \
  "config.json → grep config call sites" "$(classify_file config.json)"
assert_contains "*.yaml → grep config call sites" \
  "ci.yaml → grep config call sites" "$(classify_file ci.yaml)"
assert_contains "*.yml → grep config call sites" \
  "ci.yml → grep config call sites" "$(classify_file ci.yml)"
assert_contains "*.toml → grep config call sites" \
  "pyproject.toml → grep config call sites" "$(classify_file pyproject.toml)"

echo "-- fallback --"
assert_contains "unknown ext → no matrix entry" \
  "README.md → no matrix entry" "$(classify_file README.md)"

echo "-- preserves directory in path --"
assert_contains "src/foo.sh keeps prefix" \
  "src/foo.sh → bash -n src/foo.sh" "$(classify_file src/foo.sh)"

TOTAL=$((PASS + FAIL))
echo
echo "== $PASS / $TOTAL passed =="
if [ "$FAIL" -gt 0 ]; then
  echo "Failed cases:"
  for n in "${FAIL_NAMES[@]}"; do echo "  - $n"; done
fi
exit "$FAIL"
