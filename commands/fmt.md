# Format Command

Format source code and show what changed.

## Steps

1. Detect the project type and run the appropriate formatter:
   - If `zig.build.zon` or `build.zig` exists: `zig fmt src/`
   - If `Cargo.toml` exists: `cargo fmt`
   - If `package.json` exists: `npm run format` or `npx prettier --write .`
   - If `go.mod` exists: `go fmt ./...`
   - If `pyproject.toml` or `setup.py` exists: `ruff format .` or `black .`
   - Otherwise: Ask user for format command

2. Run `git diff --stat` to show what files were modified

3. If files were changed, briefly list them

4. If no changes, report "Already formatted"
