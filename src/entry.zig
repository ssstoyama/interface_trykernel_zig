const INITIAL_SP = @import("./sysdef.zig").INITIAL_SP;
const VectorTable = @import("./boot/vector_table.zig").VectorTable;
const reset_handler = @import("./boot/reset_handler.zig").reset_handler;
const systimer_handler = @import("./systimer.zig").systimer_handler;

extern fn dispatch_entry() callconv(.C) void;

export const vector_table: VectorTable linksection(".vector") = .{
    .initial_stack_pointer = INITIAL_SP,
    .reset = reset_handler,
    .pend_sv = dispatch_entry,
    .sys_tick = systimer_handler,
};
