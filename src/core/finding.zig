const std = @import("std");

pub const Severity = enum {
    info,
    warn,
    critical,
};

pub const Location = struct {
    path: []const u8,
    line: usize,
    column: ?usize = null,
    snippet: ?[]const u8 = null,
};

pub const Finding = struct {
    pattern_id: []const u8,
    message: []const u8,
    severity: Severity,
    location: Location,
};
