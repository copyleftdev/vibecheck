const std = @import("std");
const toml = @import("toml.zig");
const finding = @import("../core/finding.zig");

pub const Config = struct {
    scan: struct {
        ignore: std.ArrayList([]const u8),
        packs: std.ArrayList([]const u8),
        max_results: usize,
    },
    output: struct {
        format: []const u8,
        fail_on: finding.Severity,
    },

    pub fn init(allocator: std.mem.Allocator) Config {
        const c = Config{
            .scan = .{
                .ignore = std.ArrayList([]const u8).init(allocator),
                .packs = std.ArrayList([]const u8).init(allocator),
                .max_results = 100,
            },
            .output = .{
                .format = "list",
                .fail_on = .critical, // User asked for fail-on logic
            },
        };
        // Defaults
        // c.scan.ignore.append(".git"); // Already handled by walker but good for explicit list
        return c;
    }

    pub fn deinit(self: *Config, allocator: std.mem.Allocator) void {
        for (self.scan.ignore.items) |item| {
            allocator.free(item);
        }
        self.scan.ignore.deinit();
        for (self.scan.packs.items) |item| {
            allocator.free(item);
        }
        self.scan.packs.deinit();
    }
};

pub fn load(allocator: std.mem.Allocator, path: []const u8) !Config {
    var config = Config.init(allocator); // Default config

    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        if (err == error.FileNotFound) return config; // Return defaults
        return err;
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    var parser = toml.TomlParser.init(allocator);
    defer parser.deinit();

    try parser.parse(content);

    // Apply values to Config struct
    if (parser.values.get("scan.max_results")) |val| {
        if (val == .integer) config.scan.max_results = @intCast(val.integer);
    }
    
    if (parser.values.get("output.fail_on")) |val| {
        if (val == .string) {
            if (std.mem.eql(u8, val.string, "info")) config.output.fail_on = .info;
            if (std.mem.eql(u8, val.string, "warn")) config.output.fail_on = .warn;
            if (std.mem.eql(u8, val.string, "error")) config.output.fail_on = .critical;
        }
    }

    if (parser.values.get("scan.ignore")) |val| {
        if (val == .array) {
            for (val.array.items) |item| {
                try config.scan.ignore.append(try allocator.dupe(u8, item));
            }
        }
    }

    if (parser.values.get("scan.packs")) |val| {
        if (val == .array) {
            for (val.array.items) |item| {
                try config.scan.packs.append(try allocator.dupe(u8, item));
            }
        }
    }

    return config;
}
