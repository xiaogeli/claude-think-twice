#!/usr/bin/env bash
# claude-think-twice pre-push hook.
#
# Fires on any Bash tool call matching `git push*`. Computes the pending diff
# against upstream, classifies changed files against the scan matrix, and asks
# the human to confirm before the push proceeds.
#
# This hook does NOT try to verify that scans were actually run — that's
# intentionally impossible to do reliably from a hook. The human prompt is the
# enforcement.

set -euo pipefail

# Claude Code passes the tool call as JSON on stdin. Python handles JSON because
# jq is not guaranteed. Prefer python3; fall back to python (common on Windows
# Git Bash).
if command -v python3 >/dev/null 2>&1; then PY=python3
elif command -v python  >/dev/null 2>&1; then PY=python
else
  echo "claude-think-twice pre-push hook requires python3 or python on PATH." >&2
  exit 0  # fail-open: missing dep is not the agent's fault; do not block push
fi

INPUT="$(cat)"

CWD="$(printf '%s' "$INPUT" | "$PY" -c 'import json,sys; print(json.load(sys.stdin).get("cwd",""))' 2>/dev/null || true)"
if [[ -z "$CWD" ]]; then CWD="$PWD"; fi
cd "$CWD" 2>/dev/null || true

# Changed files since upstream. Falls back to "last 5 commits" when no upstream
# is configured (e.g. first push on a new branch).
FILES="$(git diff --name-only '@{upstream}..HEAD' 2>/dev/null || git diff --name-only 'HEAD~5..HEAD' 2>/dev/null || true)"

matrix=""
add_row() {
  matrix="${matrix}  - ${1}
"
}

# Classify each changed file into a minimum scan. Keep this list in sync with
# .claude/skills/think-twice/SKILL.md so the hook reminder matches the skill content.
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  case "$f" in
    *.sh)           add_row "$f → bash -n $f" ;;
    *.py)           add_row "$f → python -m py_compile $f (+ pytest on touched modules)" ;;
    *.ts|*.tsx|*.js|*.jsx|*.css|*.scss) add_row "$f → npm run build" ;;
    *.sql)          add_row "$f → grep INSERT/UPDATE/SELECT call sites against new schema" ;;
    *.json|*.yaml|*.yml|*.toml) add_row "$f → grep config call sites; verify settings resolve" ;;
    *)              add_row "$f → no matrix entry; pick the closest scan and state why" ;;
  esac
done <<< "$FILES"

if [[ -z "$matrix" ]]; then
  matrix="  (no files detected in pending diff — sanity-check your branch state before pushing)
"
fi

REASON="claude-think-twice: review before git push.

Files in your pending diff:
${matrix}
Invoke /think-twice to walk the red-flag self-check and emit SCANNED: confirmations. Then allow this push."

# Emit an ask decision so Claude Code surfaces the prompt to the human. The
# human is the actual beat of reflection — an allow-with-context here would let the push
# through unchanged.
"$PY" - "$REASON" <<'PY'
import json, sys
reason = sys.argv[1]
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": reason,
    }
}))
PY
