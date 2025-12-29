const std = @import("std");
const finding = @import("finding.zig");

pub const MatchType = enum {
    keyword,
    regex, // Placeholder for future
};

pub const Pattern = struct {
    id: []const u8,
    name: []const u8,
    severity: finding.Severity,
    match_type: MatchType,
    query: []const u8,
    extensions: ?[]const []const u8 = null,
};

pub const Matcher = struct {
    allocator: std.mem.Allocator,
    patterns: std.ArrayList(Pattern),

    pub fn init(allocator: std.mem.Allocator) Matcher {
        return Matcher{
            .allocator = allocator,
            .patterns = std.ArrayList(Pattern).init(allocator),
        };
    }

    pub fn deinit(self: *Matcher) void {
        self.patterns.deinit();
    }

    pub fn addPattern(self: *Matcher, pattern: Pattern) !void {
        try self.patterns.append(pattern);
    }

    pub fn scanFile(self: *Matcher, path: []const u8, content: []const u8, findings: *std.ArrayList(finding.Finding)) !void {
        var line_it = std.mem.splitScalar(u8, content, '\n');
        var line_num: usize = 1;

        while (line_it.next()) |line| : (line_num += 1) {
            for (self.patterns.items) |pattern| {
                if (pattern.extensions) |exts| {
                    if (!checkExtension(path, exts)) continue;
                }

                if (pattern.match_type == .keyword) {
                    if (std.mem.indexOf(u8, line, pattern.query)) |col| {
                        // Found a match!
                        try findings.append(finding.Finding{
                            .pattern_id = pattern.id,
                            .message = pattern.name,
                            .severity = pattern.severity,
                            .location = finding.Location{
                                .path = try self.allocator.dupe(u8, path),
                                .line = line_num,
                                .column = col + 1,
                                .snippet = try self.allocator.dupe(u8, std.mem.trim(u8, line, " \t\r")),
                            },
                        });
                    }
                }
            }
        }
    }

    fn checkExtension(path: []const u8, exts: []const []const u8) bool {
        const file_ext = std.fs.path.extension(path);
        for (exts) |ext| {
            if (std.mem.eql(u8, file_ext, ext)) return true;
        }
        return false;
    }
};
