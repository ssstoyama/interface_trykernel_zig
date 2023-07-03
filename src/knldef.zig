const syslib = @import("./syslib.zig");

// 割り込み制御ステートレジスタのアドレス
const SCB_ICSR = 0xE000_ED04;
// PendSV set-pending ビット
const ICSR_PENDSVSET = 1 << 28;
// ディスパッチャの呼出し
pub fn dispatch() void {
    syslib.out_w(SCB_ICSR, ICSR_PENDSVSET);
}
