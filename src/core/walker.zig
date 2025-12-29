const std = @import("std");

pub const Walker = struct {
    allocator: std.mem.Allocator,
    dir: std.fs.Dir,
    walker: std.fs.Dir.Walker,
    ignores: []const []const u8,

    pub fn init(allocator: std.mem.Allocator, path: []const u8, ignores: []const []const u8) !Walker {
        var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
        const walker = try dir.walk(allocator);
        return Walker{
            .allocator = allocator,
            .dir = dir,
            .walker = walker,
            .ignores = ignores,
        };
    }

    pub fn deinit(self: *Walker) void {
        self.walker.deinit();
        self.dir.close();
    }

    pub fn next(self: *Walker) !?std.fs.Dir.Walker.Entry {
        while (try self.walker.next()) |entry| {
            if (entry.kind != .file) continue;
            if (self.shouldIgnore(entry.path)) continue;
            return entry;
        }
        return null;
    }

    fn shouldIgnore(self: *Walker, path: []const u8) bool {
         // Check hardcoded defaults
        if (std.mem.startsWith(u8, path, ".git/")) return true;
        if (std.mem.indexOf(u8, path, "/.git/") != null) return true;
        if (std.mem.startsWith(u8, path, "zig-out/")) return true;
        if (std.mem.startsWith(u8, path, ".zig-out/")) return true;
        if (std.mem.startsWith(u8, path, "zig-cache/")) return true;
        if (std.mem.startsWith(u8, path, ".zig-cache/")) return true;
        if (std.mem.indexOf(u8, path, "/node_modules/") != null) return true;
        if (std.mem.startsWith(u8, path, "node_modules/")) return true;

        // Check configured ignores
        for (self.ignores) |ignore_pattern| {
             // Simple prefix/contains match for MVP
             if (std.mem.indexOf(u8, path, ignore_pattern) != null) return true;
        }
        return false;
    }
};
