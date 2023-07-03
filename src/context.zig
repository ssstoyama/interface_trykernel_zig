const trykernel = @import("./trykernel.zig");
const syslib = trykernel.syslib;
const typedef = trykernel.typedef;

// スタック上の実行コンテキスト情報
pub const StackFrame = extern struct {
    // R4-R11レジスタ
    r_: [8]u32,
    // R0-R3レジスタ
    r: [4]u32,
    // R12レジスタ
    ip: u32,
    // lrレジスタ
    lr: u32,
    // pcレジスタ
    pc: u32,
    // xpsrレジスタ
    xpsr: u32,
};

// 初期実行コンテキストの作成
pub fn make_context(sp: u32, ssize: usize, fp: typedef.FP) *StackFrame {
    // スタック上の実行コンテクスト情報へのポインタをsfpに設定
    var sfp: *StackFrame = @ptrFromInt(sp + ssize - @sizeOf(StackFrame));

    // 実行コンテキスト情報の初期化
    sfp.xpsr = 0x0100_0000;
    sfp.pc = @truncate(fp & ~@as(typedef.FP, 0x0000_0001));

    return sfp;
}
