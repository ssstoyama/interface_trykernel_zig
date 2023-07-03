const trykernel = @import("../trykernel.zig");
const context = trykernel.context;
const logger = trykernel.logger;
const sysdef = trykernel.sysdef;
const syslib = trykernel.syslib;
const dispatch = trykernel.knldef.dispatch;

// 実行中のタスクのID番号
export var cur_task: u32 = 0;
// 次に実行するタスクのID番号
export var next_task: u32 = 0;

// タスクの数
const MAX_FNC_ID: usize = 2;
// 保存された実行コンテキストへのポインタ
export var ctx_tbl: [MAX_FNC_ID]*context.StackFrame = [_]*context.StackFrame{undefined} ** MAX_FNC_ID;

// タスクのスタック
const STACK_SIZE: usize = 1024;
var stack_1: [STACK_SIZE]u32 = [_]u32{0} ** STACK_SIZE;
var stack_2: [STACK_SIZE]u32 = [_]u32{0} ** STACK_SIZE;

fn delay_ms(ms: usize) void {
    var cnt: usize = ms / sysdef.TIMER_PERIOD;

    while (cnt > 0) {
        if ((syslib.in_w(sysdef.SYST_CSR) & sysdef.SYST_CSR_COUNTFLAG) != 0) {
            cnt -= 1;
        }
    }
}

fn task_1() void {
    logger.DEBUG("start task_1\n", .{});
    while (true) {
        // LEDの点灯
        syslib.out_w(sysdef.GPIO_OUT_SET, (1 << 25));
        delay_ms(500);

        // 次に実行するタスクを設定
        next_task = 2;
        // ディスパッチャの実行
        dispatch();
    }
}

fn task_2() void {
    logger.DEBUG("start task_2\n", .{});
    while (true) {
        // LEDの消灯
        syslib.out_w(sysdef.GPIO_OUT_CLR, (1 << 25));
        delay_ms(200);

        // 次に実行するタスクを設定
        next_task = 1;
        // ディスパッチャの実行
        dispatch();
    }
}

pub fn main() noreturn {
    syslib.tm_com_init();

    logger.DEBUG("Hello, World!\n", .{});

    // タスクの初期化
    ctx_tbl[0] = context.make_context(@intFromPtr(&stack_1), @sizeOf([STACK_SIZE]u32), @intFromPtr(&task_1));
    ctx_tbl[1] = context.make_context(@intFromPtr(&stack_2), @sizeOf([STACK_SIZE]u32), @intFromPtr(&task_2));

    // ディスパッチにより実行する関数
    next_task = 1;
    // ディスパッチャの実行
    dispatch();

    unreachable;
}
