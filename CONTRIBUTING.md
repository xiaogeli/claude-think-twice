# Contributing to claude-think-twice

Thanks for taking the beat seriously enough to want to extend it.

## The high-value PR: a new scan-matrix row

Most reactive-coding failures are stack-specific. The scan matrix is how this project stays useful across stacks, and adding a row is the single most valuable contribution.

A good row PR has:

1. **The change type.** File extension or concept (e.g. `*.rs`, `Dockerfile`, `terraform/*.tf`, `*.proto`).
2. **The minimum scan command.** One command, fast enough that nobody skips it.
3. **One sentence on the failure it catches.** What specifically goes wrong in reactive mode for this file type? Example: *"A stray `use` in Rust compiles but leaves a dead import; `cargo check` catches it in under a second."*
4. **The edit, in three places.** `.claude/skills/think-twice/SKILL.md` (the human-readable matrix), `.claude/hooks/pre-push.sh` (the `classify_file` function), and `tests/run.sh` (an `assert_contains` row that locks in the classification). Keeping all three in sync is the deal.

Keep the scan narrow. A command that catches 80% of reactive-mode breakage beats a comprehensive audit nobody runs.

## Tests

```bash
tests/run.sh
```

16 cases against `classify_file`. Run before every PR; paste the summary into the PR description. The harness sources `pre-push.sh` directly — `classify_file` is a pure function with no I/O, which is why we can unit-test it without setting up a fake git repo. The full pipeline (stdin parsing, git diff, JSON output) is intentionally not tested here; that integration relies on Claude Code's hook payload format, which is out of our control.

## Other welcome contributions

- Ports of the skill prompt to other agents (Cursor, Aider, Copilot). PR a link into the README's *Porting* section.
- Clearer writing in `SKILL.md` or `README.md`. The tone is deliberately direct — "you chose", not "you forgot". Keep that.
- Red-flag phrases in other languages, if you use Claude Code in a non-English dev workflow.

## What this project will not accept

- Adding a full linter, typechecker, or test runner. Out of scope — the scan matrix delegates to the tools your project already runs.
- Changes that make the skill softer or more hedging. The directness is the point; a skill that apologizes cannot interrupt reactive mode.
- Features that pretend the hook can enforce what it cannot. If it can't verify, the README says so.

## Workflow

1. Open an issue first for anything larger than a scan-matrix row.
2. Fork, branch, PR against `main`.
3. One focused change per PR. A new scan-matrix row is its own PR; a README fix is its own PR.
4. The commit message explains *why*, not just *what*.
