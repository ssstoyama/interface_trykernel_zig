const trykernel = @import("../trykernel.zig");
const apidef = trykernel.apidef;
const logger = trykernel.logger;
const syslib = trykernel.syslib;
const task = trykernel.task;
const typedef = trykernel.typedef;

var tskstk_1: [1024]u8 = [_]u8{0} ** 1024;
var tskid_1: typedef.ID = undefined;
fn task_1(stacd: isize, exinf: *anyopaque) void {
    _ = exinf;
    _ = stacd;
    logger.DEBUG("Start Task-1\n", .{});
    task.tk_ext_tsk();
}
var ctsk_1: apidef.T_CTSK = undefined;

var tskstk_2: [1024]u8 = [_]u8{0} ** 1024;
var tskid_2: typedef.ID = undefined;
fn task_2(stacd: isize, exinf: *anyopaque) void {
    _ = exinf;
    _ = stacd;
    logger.DEBUG("Start Task-2\n", .{});
    task.tk_ext_tsk();
}
var ctsk_2: apidef.T_CTSK = undefined;

fn main() !void {
    logger.DEBUG("Start user-main\n", .{});

    ctsk_1 = apidef.T_CTSK{
        .tskatr = apidef.TA_HLNG | apidef.TA_RNG3 | apidef.TA_USERBUF,
        .task = @intFromPtr(&task_1),
        .itskpri = 10,
        .stksz = @sizeOf(@TypeOf(tskstk_1)),
        .bufptr = @intFromPtr(&tskstk_1),
    };
    ctsk_2 = .{
        .tskatr = apidef.TA_HLNG | apidef.TA_RNG3 | apidef.TA_USERBUF,
        .task = @intFromPtr(&task_2),
        .itskpri = 10,
        .stksz = @sizeOf(@TypeOf(tskstk_2)),
        .bufptr = @intFromPtr(&tskstk_2),
    };

    tskid_1 = try task.tk_cre_tsk(&ctsk_1);
    try task.tk_sta_tsk(tskid_1, 0);

    tskid_2 = try task.tk_cre_tsk(&ctsk_2);
    try task.tk_sta_tsk(tskid_2, 0);
}

pub fn usermain() void {
    main() catch |err| {
        const msg = logger.ERROR(err);
        @panic(msg);
    };
}
