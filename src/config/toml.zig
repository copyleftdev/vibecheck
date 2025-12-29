const std = @import("std");

pub const TomlValue = union(enum) {
    string: []const u8,
    boolean: bool,
    integer: i64,
    array: std.ArrayList([]const u8), // Only string arrays for now (globs etc)

    pub fn deinit(self: *TomlValue, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .array => |*arr| {
                for (arr.items) |item| allocator.free(item);
                arr.deinit();
            },
            .string => |s| allocator.free(s),
            else => {},
        }
    }
};

pub const TomlParser = struct {
    allocator: std.mem.Allocator,
    values: std.StringHashMap(TomlValue),

    pub fn init(allocator: std.mem.Allocator) TomlParser {
        return TomlParser{
            .allocator = allocator,
            .values = std.StringHashMap(TomlValue).init(allocator),
        };
    }

    pub fn deinit(self: *TomlParser) void {
        var it = self.values.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            entry.value_ptr.deinit(self.allocator);
        }
        self.values.deinit();
    }

    pub fn parse(self: *TomlParser, source: []const u8) !void {
        var lines = std.mem.splitScalar(u8, source, '\n');
        var current_section: ?[]const u8 = null;

        while (lines.next()) |line_raw| {
            const line = std.mem.trim(u8, line_raw, " \t\r");
            if (line.len == 0) continue;
            if (line[0] == '#') continue;

            // Section [header]
            if (line[0] == '[' and line[line.len - 1] == ']') {
                if (current_section) |s| self.allocator.free(s);
                current_section = try self.allocator.dupe(u8, line[1 .. line.len - 1]);
                continue;
            }

            // Key = Value
            if (std.mem.indexOf(u8, line, "=")) |eq_idx| {
                const key_raw = std.mem.trim(u8, line[0..eq_idx], " \t");
                var value_raw = std.mem.trim(u8, line[eq_idx + 1 ..], " \t");

                // Strip comments from value
                if (std.mem.indexOf(u8, value_raw, " #")) |comment_idx| {
                    value_raw = std.mem.trim(u8, value_raw[0..comment_idx], " \t");
                }

                // Construct full key: section.key
                var full_key: []const u8 = undefined;
                if (current_section) |section| {
                    full_key = try std.fmt.allocPrint(self.allocator, "{s}.{s}", .{ section, key_raw });
                } else {
                    full_key = try self.allocator.dupe(u8, key_raw);
                }

                const value = try self.parseValue(value_raw);
                try self.values.put(full_key, value);
            }
        }
        if (current_section) |s| self.allocator.free(s);
    }

    fn parseValue(self: *TomlParser, raw: []const u8) !TomlValue {
        if (std.mem.eql(u8, raw, "true")) return TomlValue{ .boolean = true };
        if (std.mem.eql(u8, raw, "false")) return TomlValue{ .boolean = false };

        if (raw.len >= 2 and raw[0] == '"' and raw[raw.len - 1] == '"') {
            // String: strip quotes
            return TomlValue{ .string = try self.allocator.dupe(u8, raw[1 .. raw.len - 1]) };
        }

        if (raw.len >= 2 and raw[0] == '[' and raw[raw.len - 1] == ']') {
            // Array: ["a", "b"]
            var list = std.ArrayList([]const u8).init(self.allocator);
            const inner = raw[1 .. raw.len - 1];
            var it = std.mem.splitScalar(u8, inner, ',');
            while (it.next()) |item_raw| {
                const item = std.mem.trim(u8, item_raw, " \t\"'");
                if (item.len > 0) {
                    try list.append(try self.allocator.dupe(u8, item));
                }
            }
            return TomlValue{ .array = list };
        }

        // Integer fallback
        if (std.fmt.parseInt(i64, raw, 10)) |int| {
            return TomlValue{ .integer = int };
        } else |_| {
             // Fallback to string if parsing fails (weird unquoted strings?)
             return TomlValue{ .string = try self.allocator.dupe(u8, raw) };
        }
    }
};
