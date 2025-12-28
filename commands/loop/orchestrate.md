---
description: Enter orchestrator mode - delegate implementation to agents
---

# Orchestrate Command

Work on a task as an orchestrator, delegating implementation to the implementor agent.

## Usage

```
/orchestrate <task description>
```

## How It Works

In orchestrator mode, YOU do not write code directly. Instead:
1. You plan and break down the task
2. You delegate implementation to the `implementor` agent via Task tool
3. You review results and iterate
4. You call `reviewer` for code review
5. You handle git operations (commit, etc.)

This saves context - implementation details stay in the implementor's context window.

## Setup

Enter orchestrator mode:
```bash
# Ensure jwz is initialized
[ ! -d .jwz ] && jwz init

# Set orchestrator mode (blocks Write/Edit in PreToolUse hook)
jwz post "mode:current" -m '{"mode": "orchestrator", "task": "$ARGUMENTS"}'
```

## Your Role as Orchestrator

**You DO:**
- Plan the approach
- Delegate via Task tool to `trivial:implementor`
- Review implementor results
- Call `trivial:reviewer` for code review
- Handle git operations (add, commit)
- Make architectural decisions
- Answer implementor's open questions

**You DO NOT:**
- Write code directly (use implementor)
- Edit files directly (use implementor)
- Run build/test commands (implementor does this)

## Delegation Pattern

Call the implementor with a clear spec:
```
Use Task tool with subagent_type: trivial:implementor

Prompt should include:
1. What to implement (specific and concrete)
2. Acceptance criteria (how to know it's done)
3. Relevant context (file paths, patterns to follow)
4. Test expectations (what tests to run)
```

Example:
```
Task: Add email validation to the login endpoint

Files: src/api/auth.py (login function around line 45)

Requirements:
- Validate email format before processing
- Return 400 with clear error message if invalid
- Follow existing error handling pattern in the file

Tests: Run pytest tests/test_auth.py

Acceptance: Tests pass, email validation works
```

## Handling Implementor Results

### status: COMPLETE
- Review the changes: `git diff`
- If satisfied, proceed to code review or commit
- If issues, delegate fixes to implementor

### status: BLOCKED
- Read the blocker details
- Provide guidance or answer open questions
- Re-delegate with additional context

### status: NEED_OPUS
- The task is too complex for Haiku
- Re-delegate with `model: opus` parameter
- Or break into smaller pieces for Haiku

### status: NEED_REVIEW
- Call `trivial:reviewer` agent
- Address any issues via implementor
- Iterate until LGTM

## Workflow

1. **Understand** the task
2. **Plan** the approach (break into steps if needed)
3. **Delegate** first implementation step to implementor
4. **Review** the result
5. **Iterate** if needed (fix issues, handle blockers)
6. **Review** code via reviewer agent
7. **Commit** when ready

## Completion

When the task is complete:
```bash
# Clear orchestrator mode
jwz post "mode:current" -m '{"mode": "direct"}'

# Output completion signal if in a loop
echo "<loop-done>COMPLETE</loop-done>"
```

## Escape Hatch

If you need to make a quick fix directly:
```bash
# Temporarily disable orchestrator mode
jwz post "mode:current" -m '{"mode": "direct"}'

# Make your change
# ...

# Re-enable if continuing orchestration
jwz post "mode:current" -m '{"mode": "orchestrator"}'
```
