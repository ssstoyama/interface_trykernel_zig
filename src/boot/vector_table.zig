pub const Handler = *const fn () callconv(.C) void;

// 例外ベクターテーブル
pub const VectorTable = extern struct {
    initial_stack_pointer: u32,
    reset: Handler = default_handler,
    nmi: Handler = default_handler,
    hard_fault: Handler = default_handler,
    reserved0: [7]u32 = undefined,
    svcall: Handler = default_handler,
    reserved1: [2]u32 = undefined,
    pend_sv: Handler = default_handler,
    sys_tick: Handler = default_handler,
    irq: [32]Handler = [_]Handler{default_handler} ** 32,
};

// デフォルトハンドラ
fn default_handler() callconv(.C) void {
    while (true) {}
}
