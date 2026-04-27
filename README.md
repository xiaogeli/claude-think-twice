# claude-think-twice

> **Fast ≠ efficient.**
> *The missing beat between "I see the fix" and `git push`.*

A Claude Code **skill + hook** that makes AI coding agents see the one mistake under every reactive-coding moment: the silent belief that *saving myself a round-trip* is the same as *helping the user*. It isn't. When the skipped scan would have caught something, the agent saves itself 20 seconds and costs the user two hours. The account is inverted. This project does exactly one thing — in the second before `git push`, it makes the agent read the account right-way-up.

Sister project: [`claude-prove-done`](https://github.com/xiaogeli/claude-prove-done) — same shape, different beat. *think-twice* stops `--rushed` before `git push`; *prove-done* stops `--imagined` before "I'm done."

---

## The 2-minute story

An AI coding agent already knows the rule: *run scans before you push.* The rule lives in its own project memory. And yet, when a user sends a screenshot with "quick fix please", the agent:

1. Labels the change "small" and drops its guard.
2. Assumes CI will catch mistakes — treating CI as insurance instead of a last line of defense.
3. Confuses **fast** with **efficient** — skipping the scan feels like helping the user sooner.
4. The build breaks. The 20 seconds the agent "saved" become two hours the user waits, plus a broken push the user has to notice.

The account is inverted. The agent booked one round-trip of savings on *its* ledger; the cost landed as three or four round-trips on *the user's* ledger. Those are not the same account. From inside reactive mode, the agent cannot see that — inside reactive mode, "ship it faster" feels synonymous with "help the user more".

`claude-think-twice` is the beat that makes the agent read the account right-way-up, before `git push`, not after CI.

---

## What this really is

This is not a linter. Linters check code. **This checks whether the agent confused fast with efficient.**

Reactive coding isn't laziness or forgetfulness — the agent knows the rule. It runs on one silent belief: *saving myself a round-trip is the same as helping the user.* The belief is wrong. When the skipped scan would have caught something, the agent's 20-second "saving" turns into hours of user wait, a broken build, a rollback, and eroded trust. One round-trip saved on the agent's side; three or more spent on the user's side. **The account is inverted.**

The agent cannot see this from inside the loop — inside the loop, the two accounts look like the same account. `claude-think-twice` drags the trade outside the loop long enough to be read correctly.

Once an agent sees the inversion in its own pending diff — *I was about to save myself 20 seconds and cost the user two hours* — it self-corrects. Not because a hook forced it. Because the math stops working.

Everything else in this project — the red-flag list, the scan matrix, the hook, every word of install docs — is scaffolding in service of that one moment of visibility. **Fast is not efficient.** That is the whole thesis; the rest is plumbing.

---

## Why not pre-commit / husky / git-guardrails?

Use them all — they're complementary, not competitors.

- **pre-commit, husky, lefthook** run linters and tests. They check the *code*.
- **[git-guardrails](https://github.com/mattpocock/skills/tree/main/git-guardrails-claude-code)** and similar blocklists stop `git push --force`, `git reset --hard`, and other destructive commands. They check for *malice or accidents*.
- **[claude-prove-done](https://github.com/xiaogeli/claude-prove-done)** checks whether the agent confused **memory** with **evidence**, before *"I'm done."* It scans the agent's outgoing prose for completion claims and asks whether any tool call this turn actually touched the claim's subject. Different beat, different moment.
- **claude-think-twice** checks whether the agent confused **fast** with **efficient**. Before your linter runs — before the push even leaves the machine — it asks the agent to look at the inverted account it was about to book. A linter can't ask an agent to read its own ledger; a skill prompt can.

One line: **git-guardrails stops `--force`. prove-done stops `--imagined`. claude-think-twice stops `--rushed`.**

---

## Demo

> **User:** the button color is off, quick fix pls
>
> **Agent:** edits `Button.tsx`, runs `/think-twice`:
>
> ```
> Red-flag self-check:
>   - "quick fix" detected         → guard lowered
>   - CSS-only change assumed       → but a Tailwind class typo
>                                     will not surface until build
>
> Scan matrix for your diff:
>   - Button.tsx  → npm run build (tsc + bundler)
>
> Before git push, confirm:
>   SCANNED: npm run build → OK
> ```
>
> Agent runs `npm run build` → catches an unclosed template literal in an unrelated import → fixes it → confirms → pushes clean.

That round-trip, without the beat, would have been a red CI build and a second round-trip.

---

## Install

### Project-local (recommended for teams)

Commit `.claude/` to your repo so everyone gets the same beat:

```bash
git clone https://github.com/xiaogeli/claude-think-twice.git /tmp/claude-think-twice
mkdir -p .claude/skills .claude/hooks
cp -r /tmp/claude-think-twice/.claude/skills/think-twice .claude/skills/
cp /tmp/claude-think-twice/.claude/hooks/pre-push.sh .claude/hooks/
chmod +x .claude/hooks/pre-push.sh
```

Then merge the `hooks` block from `/tmp/claude-think-twice/.claude/settings.json` into your project's `.claude/settings.json`, and commit `.claude/skills/think-twice/`, `.claude/hooks/pre-push.sh`, and the updated `.claude/settings.json`.

### Personal (all your projects)

Drop the skill and hook under `~/.claude/` instead:

```bash
git clone https://github.com/xiaogeli/claude-think-twice.git /tmp/claude-think-twice
mkdir -p ~/.claude/skills ~/.claude/hooks
cp -r /tmp/claude-think-twice/.claude/skills/think-twice ~/.claude/skills/
cp /tmp/claude-think-twice/.claude/hooks/pre-push.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/pre-push.sh
# Merge the `hooks` block from /tmp/claude-think-twice/.claude/settings.json into ~/.claude/settings.json
```

> **Important — restart Claude Code after install.** The skill will hot-reload when you drop the file in, but the **hook registers only at session start**. Until you restart (or open a fresh window), `git push` will NOT trigger the pre-push beat. To verify both installed correctly: restart → type `/think-twice` (should list the three beats) → ask Claude to run `git push` (should surface the ask dialog with the scan matrix).

---

## How it works

### The skill (`/think-twice`)

Lives at `.claude/skills/think-twice/SKILL.md`. When invoked, it walks the agent through three beats:

1. **Red-flag self-check.** A short list of phrases that signal reactive mode — *"just a one-line fix", "CI will catch it", "ship it so the user can see", "too simple to break"*. Each phrase has a one-line counter. The point is to name the psychology, not the forgotten rule.
2. **Scan matrix lookup.** Based on the file types in the pending diff, the skill prints the minimum pre-push scan. See [the matrix below](#scan-matrix).
3. **Explicit confirmation.** The agent states *"SCANNED: &lt;command&gt; → &lt;result&gt;"* for each required scan before the push.

### The hook (`PreToolUse` on `Bash`)

Lives in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "if": "Bash(git push*)",
        "hooks": [
          { "type": "command", "command": "./.claude/hooks/pre-push.sh" }
        ]
      }
    ]
  }
}
```

The hook fires whenever the agent tries to run `git push *`. It computes the diff against the upstream branch, matches changed files against the scan matrix, and returns an `ask` decision with the matrix as the reason. Claude Code surfaces the prompt to **you, the human** — and that prompt is the actual beat of reflection. You then either allow, deny, or tell the agent to run `/think-twice` first.

The hook does **not** try to parse "did the agent run scans?" from session history — that's unreliable. The enforcement is the human-in-the-loop moment, not a state machine.

### Scan matrix

| Change type                      | Minimum pre-push scan                                |
| -------------------------------- | ---------------------------------------------------- |
| Bash / shell script              | `bash -n <file>`                                     |
| Python                           | `python -m py_compile <file>` + pytest on touched modules |
| TypeScript / TSX                 | `npm run build` (tsc + bundler)                      |
| SQL / migration                  | Grep every INSERT/UPDATE site against the new schema |
| Config field                     | Grep call sites; verify settings definition resolves |
| Public function signature change | Grep every caller; update if needed                  |
| Deleted code                     | Grep for remaining references                        |

The matrix is extensible — see [Contributing](#contributing).

---

## Honest limitations

- **A determined agent can bypass the skill.** The skill is a prompt; prompts guide behavior, they don't enforce it. This is a speed bump against reactive mode, not a fence against malice.
- **The hook cannot verify "scans were run".** Claude Code hooks communicate via exit codes and permission decisions; there is no mechanism to require the agent to emit a specific confirmation string. The `ask` decision forces a human prompt — that's the real enforcement.
- **Not every change type is covered.** The matrix is a starting set, not exhaustive. If your stack is missing, [add a row](#contributing).
- **CI is still your last line of defense.** `claude-think-twice` shifts more defects to pre-push, but it is not a replacement for CI, typechecking, or tests.

---

## Non-goals

- Not a linter, test runner, or typechecker — those exist and are great.
- Not a replacement for `pre-commit` / `husky` — run them both.
- Not guaranteeing safety — see *Honest limitations* above.
- Not Claude-exclusive in spirit — the prompt patterns are portable; the hook is Claude Code-specific.

---

## Porting to other agents

The skill content (`.claude/skills/think-twice/SKILL.md`) is just a markdown prompt. Drop it into:

- **Cursor** as a `.cursorrules` entry or a Command.
- **Aider** as part of the repo's system prompt (`.aider.conf.yml` → `read`).
- **Copilot Chat** as a custom instruction in `.github/copilot-instructions.md`.

The `PreToolUse` hook is Claude Code-only — other agents would need their own equivalent (Cursor doesn't expose a pre-tool hook today). If you build a port, PR the link into this README.

---

## Tests

```bash
tests/run.sh
```

16 cases covering every extension currently in the scan matrix (`*.sh` / `*.py` / `*.ts` / `*.tsx` / `*.js` / `*.jsx` / `*.css` / `*.scss` / `*.sql` / `*.json` / `*.yaml` / `*.yml` / `*.toml`), the unknown-extension fallback, and path-prefix preservation. Exit code is the number of failures, so it drops cleanly into CI.

The harness sources `pre-push.sh` and exercises the `classify_file` function in isolation — git-diff and Claude-Code-payload integration are intentionally out of scope (slow + brittle). Adding a new scan-matrix row should come with a matching test row in [`tests/run.sh`](./tests/run.sh) so future PRs can't silently break the classifier.

---

## Contributing

The most valuable PRs add a row to the scan matrix. Minimum requirements:

1. The change type (e.g. `Rust`, `Go`, `Dockerfile`, `Terraform`).
2. The minimum scan command.
3. One sentence on *why* that scan catches the common reactive-coding failure for that type.
4. A new test row in `tests/run.sh` that locks in the new classification.

Keep additions narrow and specific — a scan that catches 80% of real breakage beats a comprehensive audit nobody runs.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full flow.

---

## License

MIT — see [LICENSE](LICENSE).
