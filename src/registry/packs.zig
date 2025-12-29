const std = @import("std");
const finding = @import("../core/finding.zig");

pub const PatternConfig = struct {
    id: []const u8,
    name: []const u8,
    severity: []const u8, // "info", "warn", "error" - mapped later
    match_type: []const u8, // "keyword", "regex"
    query: []const u8,
    extensions: ?[][]const u8 = null, // JSON arrays of strings
};

pub const Pack = struct {
    name: []const u8,
    version: []const u8,
    patterns: []const PatternConfig,
};



pub const PackLoader = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) PackLoader {
        return PackLoader{ .allocator = allocator };
    }

    pub fn loadFromFile(self: *PackLoader, path: []const u8) !std.json.Parsed(Pack) {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const content = try file.readToEndAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(content);

        return self.loadFromContent(content);
    }

    pub fn loadFromContent(self: *PackLoader, content: []const u8) !std.json.Parsed(Pack) {
        return std.json.parseFromSlice(Pack, self.allocator, content, .{ .allocate = .alloc_always, .ignore_unknown_fields = true });
    }
};

const matcher = @import("../core/matcher.zig");
const finding_mod = @import("../core/finding.zig");

pub fn toMatcherPattern(config: PatternConfig) matcher.Pattern {
    const sev = if (std.mem.eql(u8, config.severity, "error") or std.mem.eql(u8, config.severity, "critical")) finding_mod.Severity.critical
           else if (std.mem.eql(u8, config.severity, "warn")) finding_mod.Severity.warn
           else finding_mod.Severity.info;
    
    return matcher.Pattern{
        .id = config.id,
        .name = config.name,
        .severity = sev,
        .match_type = .keyword, // Note: Regex support planned for future milestone
        .query = config.query,
        .extensions = null, // Note: Extension filtering planned for future milestone
    };
}
