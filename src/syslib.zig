const sysdef = @import("./sysdef.zig");

// 32bitレジスタからの入力
pub fn in_w(addr: u32) u32 {
    return @as(*u32, @ptrFromInt(addr)).*;
}

// 32bitレジスタへの出力
pub fn out_w(addr: u32, data: u32) void {
    @as(*u32, @ptrFromInt(addr)).* = data;
}

// 32bitレジスタへの出力(ビットクリア)
const OP_CLR = 0x3000;
pub fn clr_w(addr: u32, data: u32) void {
    out_w(addr + OP_CLR, data);
}

// 32bitレジスタへの出力(ビットセット)
const OP_SET = 0x2000;
pub fn set_w(addr: u32, data: u32) void {
    out_w(addr + OP_SET, data);
}

// 32bitレジスタへの出力(ビット排他的論理和)
const OP_XOR = 0x1000;
pub fn xset_w(addr: u32, data: u32) void {
    out_w(addr + OP_XOR, data);
}

// PRIMASKレジスタ制御インライン関数
pub fn set_primask(pm: isize) void {
    asm volatile ("msr primask, %[pm]"
        :
        : [pm] "r" (pm),
    );
}

pub fn get_primask() isize {
    return asm volatile ("mrs %[ret], primask"
        : [ret] "=r" (-> isize),
    );
}

// 割込み禁止
pub fn DI() isize {
    var intsts = get_primask();
    set_primask(1);
    return intsts;
}

// 割込み許可
pub fn EI(intsts: isize) void {
    set_primask(intsts);
}

// UART0初期化
pub fn tm_com_init() void {
    // ボーレート設定
    out_w(sysdef.UART0_BASE + sysdef.UARTx_IBRD, 67);
    out_w(sysdef.UART0_BASE + sysdef.UARTx_FBRD, 52);
    // データ形式設定
    out_w(sysdef.UART0_BASE + sysdef.UARTx_LCR_H, 0x70);
    // 通信有効化
    out_w(sysdef.UART0_BASE + sysdef.UARTx_CR, sysdef.UART_CR_RXE | sysdef.UART_CR_TXE | sysdef.UART_CR_EN);
}

pub fn tm_putstring(str: []const u8) usize {
    var cnt: usize = 0;
    for (str) |c| {
        // 送信FIFOの空き待ち
        while (in_w(sysdef.UART0_BASE + sysdef.UARTx_FR) & sysdef.UART_FR_TXFF != 0) {}
        // データ送信
        out_w(sysdef.UART0_BASE + sysdef.UARTx_DR, c);
        cnt += 1;
    }
    return cnt;
}
