const trykernel = @import("./trykernel.zig");
const apidef = trykernel.apidef;
const config = trykernel.config;
const knldef = trykernel.knldef;
const sysdef = trykernel.sysdef;
const syslib = trykernel.syslib;
const systimer = trykernel.systimer;
const task = trykernel.task;
const typedef = trykernel.typedef;
const KernelError = trykernel.KernelError;

// セマフォ管理ブロック(SEMCB)
var semcb_tbl: [config.CNF_MAX_SEM_ID]knldef.SEMCB = [_]knldef.SEMCB{undefined} ** config.CNF_MAX_SEM_ID;

// セマフォの生成API
pub fn tk_cre_sem(pk_csem: apidef.T_CSEM) KernelError!typedef.ID {
    const intsts = syslib.DI();
    defer syslib.EI(intsts);

    var semid: usize = 0;
    while (semid < config.CNF_MAX_SEM_ID) : (semid += 1) {
        if (semcb_tbl[semid].state != .KS_NONEXIST) break;
    }
    if (semid >= config.CNF_MAX_SEM_ID) return KernelError.LIMIT;

    // セマフォ管理情報の初期化
    semcb_tbl[semid].state = .KS_EXIST;
    semcb_tbl[semid].semcnt = pk_csem.isemcnt;
    semcb_tbl[semid].maxsem = pk_csem.maxsem;
    semid += 1;

    return semid;
}

// セマフォの資源獲得API
pub fn tk_wai_sem(semid: typedef.ID, cnt: isize, tmout: typedef.TMO) KernelError!void {
    if (semid <= 0 or semid > config.CNF_MAX_SEM_ID) return KernelError.ID;

    const intsts = syslib.DI();
    defer syslib.EI(intsts);

    var semcb = &semcb_tbl[semid - 1];
    // 未登録のセマフォ
    if (semcb.state != .KS_EXIST) return KernelError.NOEXS;
    // 資源が足りなく、かつ、待ち時間0の場合
    if (tmout == apidef.TMO_POL) return KernelError.TMOUT;
    // 現在のセマフォの資源数 ≧ 要求する資源数
    if (semcb.semcnt >= cnt) {
        semcb.semcnt -= cnt;
        return;
    }
    // 資源が足りなく、待ち状態に移行
    var cur_task = task.cur_task orelse return;
    task.ready_queue[cur_task.itskpri].remove_top();
    // タスクの状態を待ち状態に変更
    cur_task.state = .TS_WAIT;
    // 待ち要因を設定
    cur_task.waifct = .TWFCT_SEM;
    // 待ち時間を設定
    if (tmout == apidef.TMO_FEVR) {
        cur_task.waitim = tmout;
    } else {
        cur_task.waitim = tmout + sysdef.TIMER_PERIOD;
    }
    cur_task.waisem = cnt;
    task.wait_queue.add_entry(cur_task);
    task.schedule();
}

// セマフォの資源返却API
pub fn tk_sig_sem(semid: typedef.ID, cnt: isize) KernelError!void {
    if (semid <= 0 or semid > config.CNF_MAX_SEM_ID) return KernelError.ID;

    const intsts = syslib.DI();
    defer syslib.EI(intsts);

    var semcb = &semcb_tbl[semid - 1];
    // 未登録のセマフォ
    if (semcb.state != .KS_EXIST) return KernelError.NOEXS;
    // 資源の返却
    semcb.semcnt += cnt;
    if (semcb.semcnt > semcb.maxsem) {
        // 資源数が最大値を超えた
        semcb.semcnt -= cnt;
        return KernelError.QOVR;
    }
    var iter = task.wait_queue.iter();
    while (true) {
        var tcb = iter.next() orelse break;
        if (tcb.waifct != .TWFCT_SEM) break;
        if (semcb.semcnt < tcb.waisem) break;
        // 要求資源数を満たしていれば実行可能状態へ
        semcb.semcnt -= tcb.waisem;
        task.wait_queue.remove_entry(tcb);
        tcb.state = .TS_READY;
        tcb.waifct = .TWFCT_NON;
        task.ready_queue[tcb.itskpri].add_entry(tcb);
        task.schedule();
    }
}
