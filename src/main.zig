const std = @import("std");
const scanner = @import("core/scanner.zig");
const reporter = @import("core/reporter.zig");
const config_loader = @import("config/loader.zig");
const packs = @import("registry/packs.zig");
const mcp = @import("mcp/server.zig");

const default_pack_json = @embedFile("registry/default_pack.json");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Load Config
    var conf = config_loader.load(allocator, "vibecheck.toml") catch |err| {
        std.debug.print("Warning: Could not load config: {}\n", .{err});
        return err;
    };
    defer conf.deinit(allocator);

    // CLI Args Override & Root Path
    var root_path: []const u8 = ".";
    // Output modes
    var json_output = false;
    var github_output = false;
    var mcp_mode = false;
    
    if (std.mem.eql(u8, conf.output.format, "json")) json_output = true;

    if (args.len > 1) {
        for (args[1..]) |arg| {
            if (std.mem.eql(u8, arg, "--json")) {
                json_output = true;
            } else if (std.mem.eql(u8, arg, "--github")) {
                github_output = true;
            } else if (std.mem.eql(u8, arg, "--mcp")) {
                mcp_mode = true;
            } else if (!std.mem.startsWith(u8, arg, "-")) {
                 // Assume it's the path if it's not a flag (and not a known command like list-packs in current simple logic)
                 // Note: Simple manual parsing for MVP. Future versions might use a CLI library.
                 if (!std.mem.eql(u8, arg, "list-packs") and !std.mem.eql(u8, arg, "list-patterns")) {
                    root_path = arg;
                 }
            }
        }
    }

    var s = scanner.Scanner.init(allocator);
    defer s.deinit();

    // Load Default Pack (Embedded)
    var loader = packs.PackLoader.init(allocator);
    const parsed_default_pack = try loader.loadFromContent(default_pack_json);
    defer parsed_default_pack.deinit();

    var loaded_packs = std.ArrayList(std.json.Parsed(packs.Pack)).init(allocator);
    defer {
        for (loaded_packs.items) |p| {
            p.deinit();
        }
        loaded_packs.deinit();
    }

    // Load External Packs from Config
    for (conf.scan.packs.items) |pack_path| {
         const parsed_ext = loader.loadFromFile(pack_path) catch |err| {
             std.debug.print("Warning: Failed to load pack '{s}': {}\n", .{pack_path, err});
             continue;
         };
         try loaded_packs.append(parsed_ext);
    }

    // CLI Commands
    if (args.len > 1) {
        const cmd = args[1];
        if (std.mem.eql(u8, cmd, "list-packs")) {
             std.debug.print("\nLoaded Packs:\n", .{});
             // Default is always loaded
             std.debug.print("- {s} v{s} (Embedded)\n", .{parsed_default_pack.value.name, parsed_default_pack.value.version});
             
             for (loaded_packs.items) |parsed| {
                std.debug.print("- {s} v{s} (External)\n", .{parsed.value.name, parsed.value.version});
             }
             return;
        }
        if (std.mem.eql(u8, cmd, "list-patterns")) {
             std.debug.print("\nActive Patterns:\n", .{});
             // Print default
             for (parsed_default_pack.value.patterns) |p| {
                 std.debug.print("  [{s}] {s} ({s})\n", .{p.id, p.name, p.severity});
             }
             // Print external
             for (loaded_packs.items) |parsed| {
                 for (parsed.value.patterns) |p| {
                     std.debug.print("  [{s}] {s} (from config)\n", .{p.id, p.name});
                 }
             }
             return;
        }
    }

    // Register Patterns for Scanning
    for (parsed_default_pack.value.patterns) |p| {
        try s.matcher_engine.addPattern(packs.toMatcherPattern(p));
    }
    
    for (loaded_packs.items) |parsed| {
         for (parsed.value.patterns) |p| {
             try s.matcher_engine.addPattern(packs.toMatcherPattern(p));
         }
    }
    
    // Add logic to load external packs from config later...

    if (!mcp_mode) {
        try std.io.getStdOut().writer().print("Searching for vibes in {s}...\n", .{root_path});
    }

    // MCP Mode
    if (mcp_mode) {
        var server = mcp.McpServer.init(allocator, &s, conf.scan.ignore.items);
        try server.run();
        return;
    }

    // Run Scan
    s.scan(root_path, conf.scan.ignore.items) catch |err| {
        std.debug.print("Error during scan: {}\n", .{err});
        return err;
    };

    // Report
    if (json_output) {
        try reporter.JsonReporter.report(s.findings.items);
    } else if (github_output) {
        try reporter.GitHubReporter.report(s.findings.items);
    } else {
        try reporter.ConsoleReporter.report(s.findings.items);
    }

    // Exit Code Logic
    const fail_on_severity = @intFromEnum(conf.output.fail_on);
    for (s.findings.items) |f| {
        if (@intFromEnum(f.severity) >= fail_on_severity) {
            std.process.exit(1);
        }
    }
}
