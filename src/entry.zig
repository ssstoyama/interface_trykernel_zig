const INITIAL_SP = @import("./sysdef.zig").INITIAL_SP;
const VectorTable = @import("./boot/vector_table.zig").VectorTable;
const reset_handler = @import("./boot/reset_handler.zig").reset_handler;

export const vector_table: VectorTable linksection(".vector") = .{
    .initial_stack_pointer = INITIAL_SP,
    .reset = reset_handler,
};
