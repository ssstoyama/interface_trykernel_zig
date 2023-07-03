const trykernel = @import("./trykernel.zig");
const context = trykernel.context;
const syslib = trykernel.syslib;
const typedef = trykernel.typedef;
const KernelError = trykernel.KernelError;

// タスク状態
pub const TSTAT = enum(u8) {
    // 未登録
    TS_NONEXIST = 0,
    // 実行状態 or 実行可能状態
    TS_READY = 1,
    // 待ち状態
    TS_WAIT = 2,
    // 休止状態
    TS_DORMANT = 3,
};

// タスクの待ち要因
pub const TWFCT = enum(u8) {
    // 無し
    TWFCT_NON = 0,
    // tk_dly_tskによる時間待ち
    TWFCT_DLY = 1,
};

pub const TCB = struct {
    // コンテキスト情報へのポインタ
    context: *context.StackFrame = undefined,

    pre: ?*TCB = null,
    next: ?*TCB = null,

    // タスク状態
    state: TSTAT = undefined,
    // 実行開始アドレス
    tskadr: typedef.FP = undefined,
    // 実行優先度
    itskpri: typedef.PRI = undefined,
    // スタックのアドレス
    stkadr: u32 = undefined,
    // スタックのサイズ
    stksz: typedef.SZ = undefined,

    waifct: TWFCT = undefined,
    waitim: typedef.RELTIM = undefined,
    waierr: KernelError = undefined,
};

pub const TCB_Queue = struct {
    head: ?*TCB = null,

    const Self = @This();

    const Iterator = struct {
        cur: ?*TCB,

        pub fn init(head: ?*TCB) Iterator {
            return .{
                .cur = head,
            };
        }

        pub fn next(self: *Iterator) ?*TCB {
            var tcb = self.cur;
            if (tcb) |t| {
                self.cur = t.next;
            } else {
                self.cur = null;
            }
            return tcb;
        }
    };

    pub fn init() Self {
        return .{};
    }

    pub fn iter(self: Self) Iterator {
        return Iterator.init(self.head);
    }

    pub fn is_empty(self: Self) bool {
        return self.head == null;
    }

    pub fn add_entry(self: *Self, tcb: *TCB) void {
        if (self.head) |head| {
            var end = head.pre;
            if (end) |e| e.next = tcb;
            tcb.pre = end;
            head.pre = tcb;
        } else {
            self.head = tcb;
            tcb.pre = tcb;
        }
    }

    pub fn remove_top(self: *Self) void {
        var head = self.head orelse return;
        self.head = head.next;
        if (self.head) |h| h.pre = head.pre;
        head.pre = null;
        head.next = null;
    }

    pub fn remove_entry(self: *Self, tcb: *TCB) void {
        if (self.head == tcb) {
            // tcbが先頭
            self.remove_top();
        } else {
            tcb.pre.?.next = tcb.next;
            if (tcb.pre) |pre| pre.next = tcb.next;
            if (tcb.next) |next| {
                next.pre = tcb.pre;
            } else {
                // tcbが末尾
                if (self.head) |h| h.pre = tcb.pre;
                self.head.?.pre = tcb.pre;
            }
            tcb.pre = null;
            tcb.next = null;
        }
    }
};

// 割り込み制御ステートレジスタのアドレス
const SCB_ICSR = 0xE000_ED04;
// PendSV set-pending ビット
const ICSR_PENDSVSET = 1 << 28;
// ディスパッチャの呼出し
pub fn dispatch() void {
    syslib.out_w(SCB_ICSR, ICSR_PENDSVSET);
}

const testing = @import("std").testing;
test "TCB_Queue" {
    var q = TCB_Queue.init();
    var tcb_ready = TCB{ .state = TSTAT.TS_READY };
    var tcb_wait = TCB{ .state = TSTAT.TS_WAIT };
    var tcb_dormang = TCB{ .state = TSTAT.TS_DORMANT };

    q.add_entry(&tcb_ready);
    q.add_entry(&tcb_wait);
    q.add_entry(&tcb_dormang);
    try testing.expectEqual(tcb_ready.state, q.head.?.state);
    try testing.expectEqual(tcb_wait.state, q.head.?.next.?.state);
    try testing.expectEqual(tcb_dormang.state, q.head.?.next.?.next.?.state);
    try testing.expectEqual(true, q.head.?.next.?.next.?.next == null);
    try testing.expectEqual(q.head.?.pre.?.state, q.head.?.next.?.next.?.state);

    q.remove_top();
    try testing.expectEqual(tcb_wait.state, q.head.?.state);
    try testing.expectEqual(tcb_dormang.state, q.head.?.next.?.state);
    try testing.expectEqual(true, q.head.?.next.?.next == null);
    try testing.expectEqual(tcb_dormang.state, q.head.?.pre.?.state);

    q.remove_entry(&tcb_dormang);
    try testing.expectEqual(tcb_wait.state, q.head.?.state);
    try testing.expectEqual(true, q.head.?.next == null);
    try testing.expectEqual(tcb_wait.state, q.head.?.pre.?.state);

    q.remove_top();
    try testing.expectEqual(true, q.head == null);
}
