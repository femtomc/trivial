# Test Command

Run the test suite and summarize results.

## Steps

1. Detect the project type and run the appropriate test command:
   - If `zig.build.zon` or `build.zig` exists: `zig build test`
   - If `Cargo.toml` exists: `cargo test`
   - If `package.json` exists: `npm test`
   - If `go.mod` exists: `go test ./...`
   - If `pyproject.toml` exists: `pytest` or `python -m pytest`
   - If `Makefile` exists with test target: `make test`
   - Otherwise: Ask user for test command

2. Capture and summarize the results:
   - If all tests pass: Report success with test count if available
   - If tests fail: List failing tests with file:line references

3. If failures exist, offer to investigate the root cause
