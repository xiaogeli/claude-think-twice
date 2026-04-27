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
#
# Structure: classify_file is a pure function (no side effects, no I/O) so it
# can be sourced and unit-tested in isolation by tests/run.sh. main() runs
# the whole pipeline and only fires when the script is executed directly,
# not sourced.

# Decide whether a Bash command should trigger the think-twice prompt.
# Returns 0 (yes, handle) only for `git push` and `git push <args...>`. We
# filter inside the script because Claude Code's PreToolUse `matcher` field
# matches on tool name only — it can't filter by command content. The hook is
# wired with matcher="Bash", so it fires on every Bash call; this function is
# the gate that keeps it silent for `ls`, `grep`, `cat`, etc.
should_handle_command() {
  local cmd="$1"
  # Trim leading whitespace so " git push" still matches.
  cmd="${cmd#"${cmd%%[![:space:]]*}"}"
  case "$cmd" in
    "git push"|"git push "*) return 0 ;;
    *) return 1 ;;
  esac
}

# Classify a single changed-file path into a scan-matrix line.
# Pure: takes a filename, prints one line, no I/O. Keep this in sync with
# .claude/skills/think-twice/SKILL.md so the hook reminder matches the skill.
classify_file() {
  local f="$1"
  case "$f" in
    *.sh)
      printf '%s → bash -n %s\n' "$f" "$f" ;;
    *.py)
      printf '%s → python -m py_compile %s (+ pytest on touched modules)\n' "$f" "$f" ;;
    *.ts|*.tsx|*.js|*.jsx|*.css|*.scss)
      printf '%s → npm run build\n' "$f" ;;
    *.sql)
      printf '%s → grep INSERT/UPDATE/SELECT call sites against new schema\n' "$f" ;;
    *.json|*.yaml|*.yml|*.toml)
      printf '%s → grep config call sites; verify settings resolve\n' "$f" ;;
    *)
      printf '%s → no matrix entry; pick the closest scan and state why\n' "$f" ;;
  esac
}

main() {
  set -euo pipefail

  # Claude Code passes the tool call as JSON on stdin. Python handles JSON
  # because jq is not guaranteed. Prefer python3; fall back to python (common
  # on Windows Git Bash).
  local PY
  if command -v python3 >/dev/null 2>&1; then PY=python3
  elif command -v python  >/dev/null 2>&1; then PY=python
  else
    echo "claude-think-twice pre-push hook requires python3 or python on PATH." >&2
    exit 0  # fail-open: missing dep is not the agent's fault; do not block push
  fi

  local INPUT CWD COMMAND FILES
  INPUT="$(cat)"

  # Filter on command content. The hook is wired with matcher="Bash" so it
  # fires on every Bash call; we only act on `git push*`.
  COMMAND="$(printf '%s' "$INPUT" | "$PY" -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || true)"
  if ! should_handle_command "$COMMAND"; then
    exit 0
  fi

  CWD="$(printf '%s' "$INPUT" | "$PY" -c 'import json,sys; print(json.load(sys.stdin).get("cwd",""))' 2>/dev/null || true)"
  if [[ -z "$CWD" ]]; then CWD="$PWD"; fi
  cd "$CWD" 2>/dev/null || true

  # Changed files since upstream. Falls back to "last 5 commits" when no
  # upstream is configured (e.g. first push on a new branch).
  FILES="$(git diff --name-only '@{upstream}..HEAD' 2>/dev/null || git diff --name-only 'HEAD~5..HEAD' 2>/dev/null || true)"

  local matrix=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    matrix="${matrix}  - $(classify_file "$f")
"
  done <<< "$FILES"

  if [[ -z "$matrix" ]]; then
    matrix="  (no files detected in pending diff — sanity-check your branch state before pushing)
"
  fi

  local REASON
  REASON="claude-think-twice: review before git push.

Files in your pending diff:
${matrix}
Invoke /think-twice to walk the red-flag self-check and emit SCANNED: confirmations. Then allow this push."

  # Emit an ask decision so Claude Code surfaces the prompt to the human. The
  # human is the actual beat of reflection — an allow-with-context here would
  # let the push through unchanged.
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
}

# Only run main when executed directly. When sourced (by the test harness),
# expose classify_file as a function without consuming stdin or cd-ing around.
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  main "$@"
fi
