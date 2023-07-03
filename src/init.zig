const trykernel = @import("./trykernel.zig");
const apidef = trykernel.apidef;
const logger = trykernel.logger;
const syslib = trykernel.syslib;
const task = trykernel.task;
const usermain = @import("./app//usermain.zig").usermain;

var taskstk_ini: [1024]u8 = [_]u8{0} ** 1024;

fn initsk(stacd: isize, exinf: *anyopaque) void {
    _ = exinf;
    _ = stacd;

    usermain();

    logger.DEBUG("End Try Kernel\n", .{});
    task.tk_ext_tsk();
}

var ctsk_init: apidef.T_CTSK = undefined;

pub fn main() noreturn {
    syslib.tm_com_init();
    logger.DEBUG("Start Try Kernel\n", .{});

    ctsk_init = apidef.T_CTSK{
        .tskatr = apidef.TA_HLNG | apidef.TA_RNG0 | apidef.TA_USERBUF,
        .task = @intFromPtr(&initsk),
        .itskpri = 1, // 優先度MAX
        .stksz = @sizeOf(@TypeOf(taskstk_ini)),
        .bufptr = @intFromPtr(&taskstk_ini),
    };

    const tskid_ini = task.tk_cre_tsk(&ctsk_init) catch |err| {
        const msg = logger.ERROR(err);
        @panic(msg);
    };
    task.tk_sta_tsk(tskid_ini, 0) catch |err| {
        const msg = logger.ERROR(err);
        @panic(msg);
    };

    unreachable;
}
