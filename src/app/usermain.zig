const trykernel = @import("../trykernel.zig");
const apidef = trykernel.apidef;
const eventflag = trykernel.eventflag;
const logger = trykernel.logger;
const sysdef = trykernel.sysdef;
const syslib = trykernel.syslib;
const task = trykernel.task;
const typedef = trykernel.typedef;

var flgid: typedef.ID = 0;
var cflg: apidef.T_CFLG = .{
    .flgatr = apidef.TA_TFIFO | apidef.TA_WMUL,
    .iflgptn = 0,
};

var tskstk_btn: [4096]u8 = [_]u8{0} ** 4096;
var tskid_btn: typedef.ID = undefined;
fn task_btn(stacd: isize, exinf: *anyopaque) void {
    _ = exinf;
    _ = stacd;
    logger.DEBUG("Start task_btn\n", .{});

    syslib.out_w(sysdef.GPIO(13), (syslib.in_w(sysdef.GPIO(13)) | sysdef.GPIO_PUE) & ~@as(u32, sysdef.GPIO_PDE));
    syslib.out_w(sysdef.GPIO_OE_CLR, 1 << 13);
    syslib.out_w(sysdef.GPIO_CTRL(13), 5);

    syslib.out_w(sysdef.GPIO(14), (syslib.in_w(sysdef.GPIO(14)) | sysdef.GPIO_PUE) & ~@as(u32, sysdef.GPIO_PDE));
    syslib.out_w(sysdef.GPIO_OE_CLR, 1 << 14);
    syslib.out_w(sysdef.GPIO_CTRL(14), 5);

    const btn0 = syslib.in_w(sysdef.GPIO_IN) & ((1 << 14) | (1 << 13));
    while (true) {
        const btn = syslib.in_w(sysdef.GPIO_IN) & ((1 << 14) | (1 << 13));
        const diff = btn ^ btn0;
        if (diff != 0) {
            if ((diff & (1 << 13)) != 0 and (btn & (1 << 13)) == 0) {
                logger.DEBUG("BTN-1 ON\n", .{});
                eventflag.tk_set_flg(flgid, 1 << 1) catch |err| {
                    const msg = logger.ERROR(err);
                    @panic(msg);
                };
            }
            if ((diff & (1 << 14)) != 0 and (btn & (1 << 14)) == 0) {
                logger.DEBUG("BTN-0 ON\n", .{});
                eventflag.tk_set_flg(flgid, 1 << 0) catch |err| {
                    const msg = logger.ERROR(err);
                    @panic(msg);
                };
            }
        }
        task.tk_dly_tsk(100) catch |err| {
            const msg = logger.ERROR(err);
            @panic(msg);
        };
    }
}
var ctsk_btn: apidef.T_CTSK = undefined;

var tskstk_led1: [1024]u8 = [_]u8{0} ** 1024;
var tskid_led1: typedef.ID = undefined;
fn task_led1(stacd: isize, exinf: *anyopaque) void {
    _ = exinf;
    _ = stacd;
    logger.DEBUG("Start task_led1\n", .{});

    var flgptn: usize = 0;
    while (true) {
        eventflag.tk_wai_flg(flgid, (1 << 0), apidef.TWF_ANDW | apidef.TWF_BITCLR, &flgptn, apidef.TMO_FEVR) catch |err| {
            const msg = logger.ERROR(err);
            @panic(msg);
        };

        var i: usize = 0;
        while (i < 3) : (i += 1) {
            syslib.out_w(sysdef.GPIO_OUT_SET, (1 << 25));
            task.tk_dly_tsk(500) catch |err| {
                const msg = logger.ERROR(err);
                @panic(msg);
            };
            syslib.out_w(sysdef.GPIO_OUT_CLR, (1 << 25));
            task.tk_dly_tsk(500) catch |err| {
                const msg = logger.ERROR(err);
                @panic(msg);
            };
        }
    }
}
var ctsk_led1: apidef.T_CTSK = undefined;

var tskstk_led2: [1024]u8 = [_]u8{0} ** 1024;
var tskid_led2: typedef.ID = undefined;
fn task_led2(stacd: isize, exinf: *anyopaque) void {
    _ = exinf;
    _ = stacd;
    logger.DEBUG("Start task_led2\n", .{});

    var flgptn: usize = 0;
    while (true) {
        eventflag.tk_wai_flg(flgid, (1 << 1), apidef.TWF_ANDW | apidef.TWF_BITCLR, &flgptn, apidef.TMO_FEVR) catch |err| {
            const msg = logger.ERROR(err);
            @panic(msg);
        };

        var i: usize = 0;
        while (i < 5) : (i += 1) {
            syslib.out_w(sysdef.GPIO_OUT_SET, (1 << 25));
            task.tk_dly_tsk(100) catch |err| {
                const msg = logger.ERROR(err);
                @panic(msg);
            };
            syslib.out_w(sysdef.GPIO_OUT_CLR, (1 << 25));
            task.tk_dly_tsk(100) catch |err| {
                const msg = logger.ERROR(err);
                @panic(msg);
            };
        }
    }
}
var ctsk_led2: apidef.T_CTSK = undefined;

fn main() !void {
    logger.DEBUG("Start user-main\n", .{});

    ctsk_btn = apidef.T_CTSK{
        .tskatr = apidef.TA_HLNG | apidef.TA_RNG3 | apidef.TA_USERBUF,
        .task = @intFromPtr(&task_btn),
        .itskpri = 10,
        .stksz = @sizeOf(@TypeOf(tskstk_btn)),
        .bufptr = @intFromPtr(&tskstk_btn),
    };
    ctsk_led1 = .{
        .tskatr = apidef.TA_HLNG | apidef.TA_RNG3 | apidef.TA_USERBUF,
        .task = @intFromPtr(&task_led1),
        .itskpri = 10,
        .stksz = @sizeOf(@TypeOf(tskstk_led1)),
        .bufptr = @intFromPtr(&tskstk_led1),
    };
    ctsk_led2 = .{
        .tskatr = apidef.TA_HLNG | apidef.TA_RNG3 | apidef.TA_USERBUF,
        .task = @intFromPtr(&task_led2),
        .itskpri = 10,
        .stksz = @sizeOf(@TypeOf(tskstk_led2)),
        .bufptr = @intFromPtr(&tskstk_led2),
    };

    flgid = try eventflag.tk_cre_flg(cflg);

    tskid_btn = try task.tk_cre_tsk(&ctsk_btn);
    try task.tk_sta_tsk(tskid_btn, 0);

    tskid_led1 = try task.tk_cre_tsk(&ctsk_led1);
    try task.tk_sta_tsk(tskid_led1, 0);

    tskid_led2 = try task.tk_cre_tsk(&ctsk_led2);
    try task.tk_sta_tsk(tskid_led2, 0);
}

pub fn usermain() void {
    main() catch |err| {
        const msg = logger.ERROR(err);
        @panic(msg);
    };
}
