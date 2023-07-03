pub const SRAM_START: u32 = 0x2000_0000;
pub const SRAM_SIZE: u32 = 256 * 1024;
pub const INITIAL_SP: u32 = SRAM_START + SRAM_SIZE;

// APBペリフェラル
// Clocks
pub const CLOCKS_BASE = 0x4000_8000;
pub const CLK_GPOUT0 = CLOCKS_BASE + 0x00;
pub const CLK_GPOUT1 = CLOCKS_BASE + 0x0C;
pub const CLK_GPOUT2 = CLOCKS_BASE + 0x18;
pub const CLK_GPOUT3 = CLOCKS_BASE + 0x24;
pub const CLK_REF = CLOCKS_BASE + 0x30;
pub const CLK_SYS = CLOCKS_BASE + 0x3C;
pub const CLK_PERI = CLOCKS_BASE + 0x48;
pub const CLK_USB = CLOCKS_BASE + 0x54;
pub const CLK_ADC = CLOCKS_BASE + 0x60;
pub const CLK_RTC = CLOCKS_BASE + 0x6C;
pub const CLK_SYS_RESUS_CTRL = CLOCKS_BASE + 0x78;
pub const CLK_RESUS_STATUS = CLOCKS_BASE + 0x7C;

pub const CLK_x_CTRL = 0x00;
pub const CLK_x_DIV = 0x04;
pub const CLK_x_SELECTED = 0x08;

pub const CLK_SYS_CTRL_AUXSRC = 0x0000_00e0;
pub const CLK_SYS_CTRL_SRC = 0x0000_0001;
pub const CLK_REF_CTRL_SRC = 0x0000_0003;
pub const CLK_CTRL_ENABLE = 0x0000_0800;

pub const CLK_SYS_CTRL_SRC_AUX = 0x1;

pub const CLK_KIND_GPOUT0 = 0;
pub const CLK_KIND_GPOUT1 = 1;
pub const CLK_KIND_GPOUT2 = 2;
pub const CLK_KIND_GPOUT3 = 3;
pub const CLK_KIND_REF = 4;
pub const CLK_KIND_SYS = 5;
pub const CLK_KIND_PERI = 6;
pub const CLK_KIND_USB = 7;
pub const CLK_KIND_ADC = 8;
pub const CLK_KIND_RTC = 9;

// Reset Controller
pub const RESETS_BASE = 0x4000_C000;
pub const RESETS_RESET = RESETS_BASE + 0x00;
pub const RESETS_WDSEL = RESETS_BASE + 0x04;
pub const RESETS_RESET_DONE = RESETS_BASE + 0x08;
pub const RESETS_RESET_ADC = 0x0000_0001;
pub const RESETS_RESET_I2C0 = 0x0000_0008;
pub const RESETS_RESET_I2C1 = 0x0000_0010;

// GPIO
pub const IO_BANK0_BASE = 0x4001_4000;
pub fn GPIO_CTRL(n: u32) u32 {
    return IO_BANK0_BASE + 0x04 + (n * 8);
}

pub const GPIO_CTRL_FUNCSEL_I2C = 3;
pub const GPIO_CTRL_FUNCSEL_NULL = 31;

pub const PADS_BANK0_BASE = 0x4001_C000;
pub fn GPIO(n: u32) u32 {
    return PADS_BANK0_BASE + 0x4 + (n * 4);
}

pub const GPIO_OD = 1 << 7;
pub const GPIO_IE = 1 << 6;
pub const GPIO_DRIVE_2MA = 0 << 4;
pub const GPIO_DRIVE_4MA = 1 << 4;
pub const GPIO_DRIVE_8MA = 2 << 4;
pub const GPIO_DRIVE_12MA = 3 << 4;
pub const GPIO_PUE = 1 << 3;
pub const GPIO_PDE = 1 << 2;
pub const GPIO_SHEMITT = 1 << 1;
pub const GPIO_SLEWDAST = 1 << 0;

// Crystal Oscillator(XOSC)
pub const XOSC_BASE = 0x4002_4000;
pub const XOSC_CTRL = XOSC_BASE + 0x00;
pub const XOSC_STATUS = XOSC_BASE + 0x04;
pub const XOSC_STARTUP = XOSC_BASE + 0x0C;

pub const XOSC_CTRL_ENABLE = 0x00FA_B000;
pub const XOSC_CTRL_DISABLE = 0x00D1_E000;
pub const XOSC_CTRL_FRANG_1_15MHZ = 0x0000_0AA0;
pub const XOSC_STATUS_STABLE = 0x8000_0000;

// PLL
pub const PLL_SYS_BASE = 0x4002_8000;
pub const PLL_USB_BASE = 0x4002_C000;

pub const PLL_CS = 0x00;
pub const PLL_PWR = 0x04;
pub const PLL_FBDIV_INT = 0x08;
pub const PLL_PRIM = 0x0C;

pub const PLL_CS_LOCK = 1 << 31;
pub const PLL_PWR_PD = 1 << 0;
pub const PLL_PWR_VCOPD = 1 << 5;
pub const PLL_PWR_POSTDIVPD = 1 << 3;
pub const PLL_PRIM_POSTDIV1_LSB = 16;
pub const PLL_PRIM_POSTDIV2_LSB = 12;

// UART
pub const UART0_BASE = 0x4003_4000;
pub const UART1_BASE = 0x4003_8000;

pub const UARTx_DR = 0x000;
pub const UARTx_FR = 0x018;
pub const UARTx_IBRD = 0x024;
pub const UARTx_FBRD = 0x028;
pub const UARTx_LCR_H = 0x02C;
pub const UARTx_CR = 0x030;

pub const UART_CR_RXE = 1 << 9;
pub const UART_CR_TXE = 1 << 8;
pub const UART_CR_EN = 1 << 0;
pub const UART_FR_TXFF = 1 << 5;

// IOPORT レジスタ
pub const SIO_BASE = 0xD000_0000;
pub const GPIO_IN = (SIO_BASE + 0x04);
pub const GPIO_OUT = (SIO_BASE + 0x10);
pub const GPIO_OUT_SET = (SIO_BASE + 0x14);
pub const GPIO_OUT_CLR = (SIO_BASE + 0x18);
pub const GPIO_OUT_XOR = (SIO_BASE + 0x1C);
pub const GPIO_OE_SET = (SIO_BASE + 0x24);
pub const GPIO_OE_CLR = (SIO_BASE + 0x28);
pub const GPIO_OE_XOR = (SIO_BASE + 0x2C);

// SysTick レジスタ
pub const SYST_CSR = 0xE000_E010;
pub const SYST_RVR = 0xE000_E014;
pub const SYST_CVR = 0xE000_E018;

pub const SYST_CSR_COUNTFLAG = 1 << 16;
pub const SYST_CSR_CLKSOURCE = 1 << 2;
pub const SYST_CSR_TICKINT = 1 << 1;
pub const SYST_CSR_ENABLE = 1 << 0;

// クロック周波数
pub const CLOCK_XOSC: usize = 1200_0000;
pub const CLOCK_REF = CLOCK_XOSC;

pub const XOSC_MHz = 12;
pub const XOSC_KHz = XOSC_MHz * 1000;

pub const TMCLK_MHz = 125;
pub const TMCLK_KHz = TMCLK_MHz * 1000;
pub const TIMER_PERIOD = 10;

pub const KHz = 1000;
pub const MHz = KHz * 1000;

// NVIC レジスタ
pub const SCB_SHPR3 = 0xE000_ED20;

pub const INTLEVEL_0 = 0x00;
pub const INTLEVEL_1 = 0x40;
pub const INTLEVEL_2 = 0x80;
pub const INTLEVEL_3 = 0xC0;
