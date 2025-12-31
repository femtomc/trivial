const std = @import("std");
const tissue = @import("tissue");
const idle = @import("idle");
const extractJsonString = idle.event_parser.extractString;

/// SubagentStop hook - quality gate for subagents (Task tool)
/// Same logic as Stop: invoke alice, check issues
pub fn run(allocator: std.mem.Allocator) !u8 {
    // Read hook input from stdin
    const stdin = std.fs.File.stdin();
    var buf: [65536]u8 = undefined;
    const n = try stdin.readAll(&buf);
    const input_json = buf[0..n];

    // Extract cwd and change to project directory
    const cwd = extractJsonString(input_json, "\"cwd\"") orelse ".";
    std.posix.chdir(cwd) catch {};

    // Count issues BEFORE alice review
    const issues_before = countOpenAliceReviewIssues(allocator);

    // Invoke alice for review
    invokeAlice(allocator);

    // Count issues AFTER alice review
    const issues_after = countOpenAliceReviewIssues(allocator);

    // If alice created new issues, block
    if (issues_after > issues_before) {
        return blockWithReason(
            \\[NEEDS_WORK] Alice created {} new issue(s) during review.
            \\
            \\Fix all alice-review issues before exit is allowed.
            \\Run `tissue list -t alice-review` to see them.
        , .{issues_after - issues_before});
    }

    // If there are still open issues, block
    if (issues_after > 0) {
        return blockWithReason(
            \\[ISSUES REMAIN] {} open alice-review issue(s) exist.
            \\
            \\Fix all issues, then exit will be allowed.
            \\Run `tissue list -t alice-review` to see them.
        , .{issues_after});
    }

    // No issues - alice approved
    return 0;
}

fn invokeAlice(allocator: std.mem.Allocator) void {
    const alice_prompt =
        \\You are alice, an adversarial reviewer. Review the work done by this subagent.
        \\
        \\Your job: find problems. Assume there are bugs until proven otherwise.
        \\
        \\For each problem found, create a tissue issue:
        \\  tissue new "<problem description>" -t alice-review -p <1-3>
        \\
        \\Priority: 1=critical, 2=important, 3=minor
        \\
        \\If you find no problems, create no issues.
    ;

    var child = std.process.Child.init(&.{ "claude", "-p", alice_prompt }, allocator);
    _ = child.spawnAndWait() catch return;
}

fn blockWithReason(comptime fmt: []const u8, args: anytype) u8 {
    var reason_buf: [4096]u8 = undefined;
    const reason = std.fmt.bufPrint(&reason_buf, fmt, args) catch return 2;

    var stdout_buf: [8192]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;

    stdout.writeAll("{\"decision\":\"block\",\"reason\":\"") catch return 2;
    escapeJsonTo(stdout, reason) catch return 2;
    stdout.writeAll("\"}\n") catch return 2;
    stdout.flush() catch return 2;

    return 2;
}

fn escapeJsonTo(writer: anytype, data: []const u8) !void {
    for (data) |c| {
        switch (c) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            else => {
                if (c < 0x20) {
                    try writer.print("\\u{x:0>4}", .{c});
                } else {
                    try writer.writeByte(c);
                }
            },
        }
    }
}

fn countOpenAliceReviewIssues(allocator: std.mem.Allocator) u32 {
    const store_dir = tissue.store.discoverStoreDir(allocator) catch return 0;
    defer allocator.free(store_dir);

    var store = tissue.store.Store.open(allocator, store_dir) catch return 0;
    defer store.deinit();

    return store.countOpenIssuesByTag("alice-review") catch 0;
}
