const trykernel = @import("../trykernel.zig");
const apidef = trykernel.apidef;
const logger = trykernel.logger;
const sysdef = trykernel.sysdef;
const syslib = trykernel.syslib;
const task = trykernel.task;
const typedef = trykernel.typedef;

var tskstk_btn: [2048]u8 = [_]u8{0} ** 2048;
var tskid_btn: typedef.ID = undefined;
fn task_btn(stacd: isize, exinf: *anyopaque) void {
    _ = exinf;
    _ = stacd;
    logger.DEBUG("Start task_btn\n", .{});

    syslib.out_w(sysdef.GPIO(14), (syslib.in_w(sysdef.GPIO(14)) | sysdef.GPIO_PUE) & ~@as(u32, sysdef.GPIO_PDE));
    syslib.out_w(sysdef.GPIO_OE_CLR, 1 << 14);
    syslib.out_w(sysdef.GPIO_CTRL(14), 5);

    var btn0 = syslib.in_w(sysdef.GPIO_IN) & (1 << 14);
    while (true) {
        const btn = syslib.in_w(sysdef.GPIO_IN) & (1 << 14);
        if (btn != btn0) {
            if (btn == 0) {
                logger.DEBUG("BTN ON\n", .{});
                task.tk_wup_tsk(tskid_led) catch |err| {
                    const msg = logger.ERROR(err);
                    @panic(msg);
                };
            }
            btn0 = btn;
        }
        task.tk_dly_tsk(100) catch |err| {
            const msg = logger.ERROR(err);
            @panic(msg);
        };
    }
}
var ctsk_btn: apidef.T_CTSK = undefined;

var tskstk_led: [1024]u8 = [_]u8{0} ** 1024;
var tskid_led: typedef.ID = undefined;
fn task_led(stacd: isize, exinf: *anyopaque) void {
    _ = exinf;
    _ = stacd;
    logger.DEBUG("Start task_led\n", .{});

    while (true) {
        task.tk_slp_tsk(apidef.TMO_FEVR) catch |err| {
            const msg = logger.ERROR(err);
            @panic(msg);
        };
        syslib.out_w(sysdef.GPIO_OUT_SET, (1 << 25));
        task.tk_dly_tsk(1000) catch |err| {
            const msg = logger.ERROR(err);
            @panic(msg);
        };
        syslib.out_w(sysdef.GPIO_OUT_CLR, (1 << 25));
    }
}
var ctsk_led: apidef.T_CTSK = undefined;

fn main() !void {
    logger.DEBUG("Start user-main\n", .{});

    ctsk_btn = apidef.T_CTSK{
        .tskatr = apidef.TA_HLNG | apidef.TA_RNG3 | apidef.TA_USERBUF,
        .task = @intFromPtr(&task_btn),
        .itskpri = 10,
        .stksz = @sizeOf(@TypeOf(tskstk_btn)),
        .bufptr = @intFromPtr(&tskstk_btn),
    };
    ctsk_led = .{
        .tskatr = apidef.TA_HLNG | apidef.TA_RNG3 | apidef.TA_USERBUF,
        .task = @intFromPtr(&task_led),
        .itskpri = 10,
        .stksz = @sizeOf(@TypeOf(tskstk_led)),
        .bufptr = @intFromPtr(&tskstk_led),
    };

    tskid_btn = try task.tk_cre_tsk(&ctsk_btn);
    try task.tk_sta_tsk(tskid_btn, 0);

    tskid_led = try task.tk_cre_tsk(&ctsk_led);
    try task.tk_sta_tsk(tskid_led, 0);
}

pub fn usermain() void {
    main() catch |err| {
        const msg = logger.ERROR(err);
        @panic(msg);
    };
}
