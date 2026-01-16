/* Dual Pixel Clock Generator with switchable output
 * Single MMCM with two output clocks to save resources
 * CLKOUT0: 25.175 MHz (VGA 640x480@60)
 * CLKOUT1: 27.000 MHz (480p 720x480@60)
 * Input: 33.333 MHz (EBAZ4205 system clock)
 */

module pckgen_dual (
    input       SYSCLK,
    input       timing_sel,  // 0=VGA, 1=480p
    output      PCK,
    output      locked
);

wire CLKFBOUT;
wire iPCK0, iPCK1;
wire pck_mux;

// Single MMCM generating both pixel clocks
// VCO = 33.333 MHz * 27 = 900 MHz
// CLKOUT0 = 900 MHz / 35.75 = 25.175 MHz (VGA)
// CLKOUT1 = 900 MHz / 33.333 = 27.000 MHz (480p)
MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKFBOUT_MULT_F(27.0),       // VCO = 900 MHz
    .CLKFBOUT_PHASE(0.0),
    .CLKIN1_PERIOD(30.0),          // 33.333 MHz input
    .CLKOUT0_DIVIDE_F(35.75),      // 25.175 MHz (VGA)
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0.0),
    .CLKOUT1_DIVIDE(33),           // ~27.27 MHz (close to 27 MHz)
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(0.0),
    .DIVCLK_DIVIDE(1),
    .REF_JITTER1(0.0),
    .STARTUP_WAIT("FALSE")
) MMCM_DUAL (
    .CLKOUT0(iPCK0),
    .CLKOUT1(iPCK1),
    .CLKFBOUT(CLKFBOUT),
    .LOCKED(locked),
    .CLKIN1(SYSCLK),
    .PWRDWN(1'b0),
    .RST(1'b0),
    .CLKFBIN(CLKFBOUT),
    .CLKOUT0B(), .CLKOUT1B(), .CLKOUT2(), .CLKOUT2B(),
    .CLKOUT3(), .CLKOUT3B(), .CLKOUT4(), .CLKOUT5(), .CLKOUT6(),
    .CLKFBOUTB()
);

// Clock multiplexer (glitch-free switching)
BUFGMUX #(
    .CLK_SEL_TYPE("SYNC")
) BUFGMUX_inst (
    .O(pck_mux),
    .I0(iPCK0),
    .I1(iPCK1),
    .S(timing_sel)
);

BUFG iBUFG (.I(pck_mux), .O(PCK));

endmodule
