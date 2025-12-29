# idle

**An opinionated outer harness for Claude Code.** Long-running loops, multi-model consensus, memory notes via local issue tracker and mail for agents.

`idle` is a (very) opinionated plugin for Claude Code (CC) that overloads several of CC's native points of extension (subagents, hooks, etc) so that one may usefully use
CC for long running, open ended tasks.

Note: `idle` will likely break other plugins that you may be using with Claude Code (especially if they define their own hooks). It's kind of a "batteries included" plugin.

## Why?

I dream of freeing myself from careful and methodical curation of my Claude Code sessions. Much of my time spent manually moving context around, manually saving context, manually directing Claude to do tasks.

This plugin bundles together an issue tracker, a message passing tool, and several specialized subagents, along with overloading CC's hooks to allow you to kind of just let Claude drive itself for a very long time. Now, there's still a bunch of issues doing this today (like: it can still totally go off the rails, and you have to be precise). To combat some of these problems, another thing this plugin does is provide subagent hook overloads to force some of the specialized subagents to shell out to Codex / Gemini for second opinions. This, it turns out, seems to be very useful -- at least, it seems to nullify some of the "self bias" issues you might get if you have Claude review Claude.

Overall:
- **Outer harness:** Provides a structured runtime that controls agent execution, manages worktrees, and handles state persistence across sessions.
- **Loop:** Enables agents to break out of single-turn interactions to perform continuous iterative work.
- **Consensus:** Mitigates LLM self-bias and hallucinations by requiring agreement between distinct models (or fresh contexts) before committing to critical paths.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/evil-mind-evil-sword/idle/main/install.sh | sh
```

Then in Claude Code:
```
/plugin marketplace add evil-mind-evil-sword/marketplace
/plugin install idle@emes
```

## Agents

| Agent | Model | Second Opinion | Description |
|-------|-------|----------------|-------------|
| `explorer` | haiku | — | Local codebase search and exploration |
| `librarian` | haiku | — | Remote code research (GitHub, docs, APIs) |
| `oracle` | opus | codex or claude | Deep reasoning with external dialogue |
| `documenter` | opus | gemini or claude | Technical writing with external writer |
| `reviewer` | opus | codex or claude | Code review with external dialogue |

### How it works

idle acts as an "outer harness" for Claude Code that orchestrates specialized agents within a continuous loop. Fast agents handle information retrieval, while reasoning agents drive the core logic. To prevent error propagation, the harness enforces a consensus mechanism for high-stakes decisions.

When the primary agent proposes a critical action, the harness pauses execution to consult a secondary model. If an external model (Codex, Gemini) is available, it provides an independent perspective. If not, the harness falls back to `claude -p`, creating a fresh context to break the self-refinement loop.

### Why Consensus?

- **Self-Bias:** Single models tend to validate their own errors when asked to double-check. Consensus forces an external review to break this validation loop.
- **Correlated Failures:** Distinct model architectures have different blind spots. Consensus between Claude, Codex, and Gemini catches edge cases that a single model family might miss.
- **Efficiency:** The harness routes simple tasks to faster models and reserves the expensive consensus process for complex reasoning steps, optimizing the loop for both speed and accuracy.

See [docs/architecture.md](docs/architecture.md) for details.

## Commands

### Dev Commands

These capabilities are auto-discovered by Claude based on context:

| Skill | Description |
|-------|-------------|
| `fmt` | Auto-detect and run project formatter |
| `test` | Auto-detect and run project tests |
| `review` | Run code review via reviewer agent |
| `document` | Write technical docs via documenter agent |
| `commit` | Commit staged changes with generated message |
| `message` | Post/read jwz messages for agent coordination |

### Loop Commands

| Command | Description |
|---------|-------------|
| `/loop [task]` | Universal iteration loop. With args: iterate on task. Without args: work through issue tracker (auto-lands, picks next) |
| `/cancel` | Cancel the active loop |

## Worktrees

idle uses git worktrees to enable parallel work. Each issue gets its own isolated environment:

- **Isolation:** Changes happen in `.worktrees/idle/<issue-id>/`
- **Parallelism:** You can have multiple agents working on different issues simultaneously
- **Workflow:**
    1. `/loop` (without args) picks an issue and creates a worktree
    2. Agent works in that directory
    3. On completion, auto-lands (merges to main, cleans up worktree)
    4. Loop automatically picks next issue

## Requirements

### Required

- [tissue](https://github.com/femtomc/tissue) - Issue tracker (for `/loop` issue mode)
- [zawinski](https://github.com/femtomc/zawinski) - Async messaging (for agent communication)
- [uv](https://github.com/astral-sh/uv) - Python package runner (for `scripts/search.py`)
- [gh](https://cli.github.com/) - GitHub CLI (for librarian agent)

### Optional (for enhanced multi-model diversity)

- [codex](https://github.com/openai/codex) - OpenAI coding agent → used by oracle/reviewer
- [gemini-cli](https://github.com/google-gemini/gemini-cli) - Google Gemini CLI → used by documenter

When these are not installed, agents fall back to `claude -p` for second opinions.

## Quickstart

A typical workflow with idle:

```shell
# Work through your issue backlog (picks issues, auto-lands, repeats)
/loop

# Or iterate on a specific task
/loop Add input validation to all API endpoints
```

## Examples

### Work through your backlog

```shell
# Create some issues
tissue new "Add user authentication" -p 1 -t feature
tissue new "Fix login redirect bug" -p 1 -t bug
tissue new "Refactor database queries" -p 2 -t tech-debt

# Work through issues automatically
/loop
# → Picks first ready issue, creates worktree
# → Works on it, runs review, auto-lands on completion
# → Picks next issue, repeats until backlog empty
```

### Iterate on a specific task

```shell
# Use /loop for ad-hoc iterative tasks
/loop Add input validation to all API endpoints

# Claude will:
# - Find API endpoints
# - Add validation incrementally
# - Run tests after changes
# - Continue until done or stuck
```

### Call agents directly

```shell
# Explore the local codebase (fast, uses haiku)
"How does the authentication flow work?"
# → explorer agent searches and explains

# Research external code (fast, uses haiku)
"How does React Query handle cache invalidation?"
# → librarian agent fetches docs and explains

# Deep reasoning on hard problems (thorough, uses opus + second opinion)
"I'm stuck on this race condition, help me debug it"
# → oracle agent analyzes with external dialogue, provides recommendation
```

## Observability

Monitor your agent loops:

- `idle status` - Show human-readable status of the current loop
- `idle status --json` - Machine-readable output for tooling

## Roadmap

- **Phase 1 (Current):** Bash scripts + Claude Plugin architecture.
- **Phase 2:** Rewrite core logic in Zig for performance and reliability.
- **Phase 3:** Terminal User Interface (TUI) for interactive loop management.

## Troubleshooting

### tissue: command not found

Install the tissue issue tracker:

```shell
cargo install --git https://github.com/femtomc/tissue tissue
```

Required for: `/loop` (issue mode)

### jwz: command not found

Install the jwz messaging CLI:

```shell
cargo install --git https://github.com/femtomc/zawinski jwz
```

Required for: agent-to-agent messaging. Initialize with `jwz init`.

### codex: command not found

**This is optional.** Agents will use `claude -p` for second opinions instead.

To enable OpenAI diversity:
```shell
npm install -g @openai/codex
```

### gemini: command not found

**This is optional.** The documenter will use `claude -p` for writing instead.

To enable Gemini diversity:
```shell
npm install -g @google/gemini-cli
```

### Agent not responding or errors

1. Check that required tools are installed: `which tissue`, `which jwz`, `which uv`, `which gh`
2. If using codex/gemini, verify API credentials (Codex needs `OPENAI_API_KEY`, Gemini needs Google auth)
3. Try running the tool directly to see its error output

### No issues found

If `/loop` (without args) reports no issues:

1. Ensure you're in a directory with a `.tissue` folder
2. Run `tissue list` to see available issues
3. Run `tissue ready` to see issues ready to work (no blockers)
4. Run `tissue init` to create a new issue tracker

### Zombie loops

State exists in jwz but Claude is not running.

**Symptoms:** `idle status` shows an active loop but no Claude process is running.

**Fix:**
```shell
IDLE_LOOP_DISABLE=1 claude  # Bypass loop hook
```

Or reset all state:
```shell
rm -rf .jwz/
```

### Worktree conflicts

Case-insensitive filesystem collisions on macOS/Windows.

**Symptoms:** Issue IDs `ABC` and `abc` create conflicting worktrees. Or orphaned worktrees (directory deleted but git still tracks it).

**Fix:**
```shell
git worktree prune      # Clean up orphaned worktrees
git worktree list       # Check current worktrees
```

## License

MIT
