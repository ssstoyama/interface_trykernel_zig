const syslib = @import("../syslib.zig");
const sysdef = @import("../sysdef.zig");
const logger = @import("../logger.zig");

fn delay_ms(ms: usize) void {
    var cnt: usize = ms / sysdef.TIMER_PERIOD;

    while (cnt > 0) {
        if ((syslib.in_w(sysdef.SYST_CSR) & sysdef.SYST_CSR_COUNTFLAG) != 0) {
            cnt -= 1;
        }
    }
}

pub fn main() noreturn {
    syslib.tm_com_init();

    logger.DEBUG("Hello, World!\n", .{});
    while (true) {
        // LEDの表示反転
        syslib.out_w(sysdef.GPIO_OUT_XOR, (1 << 25));
        delay_ms(500);
    }
    unreachable;
}
