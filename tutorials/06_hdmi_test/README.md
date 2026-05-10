# HDMI Pattern Generator with AXI4-Lite Control

HDMI test pattern generator with AXI4-Lite bus control for EBAZ4205 (Zynq-7010).
Timing presets and test patterns can be dynamically switched from the PS (Processing System) via the AXI bus.

## Features

- **AXI4-Lite slave interface** for register control from PS
- **3 timing presets** with dynamic switching
  - VGA 640x480 @60Hz (pixel clock 25.179 MHz)
  - 480p 720x480 @60Hz (pixel clock 27.000 MHz)
  - 720p 1280x720 @60Hz (pixel clock 74.250 MHz)
- **10 test patterns** with dynamic switching
  - 0: Color bars (8 vertical bars)
  - 1: Checkerboard (32x32 pixel grid)
  - 2: Horizontal gradation
  - 3: Crosshatch (64px grid)
  - 4: Border (1px white frame)
  - 5: RGB full field (cycles R/G/B/W per frame)
  - 6: Vertical gradation
  - 7: Walking bar (animation)
  - 8: SMPTE color bars (75% + PLUGE)
  - 9: Zone plate (concentric circles)
- **MMCM DRP (Dynamic Reconfiguration Port)** for runtime clock switching
- **VSync-synchronized register update** for tear-free switching
- **Clock domain crossing** with safe double-FF synchronization
- **Digilent rgb2dvi IP** (external SerialClk mode) for TMDS/HDMI signal generation

## Target Board

| Item | Specification |
|------|---------------|
| Board | EBAZ4205 |
| FPGA | Xilinx Zynq-7010 (XC7Z010) |
| System Clock | 100 MHz (PS FCLK_CLK1) |
| Reset | Active Low (PS FCLK_RESET1_N) |
| HDMI Output | TMDS differential pairs (DATA x3 + CLK x1) |

## Directory Structure

```text
hdmi_axi_src/
├── vivado/
│   ├── src/                     # RTL source code
│   │   ├── README.md
│   │   ├── README_JP.md         # Japanese version
│   │   ├── constraints/
│   │   │   └── pattern_hdmi_axi.xdc    # Pin / clock constraints
│   │   ├── ip/
│   │   │   ├── rgb2dvi/             # Digilent rgb2dvi IP (VHDL)
│   │   │   │   └── src/
│   │   │   │       ├── rgb2dvi.vhd
│   │   │   │       ├── ClockGen.vhd
│   │   │   │       ├── DVI_Constants.vhd
│   │   │   │       ├── OutputSERDES.vhd
│   │   │   │       ├── SyncAsync.vhd
│   │   │   │       ├── SyncAsyncReset.vhd
│   │   │   │       └── TMDS_Encoder.vhd
│   │   │   └── mmcm_drp/            # Xilinx mmcm_drp DRP controller
│   │   │       ├── mmcm_drp.v
│   │   │       └── mmcm_pll_drp_func_7s_mmcm.vh
│   │   └── rtl/
│   │       ├── pattern_hdmi_axi.v   # Top module
│   │       ├── axi_hdmi_ctrl.v      # AXI4-Lite register block
│   │       ├── pattern_multi.v      # Test pattern generator
│   │       ├── syncgen_multi.v      # Sync signal generator
│   │       ├── pckgen_triple.v      # Triple pixel clock generator
│   │       └── pckgen_dual.v        # (Legacy: for reference)
│   └── drp/                     # DRP related files
└── vitis_src/                   # Vitis software source
    ├── hdmi_axi.h
    ├── hdmi_axi.c
    ├── main.c
    └── README.txt
```

## Module Hierarchy

```text
pattern_hdmi_axi (top)
├── axi_hdmi_ctrl            AXI4-Lite register control + CDC + reconfig request
├── pattern_multi            Test pattern generation
│   └── syncgen_multi        Sync signal generation (H/V counters, HSYNC, VSYNC)
│       └── pckgen_triple    Pixel clock + 5x clock generator (MMCM DRP)
└── rgb2dvi                  RGB to TMDS/HDMI conversion (external SerialClk mode)
```

## AXI4-Lite Register Map

Base address depends on Vivado Block Design assignment.

### 0x00: Control Register (R/W)

| Bits | Field | Description |
|------|-------|-------------|
| [1:0] | `timing_sel` | Timing preset: 0 = VGA 640x480, 1 = 480p 720x480, 2 = 720p 1280x720 |
| [5:2] | `pattern_sel` | Test pattern select (0..9) |
| [31:6] | - | Reserved (read as 0) |

Writing a new `timing_sel` value automatically triggers MMCM DRP reconfiguration.
The `reconfig_busy` bit in the Status Register becomes 1 during reconfiguration and returns to 0 when complete.

### 0x04: Status Register (R)

| Bits | Field | Description |
|------|-------|-------------|
| [0] | `locked` | MMCM lock status: 1 = locked |
| [1] | `reconfig_busy` | MMCM reconfiguration in progress: 1 = busy |
| [31:2] | - | Reserved (read as 0) |

## Timing Preset Details

### VGA 640x480 @60Hz (`timing_sel = 0`)

| Parameter | Value |
|-----------|-------|
| Pixel Clock | 25.179 MHz (target 25.175 MHz, error +0.02%) |
| 5x SerialClk | 125.893 MHz |
| Horizontal Period | 800 pixels (active 640 + front 16 + sync 96 + back 48) |
| Vertical Period | 525 lines (active 480 + front 10 + sync 2 + back 33) |
| Sync Polarity | Active-low |

### 480p 720x480 @60Hz (`timing_sel = 1`)

| Parameter | Value |
|-----------|-------|
| Pixel Clock | 27.000 MHz |
| 5x SerialClk | 135.000 MHz |
| Horizontal Period | 858 pixels (active 720 + front 16 + sync 62 + back 60) |
| Vertical Period | 525 lines (active 480 + front 9 + sync 6 + back 30) |
| Sync Polarity | Active-low |

### 720p 1280x720 @60Hz (`timing_sel = 2`)

| Parameter | Value |
|-----------|-------|
| Pixel Clock | 74.250 MHz |
| 5x SerialClk | 371.250 MHz |
| Horizontal Period | 1650 pixels (active 1280 + front 110 + sync 40 + back 220) |
| Vertical Period | 750 lines (active 720 + front 5 + sync 5 + back 20) |
| Sync Polarity | Active-high (per CEA-861) |

## MMCM DRP Reconfiguration

The `pckgen_triple` module uses the Xilinx `mmcm_drp` module (from Clocking Wizard IP) to perform DRP-based runtime clock switching.

Reconfiguration timing:

```
AXI Write (timing_sel change)
         |
         v
    +----+----+
    | axi_hdmi_ctrl | reconfig_req pulse (1 S_AXI_ACLK cycle)
    +----+----+
         |
         v
    +----+----+
    | pckgen_triple | timing_sel_imm -> S2 parameter
    +----+----+
         |
         v
    +----+----+
    | mmcm_drp | DRP Read-Modify-Write sequence
    +----+----+
         |
         v
    MMCME2_ADV register update
         |
         v
    PLL relock (tLOCK ~100us-1ms)
         |
         v
    SRDY pulse
         |
         v
    reconfig_done
```

## Vivado Design Notes

### rgb2dvi IP Configuration

```verilog
rgb2dvi #(
    .kGenerateSerialClk("FALSE"),  // External SerialClk (5x)
    .kRstActiveHigh("TRUE")
) rgb2dvi_inst ( ... );
```

**IMPORTANT**: The `kGenerateSerialClk` generic must be set to `"FALSE"` to disable the internal PLL and use the external `SerialClk` input. This prevents the `[DRC PDRC-43] PLL_adv_ClkFrequency_div_no_dclk` error during bitstream generation.

### X_INTERFACE Constraints

```verilog
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 HDMI_CLK_N CLK" *)
(* X_INTERFACE_PARAMETER = "FREQ_HZ 25175000, POLARITY ACTIVE_HIGH" *)
output HDMI_CLK_N, HDMI_CLK_P,
```

The `FREQ_HZ` parameter is required to suppress `[IP_Flow 19-4751]` warnings. This is a representative value (VGA mode); actual frequency changes with timing preset.

## C Example (Register Access)

```c
#include "xil_io.h"

#define HDMI_CTRL_BASE 0x43C00000  // Depends on Block Design

// Select 720p timing + SMPTE color bars pattern
Xil_Out32(HDMI_CTRL_BASE, 0x00000022);  // timing_sel=2, pattern_sel=8

// Wait for MMCM reconfiguration complete
while (Xil_In32(HDMI_CTRL_BASE + 0x04) & 0x02) {
    // polling reconfig_busy
}

// Check lock status
if (Xil_In32(HDMI_CTRL_BASE + 0x04) & 0x01) {
    // MMCM locked, output active
}
```

## References

- [EBAZ4205 Hardware Reference](https://github.com/xjtuecho/EBAZ4205)
- [Digilent rgb2dvi IP](https://github.com/Digilent/vivado-library)
- [Xilinx 7 Series Clocking Resources (UG472)](https://docs.xilinx.com/v/u/en-US/ug472_7series_clocking)
- [Xilinx Clocking Wizard LogiCORE IP (PG065)](https://docs.xilinx.com/v/u/en-US/pg065-clk-wiz)

## License

This project is provided as-is for educational and hobbyist purposes.
