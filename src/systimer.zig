const trykernel = @import("./trykernel.zig");
const apidef = trykernel.apidef;
const sysdef = trykernel.sysdef;
const task = trykernel.task;

// システムタイマ割込みハンドラ
pub fn systimer_handler() callconv(.C) void {
    var iter = task.wait_queue.iter();
    while (true) {
        const tcb = iter.next() orelse break;
        if (tcb.waitim == apidef.TMO_FEVR) {
            continue;
        }
        if (tcb.waitim > sysdef.TIMER_PERIOD) {
            // 待ち時間から経過時間を減じる。
            tcb.waitim -= sysdef.TIMER_PERIOD;
        } else {
            task.wait_queue.remove_entry(tcb);
            tcb.state = .TS_READY;
            tcb.waifct = .TWFCT_NON;
            task.ready_queue[tcb.itskpri].add_entry(tcb);
        }
    }
    task.schedule();
}
