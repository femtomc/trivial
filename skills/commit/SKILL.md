---
name: commit
description: Stage and commit changes with a descriptive conventional commit message
---

# Commit Skill

Commit current changes with a properly formatted conventional commit message.

## When to Use

Use this skill when:
- Changes are ready to be committed
- You've finished a logical unit of work
- Tests pass and code is formatted

## Workflow

1. **Check for changes**:
   ```bash
   git status --short
   ```
   If no changes, report "Nothing to commit" and stop.

2. **Check staged changes**:
   ```bash
   git diff --cached --stat
   ```

3. **If nothing staged**, stage all changes:
   ```bash
   git add -A
   ```

4. **Generate commit message**:
   - Analyze `git diff --cached`
   - Determine type: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
   - Write concise description (1-2 sentences)

5. **Commit**:
   ```bash
   git commit -m "type: description"
   ```

6. **Report** the commit hash and summary

## Commit Types

| Type | Purpose |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring (no behavior change) |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `chore` | Build, tooling, dependencies |

## Output Format

```
## Result

**Status**: COMMITTED | NO_CHANGES | FAILED
**Commit**: abc1234
**Summary**: type: description

## Files Changed
- path/to/file.ext (+10, -5)
```
