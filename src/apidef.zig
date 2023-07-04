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

// 待ちタスクをFIFO順で管理
pub const TA_TFIFO = 0x0000_0000;
// 待ちタスクを優先度順で管理
pub const TA_TPRI = 0x0000_0001;
// 待ち行列先頭のタスクを優先
pub const TA_FIRST = 0x0000_0000;
// 要求数の少ないタスクを優先
pub const TA_CNT = 0x0000_0002;
// 複数タスクの待ちを許さない
pub const TA_WFGL = 0x0000_0000;
// 複数タスクの待ちを許す
pub const TA_WMUL = 0x0000_0008;

// イベントフラグ生成情報
pub const T_CFLG = struct {
    // イベントフラグ属性
    flgatr: typedef.ATR,
    // イベントフラグ初期値
    iflgptn: usize,
};

// AND待ち
pub const TWF_ANDW: usize = 0x0000_0000;
// OR待ち
pub const TWF_ORW: usize = 0x0000_0001;
// 全ビットのクリア
pub const TWF_CLR: usize = 0x0000_0010;
// 条件ビットのみクリア
pub const TWF_BITCLR: usize = 0x0000_0020;

pub const T_CSEM = struct {
    // セマフォ属性
    sematr: typedef.ATR,
    // セマフォ資源数の初期値
    isemcnt: isize,
    // セマフォ資源数の最大値
    maxsem: isize,
};
