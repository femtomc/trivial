const std = @import("std");

/// Unescape JSON string escape sequences
/// Converts \n, \r, \t, \\, \", etc. to their actual characters
fn unescapeJson(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    // Output can only be same size or smaller
    var result = try allocator.alloc(u8, input.len);
    var out_pos: usize = 0;
    var i: usize = 0;

    while (i < input.len) {
        if (input[i] == '\\' and i + 1 < input.len) {
            const next = input[i + 1];
            switch (next) {
                'n' => {
                    result[out_pos] = '\n';
                    out_pos += 1;
                    i += 2;
                },
                'r' => {
                    result[out_pos] = '\r';
                    out_pos += 1;
                    i += 2;
                },
                't' => {
                    result[out_pos] = '\t';
                    out_pos += 1;
                    i += 2;
                },
                '\\' => {
                    result[out_pos] = '\\';
                    out_pos += 1;
                    i += 2;
                },
                '"' => {
                    result[out_pos] = '"';
                    out_pos += 1;
                    i += 2;
                },
                '/' => {
                    result[out_pos] = '/';
                    out_pos += 1;
                    i += 2;
                },
                'u' => {
                    // Unicode escape \uXXXX - for now just skip it (4 hex digits)
                    if (i + 5 < input.len) {
                        // Simple handling: replace with '?' for non-ASCII
                        result[out_pos] = '?';
                        out_pos += 1;
                        i += 6;
                    } else {
                        result[out_pos] = input[i];
                        out_pos += 1;
                        i += 1;
                    }
                },
                else => {
                    // Unknown escape, keep as-is
                    result[out_pos] = input[i];
                    out_pos += 1;
                    i += 1;
                },
            }
        } else {
            result[out_pos] = input[i];
            out_pos += 1;
            i += 1;
        }
    }

    // Resize to actual length
    return allocator.realloc(result, out_pos) catch result[0..out_pos];
}

/// Extract the last assistant message text from a Claude transcript (NDJSON format)
pub fn extractLastAssistantText(allocator: std.mem.Allocator, transcript_path: []const u8) !?[]u8 {
    const file = std.fs.openFileAbsolute(transcript_path, .{}) catch |err| {
        if (err == error.FileNotFound) return null;
        return err;
    };
    defer file.close();

    const stat = try file.stat();
    if (stat.size == 0) return null;

    // Read last 64KB (should contain last message)
    const read_size: usize = @min(stat.size, 65536);
    const offset: u64 = stat.size - read_size;

    try file.seekTo(offset);

    var buf: [65536]u8 = undefined;
    const n = try file.readAll(&buf);
    if (n == 0) return null;

    const content = buf[0..n];

    // Find last assistant message by scanning for "type":"assistant"
    // Then extract the text content from it
    var last_text_start: ?usize = null;
    var last_text_end: usize = 0;
    var search_pos: usize = 0;

    while (std.mem.indexOf(u8, content[search_pos..], "\"type\":\"assistant\"")) |pos| {
        const abs_pos = search_pos + pos;

        // Look for text content after this
        if (std.mem.indexOf(u8, content[abs_pos..], "\"text\":\"")) |text_pos| {
            const text_start = abs_pos + text_pos + 8; // Skip past "text":"

            // Find end of text string (handle escapes)
            var text_end = text_start;
            var escape_next = false;
            while (text_end < content.len) {
                if (escape_next) {
                    escape_next = false;
                } else if (content[text_end] == '\\') {
                    escape_next = true;
                } else if (content[text_end] == '"') {
                    break;
                }
                text_end += 1;
            }

            last_text_start = text_start;
            last_text_end = text_end;
        }
        search_pos = abs_pos + 1;
    }

    // Return a copy of the last text we found, with JSON escapes decoded
    if (last_text_start) |start| {
        const raw_text = content[start..last_text_end];
        return try unescapeJson(allocator, raw_text);
    }

    return null;
}

// ============================================================================
// Tests
// ============================================================================

test "unescapeJson: basic escapes" {
    const allocator = std.testing.allocator;
    const input = "Hello\\nWorld\\ttab\\\\slash\\\"quote";
    const result = try unescapeJson(allocator, input);
    defer allocator.free(result);
    try std.testing.expectEqualStrings("Hello\nWorld\ttab\\slash\"quote", result);
}

test "unescapeJson: loop-done tag" {
    const allocator = std.testing.allocator;
    const input = "<loop-done>COMPLETE</loop-done>";
    const result = try unescapeJson(allocator, input);
    defer allocator.free(result);
    try std.testing.expectEqualStrings("<loop-done>COMPLETE</loop-done>", result);
}
