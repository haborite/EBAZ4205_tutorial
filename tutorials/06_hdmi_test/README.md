# HDMI AXI Control Project

AXI4-Lite controlled HDMI pattern generator for EBAZ4205 board.

## Features

- **Dual timing presets**: VGA 640x480@60Hz / 480p 720x480@60Hz
- **Three test patterns**: Color bars / Checkerboard / Gradation
- **AXI4-Lite control**: Register-based configuration from PS
- **VSync-synchronized updates**: Tear-free pattern/timing switching
- **Dual MMCM architecture**: Glitch-free pixel clock switching

## Project Structure

```
06_hdmi_test/
├── hdmi_axi_src/           # Source files for independent project creation
│   ├── rtl/                # RTL modules
│   │   ├── pckgen_dual.v
│   │   ├── syncgen_multi.v
│   │   ├── pattern_multi.v
│   │   ├── axi_hdmi_ctrl.v
│   │   └── pattern_hdmi_axi.v
│   ├── ip/                 # IP sources
│   │   └── rgb2dvi/        # rgb2dvi IP (VHDL)
│   └── constraints/        # Constraint files
│       └── pattern_hdmi_axi.xdc
├── create_vivado_project.tcl  # Automated project creation script
├── create_bd.tcl           # Block Design creation script
├── README.md               # This file (English)
└── README_JP.md            # Japanese version
```

## Hardware Architecture

### RTL Modules

- `pattern_hdmi_axi.v` - Top-level AXI wrapper
- `axi_hdmi_ctrl.v` - AXI4-Lite register block with clock domain crossing
- `pattern_multi.v` - Multi-pattern test signal generator
- `syncgen_multi.v` - Multi-preset sync signal generator
- `pckgen_dual.v` - Dual MMCM pixel clock generator

### Block Design

- Zynq PS (processing_system7)
- AXI Interconnect
- pattern_hdmi_axi (custom RTL)

## Register Map

Base address: `0x43C00000` (AXI4-Lite, 4KB range)

### Register Summary

| Offset | Name | Access | Description |
|--------|------|--------|-------------|
| 0x00 | CTRL | R/W | Control register (timing_sel, pattern_sel) |
| 0x04 | STATUS | R | Status register (MMCM lock) |
| 0x08-0xFFF | - | - | Reserved |

### Control Register (0x00) - R/W

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 0 | timing_sel | R/W | 0 | Timing preset selection<br>0 = VGA 640x480@60Hz (25.175 MHz)<br>1 = 480p 720x480@60Hz (27 MHz) |
| 2:1 | pattern_sel | R/W | 00 | Test pattern selection<br>00 = Color bars (8 colors)<br>01 = Checkerboard (32x32 pixels)<br>10 = Gradation (horizontal)<br>11 = Reserved |
| 31:3 | Reserved | R | 0 | Reserved, read as 0 |

**Notes:**
- Register updates are synchronized to pixel clock domain
- Changes take effect at next VSync boundary (tear-free switching)
- Both MMCMs must be locked before valid output

### Status Register (0x04) - Read-only

| Bit | Field | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 0 | locked | R | 0 | MMCM lock status<br>0 = Not locked (no valid output)<br>1 = Both MMCMs locked (valid output) |
| 31:1 | Reserved | R | 0 | Reserved, read as 0 |

**Notes:**
- Check this register after power-on or reset
- Both VGA and 480p MMCMs must be locked for proper operation
- Lock time is typically < 10ms after reset release

### Register Access Examples

```c
// Read control register
uint32_t ctrl = CTRL_REG;
uint8_t timing = ctrl & 0x01;
uint8_t pattern = (ctrl >> 1) & 0x03;

// Write control register (VGA, Checkerboard)
CTRL_REG = (1 << 1) | (0 << 0);  // pattern_sel=1, timing_sel=0

// Check MMCM lock status
while (!(STATUS_REG & 0x01)) {
    // Wait for MMCMs to lock
}

// Atomic update (recommended)
uint32_t new_ctrl = (pattern_sel << 1) | timing_sel;
CTRL_REG = new_ctrl;
```

## Usage

### Software Control (C)

```c
#include <stdint.h>

#define HDMI_CTRL_BASE  0x43C00000
#define CTRL_REG        (*(volatile uint32_t*)(HDMI_CTRL_BASE + 0x00))
#define STATUS_REG      (*(volatile uint32_t*)(HDMI_CTRL_BASE + 0x04))

// VGA 640x480, Color bars
CTRL_REG = 0x00;

// VGA 640x480, Checkerboard
CTRL_REG = 0x02;

// VGA 640x480, Gradation
CTRL_REG = 0x04;

// 480p 720x480, Color bars
CTRL_REG = 0x01;

// 480p 720x480, Checkerboard
CTRL_REG = 0x03;

// 480p 720x480, Gradation
CTRL_REG = 0x05;

// Check MMCM lock status
if (STATUS_REG & 0x01) {
    // MMCMs are locked
}
```

### Python Control (via /dev/mem)

```python
import mmap
import struct

HDMI_BASE = 0x43C00000
PAGE_SIZE = 4096

with open('/dev/mem', 'r+b') as f:
    mem = mmap.mmap(f.fileno(), PAGE_SIZE, offset=HDMI_BASE)
    
    # VGA, Color bars
    mem[0:4] = struct.pack('<I', 0x00)
    
    # 480p, Checkerboard
    mem[0:4] = struct.pack('<I', 0x03)
    
    # Read status
    status = struct.unpack('<I', mem[4:8])[0]
    print(f"MMCM locked: {status & 0x01}")
```

## Vivado Setup

### Quick Start: Automated Project Creation

Run the provided Tcl script to create a complete Vivado project:

```bash
cd tutorials/06_hdmi_test
vivado -mode batch -source create_vivado_project.tcl
```

Or in Vivado Tcl Console:
```tcl
cd tutorials/06_hdmi_test
source create_vivado_project.tcl
```

This script will:
- Create new Vivado project (`vivado_project/hdmi_axi_project.xpr`)
- Add all RTL files (pckgen_dual, syncgen_multi, pattern_multi, axi_hdmi_ctrl, pattern_hdmi_axi)
- Add rgb2dvi IP sources
- Create Block Design with Zynq PS and AXI connections
- Add constraints file
- Assign AXI address (0x43C00000)
- Create HDL wrapper

After script completion, open the project in Vivado GUI and proceed with synthesis/implementation.

### Manual Setup (Alternative)

If you prefer manual setup:

#### 1. Add RTL Files

Add the following files to your Vivado project:
- `pckgen_dual.v`
- `syncgen_multi.v`
- `pattern_multi.v`
- `axi_hdmi_ctrl.v`
- `pattern_hdmi_axi.v`
- rgb2dvi sources (VHDL files)

#### 2. Create Block Design

Run the Block Design creation script:
```tcl
source create_bd.tcl
```

Or manually:
1. Create new Block Design
2. Add Zynq PS IP
3. Add `pattern_hdmi_axi` as module reference
4. Connect PS M_AXI_GP0 to pattern_hdmi_axi S_AXI via AXI Interconnect
5. Assign address: 0x43C00000, range 4K
6. Make external: CLK, RST, HDMI_CLK_N/P, HDMI_N/P

#### 3. Add Constraints

Use the provided `pattern_hdmi_axi.xdc` constraint file.

#### 4. Generate Bitstream

1. Generate Block Design
2. Create HDL wrapper
3. Run Synthesis
4. Run Implementation
5. Generate Bitstream

## Timing Details

### VGA 640x480@60Hz
- Pixel clock: 25.175 MHz
- H: 640 + 16 (front) + 96 (sync) + 48 (back) = 800 total
- V: 480 + 10 (front) + 2 (sync) + 33 (back) = 525 total

### 480p 720x480@60Hz
- Pixel clock: 27.000 MHz
- H: 720 + 16 (front) + 62 (sync) + 60 (back) = 858 total
- V: 480 + 9 (front) + 6 (sync) + 30 (back) = 525 total

## Pattern Descriptions

### Color Bars (pattern_sel=0)
8 vertical bars: White, Yellow, Cyan, Green, Magenta, Red, Blue, Black

### Checkerboard (pattern_sel=1)
32x32 pixel black and white squares

### Gradation (pattern_sel=2)
Horizontal grayscale gradient from black to white

## Notes

- Register updates are synchronized to VSync to prevent tearing
- Both MMCMs must be locked before valid output
- Pixel clock switching uses BUFGMUX for glitch-free operation
- rgb2dvi IP supports 25-30 MHz pixel clock range (both presets fit)

## Troubleshooting

**No display output**
- Check MMCM lock status via STATUS_REG
- Verify HDMI cable connection
- Check CLK input (33.333 MHz)

**Tearing/artifacts when switching**
- Normal during mode switch (1-2 frames)
- If persistent, check VSync signal integrity

**Wrong colors**
- Verify rgb2dvi IP configuration
- Check HDMI_N/P pin assignments
