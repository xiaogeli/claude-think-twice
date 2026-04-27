# claude-think-twice

[English](#english) · [简体中文](#中文)

---

<a id="english"></a>

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

### One-liner (recommended)

Personal scope (all your projects):

```bash
curl -fsSL https://raw.githubusercontent.com/xiaogeli/claude-think-twice/main/install.sh | bash
```

Project scope (commit `.claude/` alongside this repo so the team shares it):

```bash
curl -fsSL https://raw.githubusercontent.com/xiaogeli/claude-think-twice/main/install.sh | bash -s -- --project
```

The installer clones to a temp dir, copies the skill + hook into `~/.claude/` (or `./.claude/` with `--project`), merges the PreToolUse[Bash] hook entry into `settings.json` while preserving any existing hooks, and rewrites the hook command path to absolute (personal) or relative (project) so it resolves correctly. Re-running is idempotent. Source: [`install.sh`](./install.sh).

> **Restart Claude Code afterwards.** The skill hot-reloads, but hooks register only at session start.

### Manual install (if you'd rather see every step)

<details>
<summary>Project-local (recommended for teams)</summary>

Commit `.claude/` to your repo so everyone gets the same beat:

```bash
git clone https://github.com/xiaogeli/claude-think-twice.git /tmp/claude-think-twice
mkdir -p .claude/skills .claude/hooks
cp -r /tmp/claude-think-twice/.claude/skills/think-twice .claude/skills/
cp /tmp/claude-think-twice/.claude/hooks/pre-push.sh .claude/hooks/
chmod +x .claude/hooks/pre-push.sh
```

Then merge the `hooks` block from `/tmp/claude-think-twice/.claude/settings.json` into your project's `.claude/settings.json`, and commit `.claude/skills/think-twice/`, `.claude/hooks/pre-push.sh`, and the updated `.claude/settings.json`.

</details>

<details>
<summary>Personal (all your projects)</summary>

Drop the skill and hook under `~/.claude/` instead:

```bash
git clone https://github.com/xiaogeli/claude-think-twice.git /tmp/claude-think-twice
mkdir -p ~/.claude/skills ~/.claude/hooks
cp -r /tmp/claude-think-twice/.claude/skills/think-twice ~/.claude/skills/
cp /tmp/claude-think-twice/.claude/hooks/pre-push.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/pre-push.sh
# Merge the `hooks` block from /tmp/claude-think-twice/.claude/settings.json into ~/.claude/settings.json
```

</details>

After **any** install method, restart Claude Code so the hook registers. Verify: restart → type `/think-twice` (should list the three beats) → ask Claude to run `git push` (should surface the ask dialog with the scan matrix).

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
        "hooks": [
          { "type": "command", "command": "./.claude/hooks/pre-push.sh" }
        ]
      }
    ]
  }
}
```

The matcher fires on **every** Bash call, and the script itself filters down to `git push*` via `should_handle_command` — exiting silently with code 0 for anything else. Claude Code's hook `matcher` only matches on tool name (e.g. `Bash`), not on tool input content, so the filter has to live in the script. If you ever need to trigger on a different command, edit `should_handle_command` in `.claude/hooks/pre-push.sh`.

When `git push` is detected, the hook computes the diff against the upstream branch, matches changed files against the scan matrix, and returns an `ask` decision with the matrix as the reason. Claude Code surfaces the prompt to **you, the human** — and that prompt is the actual beat of reflection. You then either allow, deny, or tell the agent to run `/think-twice` first.

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

27 cases. 11 cover `should_handle_command` (the command-content filter — fires on `git push*`, stays silent on `ls`, `git status`, `git push-tags`, etc.) and 16 cover `classify_file` (every extension in the scan matrix plus the unknown-extension fallback and path-prefix preservation). Exit code is the number of failures, so it drops cleanly into CI.

The harness sources `pre-push.sh` and exercises the two pure functions in isolation — git-diff and Claude-Code-payload integration are intentionally out of scope (slow + brittle). Adding a new scan-matrix row, or broadening the command trigger, should come with matching test rows in [`tests/run.sh`](./tests/run.sh) so future PRs can't silently break either gate.

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

---

[↑ Back to top](#claude-think-twice) · [English](#english) · [简体中文](#中文)

---

<a id="中文"></a>

> **快 ≠ 高效。**
> *"我看见修法了" 和 `git push` 之间缺的那一拍。*

一个 Claude Code 的 **skill + hook**，让 AI 编码 agent 看见每一次反应式编码瞬间背后的同一个错误：把 *少跑一趟 round-trip* 当成 *帮到了用户*。它不是。被跳过的那次扫描如果本可以抓到问题，agent 就给自己省了 20 秒、给用户花了 2 小时。账算反了。这个项目只做一件事 —— 在 `git push` 前那一秒，让 agent 把账读正过来。

姊妹项目：[`claude-prove-done`](https://github.com/xiaogeli/claude-prove-done) —— 同样的形态，不同的节拍。*think-twice* 在 `git push` 前拦住 `--rushed`；*prove-done* 在 "I'm done" 前拦住 `--imagined`。

---

## 两分钟版的故事

AI 编码 agent 早就知道规则：*push 前先跑扫描。*这条规则就写在它自己的项目记忆里。然而当用户发来一张截图加一句"快速修一下"，agent：

1. 把这次改动标为"小"，警惕松了。
2. 假设 CI 会兜底 —— 把 CI 当保险，而不是最后一道防线。
3. 把**快**和**高效**搞混了 —— 跳过扫描感觉像是更快帮到用户。
4. Build 挂了。Agent "省下"的 20 秒变成用户等的 2 小时，加上一个用户得自己注意到的、坏掉的 push。

账算反了。Agent 在*自己*的账上记了一笔节省（一次 round-trip）；代价记到了*用户*的账上（三四次 round-trip）。这不是同一本账。从反应式模式的内部看，agent 看不见这一点 —— 在反应式模式里，"赶紧发出去"感觉就等于"更帮用户"。

`claude-think-twice` 就是逼 agent 在 `git push` 前、不是 CI 之后，把这本账读正过来的那一拍。

---

## 这到底是什么

不是 linter。Linter 检查代码。**这个工具检查的是 agent 是不是把快和高效搞混了。**

反应式编码不是懒或健忘 —— agent 知道规则。它运行在一个无声的信念上：*我少跑一次 round-trip 就等于帮到用户。*这个信念是错的。被跳过的那次扫描如果本能抓到问题，agent 那"省下的 20 秒"会变成用户的几个小时等待、坏掉的 build、回滚动作、被消耗的信任。Agent 这边省一次 round-trip；用户那边花三次以上。**账算反了。**

Agent 在循环内部看不到这一点 —— 在循环内部，两本账看起来是同一本。`claude-think-twice` 把这笔交易拉到循环外部，停留得够久、能被读正确。

一旦 agent 在自己 pending diff 里看见这个反向 —— *我刚才打算给自己省 20 秒、给用户花 2 小时* —— 它就会自我修正。不是因为 hook 强迫它，而是这道算术不再成立。

这个项目的其他一切 —— 红旗清单、scan matrix、hook、安装文档每一句话 —— 都是为那一刻的可见性服务的脚手架。**快不是高效。**这就是全部论点；其他都是周边。

---

## 为什么不用 pre-commit / husky / git-guardrails？

都用 —— 它们是互补的，不是替代关系。

- **pre-commit、husky、lefthook** 跑 linter 和测试。它们检查*代码*。
- **[git-guardrails](https://github.com/mattpocock/skills/tree/main/git-guardrails-claude-code)** 之类的 blocklist 拦 `git push --force`、`git reset --hard` 等破坏性命令。它们检查的是*恶意或事故*。
- **[claude-prove-done](https://github.com/xiaogeli/claude-prove-done)** 检查 agent 在 *"I'm done"* 前是不是把 **记忆** 和 **证据** 搞混了。它扫 agent 自己的输出散文里的完成声明，问这一轮里有没有工具调用真的碰过声明里的具体对象。不同节拍，不同时刻。
- **claude-think-twice** 检查 agent 是不是把**快**和**高效**搞混了。在你的 linter 跑之前 —— 在 push 还没离开机器之前 —— 让 agent 看一眼自己刚要记的那本反向账。Linter 没法让 agent 读自己的账本，skill 提示可以。

一句话：**git-guardrails 拦 `--force`。prove-done 拦 `--imagined`。claude-think-twice 拦 `--rushed`。**

---

## Demo（中文）

> **用户：** 按钮颜色不对，快速修一下
>
> **Agent：** 编辑 `Button.tsx`，跑 `/think-twice`：
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
> Agent 跑 `npm run build` → 抓到一个无关 import 里没闭合的 template literal → 修了 → 确认 → 干净 push。

那一次 round-trip，没有这一拍的话，会变成一次红的 CI build 加第二次 round-trip。

---

## 安装

### 一行命令（推荐）

个人级（影响你所有项目）：

```bash
curl -fsSL https://raw.githubusercontent.com/xiaogeli/claude-think-twice/main/install.sh | bash
```

项目级（把 `.claude/` 提交进当前仓库给团队共享）：

```bash
curl -fsSL https://raw.githubusercontent.com/xiaogeli/claude-think-twice/main/install.sh | bash -s -- --project
```

安装脚本会 clone 到临时目录、把 skill + hook 文件复制到 `~/.claude/`（或 `--project` 时复制到 `./.claude/`）、把 PreToolUse[Bash] hook 条目 merge 进 `settings.json`（保留你已有的所有 hook，重复的不会重复加），并根据 scope 把 hook 命令路径改写成绝对路径（个人级）或相对路径（项目级）。重复运行是幂等的。源码：[`install.sh`](./install.sh)。

> **装完重启 Claude Code。** Skill 会热加载，hook 只在 session 启动时注册。

### 手动安装（想看每一步的话）

<details>
<summary>项目级（推荐团队使用）</summary>

把 `.claude/` 提交进仓库，团队成员共享同一拍：

```bash
git clone https://github.com/xiaogeli/claude-think-twice.git /tmp/claude-think-twice
mkdir -p .claude/skills .claude/hooks
cp -r /tmp/claude-think-twice/.claude/skills/think-twice .claude/skills/
cp /tmp/claude-think-twice/.claude/hooks/pre-push.sh .claude/hooks/
chmod +x .claude/hooks/pre-push.sh
```

然后把 `/tmp/claude-think-twice/.claude/settings.json` 里的 `hooks` 块 merge 进你项目的 `.claude/settings.json`，再把 `.claude/skills/think-twice/`、`.claude/hooks/pre-push.sh` 以及更新后的 `.claude/settings.json` 一起 commit。

</details>

<details>
<summary>个人级（所有项目）</summary>

把 skill 和 hook 放到 `~/.claude/`：

```bash
git clone https://github.com/xiaogeli/claude-think-twice.git /tmp/claude-think-twice
mkdir -p ~/.claude/skills ~/.claude/hooks
cp -r /tmp/claude-think-twice/.claude/skills/think-twice ~/.claude/skills/
cp /tmp/claude-think-twice/.claude/hooks/pre-push.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/pre-push.sh
# 把 /tmp/claude-think-twice/.claude/settings.json 里的 `hooks` 块 merge 进 ~/.claude/settings.json
```

</details>

不管用哪种方式装，装完都要重启 Claude Code 让 hook 注册。验证：重启 → 输入 `/think-twice`（应该列出三拍）→ 让 Claude 跑 `git push`（应该弹出 ask 对话，里面带 scan matrix）。

---

## 工作原理

### Skill（`/think-twice`）

位于 `.claude/skills/think-twice/SKILL.md`。被调用时，它带 agent 走过三拍：

1. **红旗自检。**一组短语清单，标记反应式模式 —— *"just a one-line fix"、"CI will catch it"、"ship it so the user can see"、"too simple to break"*。每条都有一行反驳。重点是命名背后的心理，不是被忘掉的规则。
2. **Scan matrix 查表。**根据 pending diff 里的文件类型，skill 打出最少的 pre-push 扫描。见 [下面的 matrix](#scan-matrix-1)。
3. **显式确认。**Agent 在 push 前对每个必跑的扫描说 *"SCANNED: <command> → <result>"*。

### Hook（`PreToolUse` on `Bash`）

位于 `.claude/settings.json`：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "./.claude/hooks/pre-push.sh" }
        ]
      }
    ]
  }
}
```

Matcher 在**每次** Bash 调用时触发，脚本本身用 `should_handle_command` 过滤到 `git push*` —— 其他命令直接 exit 0 静默放行。Claude Code 的 hook `matcher` 只匹配 tool name（比如 `Bash`），不匹配 tool input 内容，所以过滤逻辑只能放在脚本里。如果你想用别的命令触发，改 `.claude/hooks/pre-push.sh` 里的 `should_handle_command`。

检测到 `git push` 时，hook 计算与 upstream 分支的 diff，把改动文件对到 scan matrix 上，返回一个 `ask` 决定，把 matrix 作为理由。Claude Code 把 prompt 显示给**你这个人** —— 那个 prompt 才是真正的反思那一拍。然后你决定：放行、拒绝、或者让 agent 先跑 `/think-twice`。

Hook **不**尝试从 session history 里解析"agent 跑没跑扫描"—— 那不可靠。强制力来自人的那一刻，不是状态机。

### Scan matrix

| 改动类型                          | 最少的 pre-push 扫描                                  |
| --------------------------------- | ----------------------------------------------------- |
| Bash / shell 脚本                 | `bash -n <file>`                                      |
| Python                            | `python -m py_compile <file>` + pytest 跑相关模块     |
| TypeScript / TSX                  | `npm run build`（tsc + bundler）                      |
| SQL / migration                   | Grep 每个 INSERT/UPDATE 站点对照新 schema             |
| 配置字段                          | Grep 调用点；验证 settings 定义能解析                 |
| 公开函数签名变更                  | Grep 每个 caller；按需更新                            |
| 删掉的代码                        | Grep 残留引用                                         |

Matrix 可扩展 —— 见 [Contributing](#contributing-1)。

---

## 诚实交代局限

- **决心绕过 skill 的 agent 绕得过去。** Skill 是 prompt；prompt 引导行为、不强制。这是反应式模式的减速带，不是反恶意的栅栏。
- **Hook 没法核实"扫描跑过了"。** Claude Code hook 通过 exit code 和 permission decision 通信；没有机制能要求 agent 输出某个特定确认字符串。`ask` 决定强制弹一个人工 prompt —— 这才是真正的强制力。
- **不是每种改动都覆盖。** Matrix 是起点不是穷举。你的技术栈缺一行，[加一行](#contributing-1)。
- **CI 仍然是最后一道防线。** `claude-think-twice` 把更多缺陷推到 pre-push，但它不是 CI、类型检查、测试的替代。

---

## Non-goals

- 不是 linter、test runner、类型检查器 —— 那些已经存在且很好用。
- 不是 `pre-commit` / `husky` 的替代 —— 两个一起跑。
- 不保证安全 —— 见上面*诚实交代局限*。
- 在精神上不是 Claude 独占 —— prompt 模式可移植；hook 部分是 Claude Code 特有。

---

## 移植到其他 agent

Skill 内容（`.claude/skills/think-twice/SKILL.md`）就是一段 markdown prompt。可以丢到：

- **Cursor** 作为一条 `.cursorrules` 条目或 Command。
- **Aider** 作为仓库 system prompt 的一部分（`.aider.conf.yml` → `read`）。
- **Copilot Chat** 作为 `.github/copilot-instructions.md` 里的自定义指令。

`PreToolUse` hook 是 Claude Code 独有 —— 别的 agent 需要自己的等价机制（Cursor 目前不暴露 pre-tool hook）。如果你做了移植，PR 个链接到本 README。

---

## 测试

```bash
tests/run.sh
```

27 个 case。11 个覆盖 `should_handle_command`（命令内容过滤 —— `git push*` 触发，`ls`、`git status`、`git push-tags` 等静默），16 个覆盖 `classify_file`（scan matrix 里每个扩展名 + 未知扩展名回退 + 路径前缀保留）。退出码等于失败数，可以直接接 CI。

Harness 通过 `source pre-push.sh` 把两个纯函数拉出来单独跑 —— git-diff 和 Claude Code payload 集成测试故意不在范围内（慢且脆）。新增 scan-matrix 行或扩大命令触发面，应该附带 [`tests/run.sh`](./tests/run.sh) 里的对应测试行，这样未来 PR 不能静悄悄破坏任一道闸。

---

## Contributing

价值最高的 PR 是给 scan matrix 加一行。最低要求：

1. 改动类型（比如 `Rust`、`Go`、`Dockerfile`、`Terraform`）。
2. 最小的扫描命令。
3. 一句话说明*为什么*这个扫描能抓到该类型的常见反应式编码失败。
4. `tests/run.sh` 里加一行新测试锁定新分类。

加东西保持窄而具体 —— 一个能抓 80% 真实问题的扫描，胜过一个全面但没人愿意跑的审计。

完整流程见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## License

MIT —— 见 [LICENSE](LICENSE)。

---

[↑ 回到顶部](#claude-think-twice) · [English](#english) · [简体中文](#中文)
