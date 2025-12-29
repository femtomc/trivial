---
name: fmt
description: Auto-detect and run the project formatter to fix code style
---

# Format Skill

Format source code using the project's configured formatter.

## When to Use

Use this skill when:
- Before committing changes
- Code style issues are detected
- User asks to format code

## Workflow

1. **Detect formatter** by checking project files:
   - `Makefile` → `format` or `fmt` target
   - `package.json` → `format`, `fmt`, or `lint:fix` script
   - `build.zig` or `build.zig.zon` → `zig fmt src/`
   - `Cargo.toml` → `cargo fmt`
   - `go.mod` → `go fmt ./...`
   - `pyproject.toml` → `ruff format .` or `black .`
   - If unclear, ask the user

2. **Run the formatter**

3. **Show changes**:
   ```bash
   git diff --stat
   ```

4. **Report results**:
   - If files changed: list them
   - If no changes: "Already formatted"
