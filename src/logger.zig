const std = @import("std");
const tm_putstring = @import("./syslib.zig").tm_putstring;

// デバッグプリント
pub fn DEBUG(comptime fmt: []const u8, args: anytype) void {
    var buf: [256]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, fmt, args) catch |err| {
        const msg = ERROR(err);
        @panic(msg);
    };
    _ = tm_putstring("DEBUG: ");
    _ = tm_putstring(text);
}

pub fn ERROR(err: anyerror) []const u8 {
    var buf: [256]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "ERROR: {}\n", .{err}) catch |er| {
        @panic(@errorName(er));
    };
    _ = tm_putstring(msg);
    return msg;
}
