const std = @import("std");
const tm_putstring = @import("./syslib.zig").tm_putstring;

// デバッグプリント
pub fn DEBUG(comptime fmt: []const u8, args: anytype) void {
    var buf: [256]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, fmt, args) catch |err| {
        ERROR(err);
        @panic(@errorName(err));
    };
    _ = tm_putstring("DEBUG: ");
    _ = tm_putstring(text);
}

pub fn ERROR(err: anyerror) void {
    _ = tm_putstring("ERROR: ");
    _ = tm_putstring(@errorName(err));
    _ = tm_putstring("\n");
}
