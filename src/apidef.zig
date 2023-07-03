const typedef = @import("./typedef.zig");

pub const T_CTSK = struct {
    tskatr: typedef.ATR,
    task: typedef.FP,
    itskpri: typedef.PRI,
    stksz: typedef.SZ,
    bufptr: u32,
};

pub const TA_HLNG = 0x0000_0001;
pub const TA_USERBUF = 0x0000_0020;
pub const TA_RNG0 = 0x0000_0000;
pub const TA_RNG1 = 0x0000_0100;
pub const TA_RNG2 = 0x0000_0200;
pub const TA_RNG3 = 0x0000_0300;
