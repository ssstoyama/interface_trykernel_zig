const typedef = @import("./typedef.zig");

// タイムアウト時間 0
pub const TMO_POL: isize = 0;
// 無限待ち
pub const TMO_FEVR: isize = -1;

//タスク生成情報
pub const T_CTSK = struct {
    // タスク属性
    tskatr: typedef.ATR,
    // タスク起動アドレス
    task: typedef.FP,
    // タスク優先度
    itskpri: typedef.PRI,
    // スタックサイズ
    stksz: typedef.SZ,
    // スタックのバッファポインタ
    bufptr: u32,
};

// タスク属性
pub const TA_HLNG = 0x0000_0001;
pub const TA_USERBUF = 0x0000_0020;
pub const TA_RNG0 = 0x0000_0000;
pub const TA_RNG1 = 0x0000_0100;
pub const TA_RNG2 = 0x0000_0200;
pub const TA_RNG3 = 0x0000_0300;
