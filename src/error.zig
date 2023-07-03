pub const KernelError = error{
    SYS, // システムエラー
    NOCOP, // コプロセッサ使用不可
    NOSPT, // 未サポート機能
    RSFN, // 予約機能コード番号
    RSATR, // 不正属性
    PAR, // パラメータ不正
    ID, // ID不正
    CTX, // コンテキストエラー
    MACV, // メモリアクセス違反
    OACV, // オブジェクトアクセス違反
    ILUSE, // システムコール不正
    NOMEM, // メモリ不足
    LIMIT, // 上限値エラー
    OBJ, // オブジェクト状態エラー
    NOEXS, // オブジェクト不正エラー
    QOVR, // 上限エラー
    RLWAI, // 待ち状態強制解除
    TMOUT, // タイムアウトエラー
    DLT, // 待ちオブジェクト削除
    DISWAI, // 待ち禁止による待ち状態解除
    IO, // I/Oエラー
};
