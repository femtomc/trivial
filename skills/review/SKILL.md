---
name: review
description: Run code review on current changes using the reviewer agent
---

# Review Skill

Get a code review on current changes before completion.

## When to Use

Use this skill when:
- Work is ready to be reviewed
- Before marking an issue complete
- User asks for a code review

## Prerequisites

Must have changes to review:
```bash
git diff --stat
git diff --cached --stat
```

If no changes, report "No changes to review" and stop.

## Workflow

Invoke the reviewer agent:

```
Task(subagent_type="idle:reviewer", prompt="Review the current changes.")
```

The reviewer agent will:
1. Run `git diff` to see changes
2. Look for project style guides in `docs/` or `CONTRIBUTING.md`
3. Collaborate with Codex for a second opinion
4. **Post verdict to jwz** on the issue topic
5. Return verdict: **LGTM** or **CHANGES_REQUESTED**

## jwz Integration

The reviewer posts its verdict to jwz. The stop hook reads from jwz to enforce review requirements.

**Reviewer posts:**
```bash
# On LGTM
jwz post "issue:$ISSUE_ID" -m "[review] LGTM sha:$(git rev-parse HEAD)"

# On changes requested
jwz post "issue:$ISSUE_ID" -m "[review] CHANGES_REQUESTED sha:$(git rev-parse HEAD)"
```

**Stop hook reads** the latest `[review]` message from the issue topic to determine if completion is allowed.

## Review Requirements

Within an issue loop:
1. Code must be reviewed before completing
2. CHANGES_REQUESTED must be addressed with another review
3. After 3 review iterations, create follow-up issues instead

The stop hook enforces these by reading review messages from jwz.
