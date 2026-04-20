---
name: think-twice
description: Invoke before `git push`. Reactive coding runs on a silent confusion — the agent believes that saving itself one round-trip helps the user. It doesn't. When the skipped scan would have caught something, the agent saves itself 20 seconds and costs the user two hours. The account is inverted. This skill does exactly one thing — makes the agent see the inverted account in the second before push, not after CI catches it. Use whenever a change feels "quick", "small", or "obvious" — those are the moments where the inversion is most tempting and most expensive.
when_to_use: Before any `git push`. Especially when the last user message contained words like "quick", "small", "just", "one-line", or a screenshot with "fix this". If the agent notices any red-flag phrase in its own reasoning, invoke this skill.
---

# /think-twice

## Fast ≠ efficient — read this before you push

You are not lazy. You did not forget. You confused **fast** with **efficient**.

Reactive coding runs on one unspoken belief: *saving myself one round-trip is the same as helping the user.* It isn't. The account runs the other way.

- **What you booked:** skip a 20-second scan → ship one round-trip sooner → user gets the answer faster.
- **What actually happens when the scan would have caught something:** the build breaks → CI screams → someone rolls it back → you debug → you push again → the user has waited two extra hours, gotten frustrated, and lost a little trust in the next thing you ship.

One round-trip saved on your side. Three, four, sometimes more spent on the user's side. **The account is inverted.** Every round-trip you "saved" was bookkept on the wrong ledger.

This skill does exactly one thing: in the second before `git push`, it makes you read the account right-way-up.

Everything that follows — the red-flag list, the scan matrix, the confirmation ritual — is scaffolding. The point is that one moment of visibility. **Fast is not efficient. Look at the numbers before you push, not after CI.**

---

## Beat 1 — Red-flag self-check

Scan your recent reasoning for any of these phrases. If you find one, **you are in reactive mode**. The diff size is not the problem; the lowered guard is.

| If you thought…                          | The counter                                                                 |
| ---------------------------------------- | --------------------------------------------------------------------------- |
| "Just a one-line fix"                    | The smaller the diff, the lower the guard. Most outages are one-line fixes. |
| "CI will catch it"                       | CI is a last line of defense, not insurance. Hitting it costs a round-trip. |
| "Ship it so the user can see"            | A broken build makes the user wait longer, not less.                        |
| "Too simple to break"                    | Simple is a feeling, not a guarantee. Run the scan anyway.                  |
| "I'll batch the scans later"             | Later is never. Run the scan now, while the diff is in your head.           |
| "The last change was similar, it worked" | Similarity is not identity. Different file, different callers, different imports. |

If you found a phrase, you just caught yourself booking a saving on the wrong ledger. Your "one fewer round-trip" is on your account; the potential two-hour wait is on the user's. They do not cancel.

---

## Beat 2 — Scan matrix lookup

This is the specific price of **looking**. Seconds to minutes per scan. The price of *not* looking — when the scan would have caught anything — is measured in hours of user wait plus a visibly broken push. The two prices sit on different accounts. Treating them as comparable *is* the inverted math.

For each file in your pending diff (`git diff --name-only @{upstream}..HEAD` or equivalent), run the minimum scan for its type.

| Change type                      | Minimum pre-push scan                                              |
| -------------------------------- | ------------------------------------------------------------------ |
| Bash / shell script (`*.sh`)     | `bash -n <file>`                                                   |
| Python (`*.py`)                  | `python -m py_compile <file>` + pytest on touched modules          |
| TypeScript / TSX (`*.ts`, `*.tsx`) | `npm run build` (runs tsc + bundler)                             |
| JavaScript / JSX (`*.js`, `*.jsx`) | `npm run build` or project's lint+test command                   |
| SQL / migration                  | Grep every `INSERT`/`UPDATE`/`SELECT` site against the new schema  |
| Config field (JSON/YAML/TOML)    | Grep call sites; verify settings definition resolves at runtime    |
| Public function signature change | Grep every caller; update all of them in this same diff            |
| Deleted code                     | Grep the repo for remaining references to the deleted symbols      |

If your change type is not listed, pick the closest match and state which scan you ran and why. Then open an issue on `claude-think-twice` proposing the new row.

**CSS / styling-only changes** still need `npm run build` in TypeScript projects — a Tailwind class typo or missing import will not surface until build. If your project has no build step (static CSS with Django / Rails / plain HTML), substitute: grep every class name you removed or renamed against the templates that reference it.

---

## Beat 3 — Confirmation ritual

Before running `git push`, emit one line per scan in this exact format:

```
SCANNED: <command> → OK
```

Example:

```
SCANNED: npm run build → OK
SCANNED: python -m py_compile src/utils.py → OK
```

If any scan failed, **fix it first, then re-run the scan, then emit the confirmation.** Do not push with a known-failing scan and a plan to "fix in the next commit". That is reactive mode wearing a different hat.

If you cannot run a scan (missing tooling, offline environment, etc.), state that explicitly and ask the user whether to proceed:

```
SKIPPED: npm run build (reason: no Node toolchain in this sandbox). Proceed?
```

---

## What this skill does not do

- It does not replace your linter, typechecker, test suite, or CI. Run those too.
- It does not guarantee a safe push. It is a speed bump against reactive mode.
- It does not block destructive commands like `git push --force`. Pair with [git-guardrails](https://github.com/mattpocock/skills/tree/main/git-guardrails-claude-code) for that.

The value is the beat itself — the moment between "I see the fix" and `git push`. Take it.
