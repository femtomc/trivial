---
name: test
description: Auto-detect and run the project test suite
---

# Test Skill

Run the project's test suite and summarize results.

## When to Use

Use this skill when:
- After making code changes
- Before committing
- To verify a fix works
- User asks to run tests

## Workflow

1. **Detect test runner** by checking project files:
   - `Makefile` → `test` target
   - `package.json` → `test` script
   - `build.zig` or `build.zig.zon` → `zig build test`
   - `Cargo.toml` → `cargo test`
   - `go.mod` → `go test ./...`
   - `pyproject.toml` → `pytest`
   - If unclear, ask the user

2. **Run tests** and capture output

3. **Summarize results**:
   - **Pass**: Report success with test count if available
   - **Fail**: List failing tests with file:line references

4. **On failure**: Offer to investigate the root cause
