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
