const std = @import("std");
const scanner = @import("../core/scanner.zig");
const finding = @import("../core/finding.zig");
const reporter = @import("../core/reporter.zig");

// Minimal JSON-RPC structures
const JsonRpcRequest = struct {
    jsonrpc: []const u8,
    method: []const u8,
    params: ?std.json.Value = null,
    id: ?std.json.Value = null,
};

const McpTool = struct {
    name: []const u8,
    description: []const u8,
    inputSchema: std.json.Value,
};

pub const McpServer = struct {
    allocator: std.mem.Allocator,
    scan_engine: *scanner.Scanner,
    ignores: [][]const u8,

    pub fn init(allocator: std.mem.Allocator, s: *scanner.Scanner, ignores: [][]const u8) McpServer {
        return .{
            .allocator = allocator,
            .scan_engine = s,
            .ignores = ignores,
        };
    }

    pub fn run(self: *McpServer) !void {
        const stdin = std.io.getStdIn().reader();
        const stdout = std.io.getStdOut().writer();

        var buf: [1024 * 1024]u8 = undefined;

        while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            // Parse Request
            const parsed_req = try std.json.parseFromSlice(JsonRpcRequest, self.allocator, line, .{ .ignore_unknown_fields = true });
            defer parsed_req.deinit();
            const req = parsed_req.value;

            // Handle Request
            if (std.mem.eql(u8, req.method, "initialize")) {
                try self.handleInitialize(stdout, req.id);
            } else if (std.mem.eql(u8, req.method, "tools/list")) {
                try self.handleToolsList(stdout, req.id);
            } else if (std.mem.eql(u8, req.method, "tools/call")) {
                try self.handleToolsCall(stdout, req.id, req.params);
            } else {
                // Ignore unknown notifications or methods for MVP
            }
        }
    }

    fn handleInitialize(self: *McpServer, writer: anytype, id: ?std.json.Value) !void {
        _ = self;
        try sendResponse(writer, id, .{
            .protocolVersion = "2024-11-05",
            .capabilities = .{ .tools = .{} },
            .serverInfo = .{
                .name = "vibecheck-mcp",
                .version = "1.0.0",
            },
        });
    }

    fn handleToolsList(self: *McpServer, writer: anytype, id: ?std.json.Value) !void {
        _ = self;
        const Tool = struct {
            name: []const u8,
            description: []const u8,
            inputSchema: struct {
                type: []const u8 = "object",
                properties: struct {
                    path: struct {
                        type: []const u8 = "string",
                        description: []const u8 = "Absolute path to scan",
                    },
                },
                required: []const []const u8 = &[_][]const u8{"path"},
            },
        };

        const ToolsListResult = struct {
            tools: []const Tool,
        };
        
        const result = ToolsListResult{
            .tools = &[_]Tool{
                .{
                    .name = "vibecheck_scan",
                    .description = "Scan a directory for bad vibes (TODOs, secrets, etc.)",
                    .inputSchema = .{ .properties = .{ .path = .{} } },
                },
            },
        };
        
        try sendResponse(writer, id, result);
    }

    fn handleToolsCall(self: *McpServer, writer: anytype, id: ?std.json.Value, params: ?std.json.Value) !void {
        const p = params orelse return;
        const name = p.object.get("name").?.string;
        
        if (std.mem.eql(u8, name, "vibecheck_scan")) {
            const args_obj = p.object.get("arguments").?.object;
            const path_val = args_obj.get("path").?;
            const path = path_val.string;

            // Reset findings for fresh scan
            self.scan_engine.findings.clearRetainingCapacity();
            self.scan_engine.scan(path, self.ignores) catch |err| {
                 // Send error response if scan failed
                 std.debug.print("MCP Scan Error: {}\n", .{err});
            };
            
            // Serialize findings to string first
            var findings_buf = std.ArrayList(u8).init(self.allocator);
            defer findings_buf.deinit();
            try std.json.stringify(self.scan_engine.findings.items, .{}, findings_buf.writer());
            
            // Create the inner content struct
            const ContentItem = struct {
                type: []const u8 = "text",
                text: []const u8,
            };
            const ToolResult = struct {
                content: []const ContentItem,
                isError: bool = false,
            };
            
            const result_data = ToolResult{
                .content = &[_]ContentItem{
                    .{ .text = findings_buf.items },
                },
            };

            // Send Response Wrapper
            const Response = struct {
                jsonrpc: []const u8 = "2.0",
                id: ?std.json.Value,
                result: ToolResult,
            };

            try std.json.stringify(Response{ .id = id, .result = result_data }, .{ .emit_null_optional_fields = false }, writer);
            try writer.print("\n", .{});
        }
    }

    fn sendResponse(writer: anytype, id: ?std.json.Value, result: anytype) !void {
        const Response = struct {
            jsonrpc: []const u8 = "2.0",
            id: ?std.json.Value,
            result: @TypeOf(result),
        };
        try std.json.stringify(Response{ .id = id, .result = result }, .{ .emit_null_optional_fields = false }, writer);
        try writer.print("\n", .{});
    }
};
