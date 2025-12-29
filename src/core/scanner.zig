const std = @import("std");
const walker = @import("walker.zig");
const matcher = @import("matcher.zig");
const finding = @import("finding.zig");

pub const Scanner = struct {
    allocator: std.mem.Allocator,
    matcher_engine: matcher.Matcher,
    findings: std.ArrayList(finding.Finding),

    pub fn init(allocator: std.mem.Allocator) Scanner {
        return Scanner{
            .allocator = allocator,
            .matcher_engine = matcher.Matcher.init(allocator),
            .findings = std.ArrayList(finding.Finding).init(allocator),
        };
    }

    pub fn deinit(self: *Scanner) void {
        self.matcher_engine.deinit();
        for (self.findings.items) |f| {
            self.allocator.free(f.location.path);
            if (f.location.snippet) |s| self.allocator.free(s);
        }
        self.findings.deinit();
    }



    pub fn scan(self: *Scanner, root_path: []const u8, ignores: []const []const u8) !void {
        var w = try walker.Walker.init(self.allocator, root_path, ignores);
        defer w.deinit();

        const max_size = 1 * 1024 * 1024; // 1MB limit for now

        while (try w.next()) |entry| {
            // Open file
            const file = w.dir.openFile(entry.path, .{}) catch |err| {
                // If we can't open matched file (e.g. symlink issue), skip
                std.debug.print("Skipping {s}: {}\n", .{entry.path, err});
                continue;
            };
            defer file.close();

            const stat = file.stat() catch continue;
            if (stat.kind != .file) continue;
            if (stat.size > max_size) continue;

            const content = file.readToEndAlloc(self.allocator, max_size) catch continue;
            defer self.allocator.free(content);

            try self.matcher_engine.scanFile(entry.path, content, &self.findings);
        }
    }
};
