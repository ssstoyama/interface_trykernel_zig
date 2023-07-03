const sysdef = @import("../sysdef.zig");
const syslib = @import("../syslib.zig");
const main = @import("../init.zig").main;

// メモリセクションのアドレス変数
extern const __data_org: anyopaque;
extern const __data_start: anyopaque;
extern const __data_end: anyopaque;
extern const __bss_start: anyopaque;
extern const __bss_end: anyopaque;

// クロックの初期化
const XOSC_STARTUP_DELAY: u32 = (sysdef.XOSC_KHz + 128) / 256;

// PLLの初期化
fn init_pll(pll: u32, refdiv: usize, vco_freq: usize, post_div1: usize, post_div2: usize) void {
    var ref_mhz: u32 = sysdef.XOSC_MHz / refdiv;
    var fbdiv: u32 = vco_freq / (ref_mhz * sysdef.MHz);
    var pdiv: u32 = (post_div1 << sysdef.PLL_PRIM_POSTDIV1_LSB) | (post_div2 << sysdef.PLL_PRIM_POSTDIV2_LSB);

    var pll_reset: u32 = undefined;
    if (pll == sysdef.PLL_USB_BASE) {
        pll_reset = 1 << 13;
    } else {
        pll_reset = 1 << 12;
    }
    syslib.set_w(sysdef.RESETS_RESET, pll_reset);
    syslib.clr_w(sysdef.RESETS_RESET, pll_reset);

    syslib.out_w(pll + sysdef.PLL_CS, refdiv);
    syslib.out_w(pll + sysdef.PLL_FBDIV_INT, fbdiv);

    syslib.clr_w(pll + sysdef.PLL_PWR, (sysdef.PLL_PWR_PD | sysdef.PLL_PWR_VCOPD));
    while ((syslib.in_w(pll + sysdef.PLL_CS) & sysdef.PLL_CS_LOCK) == 0) {}

    syslib.out_w(pll + sysdef.PLL_PRIM, pdiv);
    syslib.clr_w(pll + sysdef.PLL_PWR, sysdef.PLL_PWR_POSTDIVPD);
}

// 周辺クロックの設定
fn clock_config(clock_kind: usize, auxsrc: u32, src_freq: u32, freq: u32) void {
    if (freq > src_freq) return;

    var clock: u32 = sysdef.CLOCKS_BASE + (clock_kind * 0xC);

    var div: u32 = @as(u32, @truncate((src_freq << 8) / freq));
    if (div > syslib.in_w(clock + sysdef.CLK_x_DIV)) {
        syslib.out_w(clock + sysdef.CLK_x_DIV, div);
    }
    syslib.clr_w(clock + sysdef.CLK_x_CTRL, sysdef.CLK_CTRL_ENABLE);

    syslib.out_w(clock + sysdef.CLK_x_CTRL, (syslib.in_w(clock + sysdef.CLK_x_CTRL) & sysdef.CLK_SYS_CTRL_AUXSRC) | (auxsrc << 5));
    syslib.set_w(clock + sysdef.CLK_x_CTRL, sysdef.CLK_CTRL_ENABLE);
    syslib.out_w(clock + sysdef.CLK_x_DIV, div);
}

// クロックの初期化
fn init_clock() void {
    syslib.out_w(sysdef.CLK_SYS_RESUS_CTRL, 0);

    // XOSCの設定
    syslib.out_w(sysdef.XOSC_CTRL, sysdef.XOSC_CTRL_FRANG_1_15MHZ);
    syslib.out_w(sysdef.XOSC_STARTUP, XOSC_STARTUP_DELAY);
    syslib.set_w(sysdef.XOSC_CTRL, sysdef.XOSC_CTRL_ENABLE);
    while ((syslib.in_w(sysdef.XOSC_STATUS) & sysdef.XOSC_STATUS_STABLE) == 0) {}

    syslib.clr_w(sysdef.CLK_SYS + sysdef.CLK_x_CTRL, sysdef.CLK_SYS_CTRL_SRC);
    while (syslib.in_w(sysdef.CLK_SYS + sysdef.CLK_x_SELECTED) != 0x1) {}
    syslib.clr_w(sysdef.CLK_REF + sysdef.CLK_x_CTRL, sysdef.CLK_REF_CTRL_SRC);
    while (syslib.in_w(sysdef.CLK_REF + sysdef.CLK_x_SELECTED) != 0x1) {}

    // PLLの設定
    // PLL SYS 125MHz
    init_pll(sysdef.PLL_SYS_BASE, 1, 1500 * sysdef.MHz, 6, 2);
    // PLL USB 48MHz
    init_pll(sysdef.PLL_USB_BASE, 1, 480 * sysdef.MHz, 5, 2);

    // CLK_REFの設定
    var div: u32 = @as(u32, @truncate((12 * sysdef.MHz << 8) / (12 * sysdef.MHz)));
    if (div > syslib.in_w(sysdef.CLK_REF + sysdef.CLK_x_DIV)) {
        syslib.out_w(sysdef.CLK_REF + sysdef.CLK_x_DIV, div);
    }
    syslib.clr_w(sysdef.CLK_REF + sysdef.CLK_x_CTRL, sysdef.CLK_CTRL_ENABLE);
    syslib.out_w(sysdef.CLK_REF + sysdef.CLK_x_CTRL, (syslib.in_w(sysdef.CLK_REF + sysdef.CLK_x_CTRL) & sysdef.CLK_SYS_CTRL_AUXSRC));
    syslib.out_w(sysdef.CLK_REF + sysdef.CLK_x_CTRL, (syslib.in_w(sysdef.CLK_REF + sysdef.CLK_x_CTRL) & sysdef.CLK_REF_CTRL_SRC) | 2);
    while ((syslib.in_w(sysdef.CLK_REF + sysdef.CLK_x_SELECTED) & (1 << 2)) == 0) {}

    syslib.set_w(sysdef.CLK_REF + sysdef.CLK_x_CTRL, sysdef.CLK_CTRL_ENABLE);
    syslib.out_w(sysdef.CLK_REF + sysdef.CLK_x_DIV, div);

    // CLK_SYSの設定
    div = @as(u32, @truncate(((125 * sysdef.MHz) << 8) / (125 * sysdef.MHz)));
    if (div > syslib.in_w(sysdef.CLK_SYS + sysdef.CLK_x_DIV)) {
        syslib.out_w(sysdef.CLK_SYS + sysdef.CLK_x_DIV, div);
    }
    syslib.clr_w(sysdef.CLK_SYS + sysdef.CLK_x_CTRL, sysdef.CLK_REF_CTRL_SRC);
    while ((syslib.in_w(sysdef.CLK_SYS + sysdef.CLK_x_SELECTED) & 0x1) == 0) {}

    syslib.out_w(sysdef.CLK_SYS + sysdef.CLK_x_CTRL, (syslib.in_w(sysdef.CLK_SYS + sysdef.CLK_x_CTRL) & sysdef.CLK_SYS_CTRL_AUXSRC));
    syslib.out_w(sysdef.CLK_SYS + sysdef.CLK_x_CTRL, (syslib.in_w(sysdef.CLK_SYS + sysdef.CLK_x_CTRL) & sysdef.CLK_REF_CTRL_SRC) | 1);
    while ((syslib.in_w(sysdef.CLK_SYS + sysdef.CLK_x_SELECTED) & (1 << 1)) == 0) {}

    syslib.set_w(sysdef.CLK_SYS + sysdef.CLK_x_CTRL, sysdef.CLK_CTRL_ENABLE);
    syslib.out_w(sysdef.CLK_SYS + sysdef.CLK_x_DIV, div);

    // CLK_USBの設定
    clock_config(sysdef.CLK_KIND_USB, 0, 48 * sysdef.MHz, 48 * sysdef.MHz);
    // CLK_ADCの設定
    clock_config(sysdef.CLK_KIND_ADC, 0, 48 * sysdef.MHz, 48 * sysdef.MHz);
    // CLK_RTCの設定
    clock_config(sysdef.CLK_KIND_RTC, 0, 48 * sysdef.MHz, 46875);
    // CLK_PERIの設定
    clock_config(sysdef.CLK_KIND_PERI, 0, 125 * sysdef.MHz, 125 * sysdef.MHz);
}

// ペリフェラルの有効化
fn init_peri() void {
    // GPIOの有効化
    syslib.clr_w(sysdef.RESETS_RESET, 1 << 5);
    while ((syslib.in_w(sysdef.RESETS_RESET_DONE) & (1 << 5)) == 0) {}

    syslib.clr_w(sysdef.RESETS_RESET, 1 << 8);
    while ((syslib.in_w(sysdef.RESETS_RESET_DONE) & (1 << 8)) == 0) {}

    // UART0の有効化
    syslib.clr_w(sysdef.RESETS_RESET, 1 << 22);
    while ((syslib.in_w(sysdef.RESETS_RESET_DONE) & (1 << 22)) == 0) {}

    // 端子設定

    // P25端子=Picoボード上のLED
    // P25端子出力無効
    syslib.out_w(sysdef.GPIO_OE_CLR, (1 << 25));
    // P25端子出力クリア
    syslib.out_w(sysdef.GPIO_OUT_CLR, (1 << 25));
    // P25端子 SIO
    syslib.out_w(sysdef.GPIO_CTRL(25), 5);
    // P25端子出力有効
    syslib.out_w(sysdef.GPIO_OE_SET, (1 << 25));

    // P0端子 UART0-TX
    syslib.out_w(sysdef.GPIO_CTRL(0), 2);
    // P1端子 UART0-RX
    syslib.out_w(sysdef.GPIO_CTRL(1), 2);
}

// メモリ・セクションの初期化
fn init_section() void {
    // dataセクション初期化
    {
        const src = @as([*]u8, @ptrCast(&__data_org));
        const top = @as([*]u8, @ptrCast(&__data_start));
        const end = @as([*]u8, @ptrCast(&__data_end));
        const len = @intFromPtr(end) - @intFromPtr(top);

        @memcpy(top[0..len], src[0..len]);
    }

    // bssセクション初期化
    {
        const top = @as([*]u8, @ptrCast(&__bss_start));
        const end = @as([*]u8, @ptrCast(&__bss_end));
        const len = @intFromPtr(end) - @intFromPtr(top);
        @memset(top[0..len], 0);
    }
}

// システムタイマの初期化
fn init_system() void {
    // SysTick動作停止
    syslib.out_w(sysdef.SYST_CSR, sysdef.SYST_CSR_CLKSOURCE | sysdef.SYST_CSR_TICKINT);
    // リロード値設定
    syslib.out_w(sysdef.SYST_RVR, (sysdef.TIMER_PERIOD * sysdef.TMCLK_KHz) - 1);
    // カウント値設定
    syslib.out_w(sysdef.SYST_CVR, (sysdef.TIMER_PERIOD * sysdef.TMCLK_KHz) - 1);
    // SysTick動作開始
    syslib.out_w(sysdef.SYST_CSR, sysdef.SYST_CSR_CLKSOURCE | sysdef.SYST_CSR_TICKINT | sysdef.SYST_CSR_ENABLE);
}

// リセットハンドラ
pub fn reset_handler() callconv(.C) void {
    var intsts = syslib.DI();

    syslib.out_w(sysdef.SCB_SHPR3, (sysdef.INTLEVEL_0 << 24) | (sysdef.INTLEVEL_3 << 16));

    // クロック初期化
    init_clock();
    // ペリフェラル初期化
    init_peri();
    // メモリ初期化
    init_section();
    // システムタイマ初期化
    init_system();

    syslib.EI(intsts);

    main();

    while (true) {}
}
