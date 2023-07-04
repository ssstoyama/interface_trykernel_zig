const trykernel = @import("./trykernel.zig");
const apidef = trykernel.apidef;
const config = trykernel.config;
const context = trykernel.context;
const knldef = trykernel.knldef;
const sysdef = trykernel.sysdef;
const syslib = trykernel.syslib;
const typedef = trykernel.typedef;
const KernelError = trykernel.KernelError;

// タスク管理ブロック (TCB)
var tcb_tbl: [config.CNF_MAX_TSK_ID]knldef.TCB = [_]knldef.TCB{knldef.TCB{}} ** config.CNF_MAX_TSK_ID;
// タスクのレディキュー
pub var ready_queue: [config.CNF_MAX_TSK_PRI]knldef.TCB_Queue = [_]knldef.TCB_Queue{knldef.TCB_Queue.init()} ** config.CNF_MAX_TSK_PRI;
// 時間待ち状態のタスクの待ち行列(ウェイトキュー)
pub var wait_queue: knldef.TCB_Queue = knldef.TCB_Queue.init();
// 実行中のタスク
pub export var cur_task: ?*knldef.TCB = null;
// 次に実行するタスク
export var sche_task: ?*knldef.TCB = null;
// ディスパッチャ実行中
export var disp_running: bool = false;

// タスク生成API
pub fn tk_cre_tsk(pk_ctsk: *const apidef.T_CTSK) !typedef.ID {
    // 引数チェック
    if ((pk_ctsk.tskatr & ~@as(u32, apidef.TA_RNG3)) != (apidef.TA_HLNG | apidef.TA_USERBUF)) return KernelError.RSATR;
    if ((pk_ctsk.itskpri <= 0) or (pk_ctsk.itskpri > config.CNF_MAX_TSK_PRI)) return KernelError.PAR;
    if (pk_ctsk.stksz == 0) return KernelError.PAR;

    const intsts = syslib.DI();
    defer syslib.EI(intsts);

    // 未使用のTCBを検索
    var i: usize = 0;
    while (i < config.CNF_MAX_TSK_ID) : (i += 1) {
        if (tcb_tbl[i].state == knldef.TSTAT.TS_NONEXIST) break;
    }
    // タスクが既に最大数
    if (i >= config.CNF_MAX_TSK_ID) return KernelError.LIMIT;
    // TCBの初期化
    tcb_tbl[i] = .{
        .state = .TS_DORMANT,
        .tskadr = pk_ctsk.task,
        .itskpri = pk_ctsk.itskpri,
        .stksz = pk_ctsk.stksz,
        .stkadr = pk_ctsk.bufptr,
    };
    return i + 1; // タスクID
}

// タスク実行API
pub fn tk_sta_tsk(tskid: typedef.ID, stacd: isize) KernelError!void {
    _ = stacd;
    // 引数チェック
    if ((tskid <= 0) or (tskid > config.CNF_MAX_TSK_ID)) return KernelError.ID;

    const intsts = syslib.DI();
    defer syslib.EI(intsts);

    var tcb = &tcb_tbl[tskid - 1];
    if (tcb.state != .TS_DORMANT) return KernelError.OBJ; // タスクを実行できない

    // タスクを実行できる状態に変更
    tcb.state = .TS_READY;
    tcb.context = context.make_context(tcb.stkadr, tcb.stksz, tcb.tskadr);
    ready_queue[tcb.itskpri].add_entry(tcb);
    schedule();
}

// タスクの動作終了API
pub fn tk_ext_tsk() void {
    const intsts = syslib.DI();
    defer syslib.EI(intsts);

    if (cur_task) |task| {
        // タスクを休止状態へ
        task.state = .TS_DORMANT;
        ready_queue[task.itskpri].remove_top();
        schedule();
    }
}

// タスクの実行遅延 API
pub fn tk_dly_tsk(dlytim: typedef.RELTIM) KernelError!void {
    const intsts = syslib.DI();
    defer syslib.EI(intsts);

    if (dlytim <= 0) return;
    var task = cur_task orelse return;
    ready_queue[task.itskpri].remove_top();

    // タスクの状態を待ち状態に変更
    task.state = .TS_WAIT;
    // 待ち要因を設定
    task.waifct = .TWFCT_DLY;
    // 待ち時間を設定
    task.waitim = dlytim + sysdef.TIMER_PERIOD;

    wait_queue.add_entry(task);
    schedule();
}

// タスク起床待ちAPI
pub fn tk_slp_tsk(tmout: typedef.TMO) KernelError!void {
    const intsts = syslib.DI();
    defer syslib.EI(intsts);

    var task = cur_task orelse return;
    // 起床要求有り
    if (task.wupcnt > 0) {
        task.wupcnt -= 1;
        return;
    }
    // 起床要求無し
    ready_queue[task.itskpri].remove_top();

    // タスクの状態を待ち状態に変更
    task.state = .TS_WAIT;
    // 待ち要因を設定
    task.waifct = .TWFCT_SLP;
    // 待ち時間を設定
    if (tmout == apidef.TMO_FEVR) {
        task.waitim = tmout;
    } else {
        task.waitim = tmout + sysdef.TIMER_PERIOD;
    }

    wait_queue.add_entry(task);
    schedule();
}

// タスクの起床 API
pub fn tk_wup_tsk(tskid: typedef.ID) KernelError!void {
    if (tskid <= 0 or tskid > config.CNF_MAX_TSK_ID) return KernelError.ID;

    const intsts = syslib.DI();
    defer syslib.EI(intsts);

    var tcb = &tcb_tbl[tskid - 1];
    // tk_slp_tskで待ち状態か？
    if (tcb.state == .TS_WAIT and tcb.waifct == .TWFCT_SLP) {
        wait_queue.remove_entry(tcb);

        tcb.state = .TS_READY;
        tcb.waifct = .TWFCT_NON;

        ready_queue[tcb.itskpri].add_entry(tcb);
        schedule();
        return;
    }
    // 実行できる状態の場合
    if (tcb.state == .TS_READY or tcb.state == .TS_WAIT) {
        // 起床要求数を増やす
        tcb.wupcnt += 1;
        return;
    }
    return KernelError.OBJ;
}

// タスクのスケジューリング
pub fn schedule() void {
    var i: usize = 0;
    while (i < config.CNF_MAX_TSK_PRI) : (i += 1) {
        if (!ready_queue[i].is_empty()) break;
    }

    if (i < config.CNF_MAX_TSK_PRI) {
        sche_task = ready_queue[i].head;
    } else {
        sche_task = null;
    }
    if (sche_task != cur_task and !disp_running) {
        knldef.dispatch();
    }
}
