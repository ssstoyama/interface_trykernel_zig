const trykernel = @import("./trykernel.zig");
const apidef = trykernel.apidef;
const config = trykernel.config;
const knldef = trykernel.knldef;
const sysdef = trykernel.sysdef;
const syslib = trykernel.syslib;
const task = trykernel.task;
const typedef = trykernel.typedef;
const KernelError = trykernel.KernelError;

// イベントフラグ管理ブロック(FLGCB)
var flgcb_tbl: [config.CNF_MAX_FLG_ID]knldef.FLGCB = [_]knldef.FLGCB{undefined} ** config.CNF_MAX_FLG_ID;

// イベントフラグの生成API
pub fn tk_cre_flg(pk_cflg: apidef.T_CFLG) KernelError!typedef.ID {
    const intsts = syslib.DI();
    defer syslib.EI(intsts);

    var flgid: typedef.ID = 0;
    while (flgid < config.CNF_MAX_FLG_ID) : (flgid += 1) {
        if (flgcb_tbl[flgid].state != .KS_NONEXIST) break;
    }

    if (flgid >= config.CNF_MAX_FLG_ID) {
        return KernelError.LIMIT;
    }
    flgcb_tbl[flgid].state = .KS_EXIST;
    flgcb_tbl[flgid].flgptn = pk_cflg.iflgptn;
    flgid += 1;
    return flgid;
}

// イベントフラグ待ちの条件チェック
fn check_flag(flgptn: usize, waiptn: usize, wfmode: usize) bool {
    if (wfmode & apidef.TWF_ORW != 0) {
        return (flgptn & waiptn) != 0;
    }
    return (flgptn & waiptn) == waiptn;
}

// イベントフラグのセットAPI
pub fn tk_set_flg(flgid: typedef.ID, setptn: usize) KernelError!void {
    if (flgid <= 0 or flgid > config.CNF_MAX_FLG_ID) return KernelError.ID;

    const intsts = syslib.DI();
    defer syslib.EI(intsts);

    var flgcb = &flgcb_tbl[flgid - 1];
    if (flgcb.state != .KS_EXIST) return KernelError.NOEXS;

    flgcb.flgptn |= setptn;
    var iter = task.wait_queue.iter();
    while (true) {
        var tcb = iter.next() orelse break;
        if (tcb.waifct != .TWFCT_FLG) continue;
        if (!check_flag(flgcb.flgptn, tcb.waiptn, tcb.wfmode)) continue;
        task.wait_queue.remove_entry(tcb);
        tcb.state = .TS_READY;
        tcb.waifct = .TWFCT_NON;
        tcb.p_flgptn = flgcb.flgptn;
        task.ready_queue[tcb.itskpri].add_entry(tcb);
        task.schedule();

        if ((tcb.wfmode & apidef.TWF_BITCLR) != 0) {
            // 対象フラグのクリア
            flgcb.flgptn &= ~@as(u32, tcb.waiptn);
            if (flgcb.flgptn == 0) {
                break;
            }
        }
        if ((tcb.wfmode & apidef.TWF_CLR) != 0) {
            // 全フラグのクリア
            flgcb.flgptn = 0;
            break;
        }
    }
}

// イベントフラグのクリアAPI
pub fn tk_clr_flg(flgid: typedef.ID, clrptn: usize) KernelError!void {
    if (flgid <= 0 or flgid > config.CNF_MAX_FLG_ID) return KernelError.ID;

    const intsts = syslib.DI();
    syslib.EI(intsts);

    var flgcb = &flgcb_tbl[flgid - 1];
    if (flgcb.state != .KS_EXIST) return KernelError.NOEXS;
    // フラグのクリア
    flgcb.flgptn &= clrptn;
}

// イベントフラグ待ちAPI
pub fn tk_wai_flg(flgid: typedef.ID, waiptn: usize, wfmode: usize, p_flgptn: *usize, tmout: typedef.TMO) KernelError!void {
    if (flgid <= 0 or flgid > config.CNF_MAX_FLG_ID) return KernelError.ID;

    const intsts = syslib.DI();
    defer syslib.EI(intsts);

    var flgcb = &flgcb_tbl[flgid - 1];
    // 未登録のイベントフラグ
    if (flgcb.state != .KS_EXIST) return KernelError.NOEXS;
    // 待ち条件不成立、かつ、待ち時間0の場合
    if (tmout == apidef.TMO_POL) return KernelError.TMOUT;
    // 待ち条件が成立している場合
    if (check_flag(flgcb.flgptn, waiptn, wfmode)) {
        p_flgptn.* = flgcb.flgptn;
        if ((wfmode & apidef.TWF_BITCLR) != 0) {
            // 該当フラグのクリア
            flgcb.flgptn &= ~@as(u32, waiptn);
        }
        if ((wfmode & apidef.TWF_CLR) != 0) {
            // 全フラグのクリア
            flgcb.flgptn = 0;
        }
        return;
    }
    // 待ち条件不成立、待ち状態に移行
    var cur_task = task.cur_task orelse return;
    task.ready_queue[cur_task.itskpri].remove_top();
    // タスクの状態を待ち状態に変更
    cur_task.state = .TS_WAIT;
    // 待ち要因を設定
    cur_task.waifct = .TWFCT_FLG;
    // 待ち時間を設定
    if (tmout == apidef.TMO_FEVR) {
        cur_task.waitim = tmout;
    } else {
        cur_task.waitim = tmout + sysdef.TIMER_PERIOD;
    }
    cur_task.waiptn = waiptn;
    cur_task.wfmode = wfmode;
    cur_task.p_flgptn = p_flgptn.*;
    task.wait_queue.add_entry(cur_task);
    task.schedule();
}
