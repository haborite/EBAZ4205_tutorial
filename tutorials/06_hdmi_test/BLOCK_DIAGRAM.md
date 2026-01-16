# pattern_hdmi_axi Block Diagram

AXI4-Lite controlled HDMI pattern generator circuit block diagram.

## Overall Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         pattern_hdmi_axi (Top Module)                       │
└─────────────────────────────────────────────────────────────────────────────┘

  ┌──────────────────┐
  │  Zynq PS         │
  │  FCLK_CLK0       │───── S_AXI_ACLK (100 MHz)
  │  FCLK_CLK1       │───── CLK (33.333 MHz)
  │  FCLK_RESET1_N   │───── RST (ACTIVE_LOW) ──┐
  └──────────────────┘                          │
           │                                     │ ~RST_internal
           │ AXI4-Lite                          │ (ACTIVE_HIGH)
           │                                     │
           ↓                                     ↓
  ┌─────────────────────────────────────────────────────────────────┐
  │  axi_hdmi_ctrl                                                  │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │ AXI4-Lite Slave Interface (S_AXI_ACLK domain)            │  │
  │  │ - Register Read/Write                                    │  │
  │  │ - Addr: 0x0 = CTRL_REG (timing_sel, pattern_sel)        │  │
  │  │ - Addr: 0x4 = STATUS_REG (locked)                        │  │
  │  └──────────────────────────────────────────────────────────┘  │
  │                          │                                      │
  │                          ↓ CDC (Clock Domain Crossing)          │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │ Synchronizer (S_AXI_ACLK → PCK domain)                   │  │
  │  │ - timing_sel_reg  → timing_sel_meta  → timing_sel_sync   │  │
  │  │ - pattern_sel_reg → pattern_sel_meta → pattern_sel_sync  │  │
  │  │ - VSync boundary latch (no tearing)                      │  │
  │  └──────────────────────────────────────────────────────────┘  │
  └─────────────────────────────────────────────────────────────────┘
           │                                     │
           │ timing_sel_sync                     │ pattern_sel_sync[1:0]
           │                                     │
           ↓                                     ↓
  ┌─────────────────────────────────────────────────────────────────┐
  │  pattern_multi                                                  │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │ syncgen_multi (Sync Generator)                           │  │
  │  │  ┌────────────────────────────────────────────────────┐  │  │
  │  │  │ pckgen_dual (Pixel Clock Generator)                │  │  │
  │  │  │  ┌──────────────────────────────────────────────┐  │  │  │
  │  │  │  │ MMCM_DUAL (Single MMCM)                      │  │  │  │
  │  │  │  │ - CLKIN1: 33.333 MHz                         │  │  │  │
  │  │  │  │ - VCO: 900 MHz (×27)                         │  │  │  │
  │  │  │  │ - CLKOUT0: 25.175 MHz (÷35.75) [VGA]        │  │  │  │
  │  │  │  │ - CLKOUT1: 27.27 MHz (÷33) [480p]           │  │  │  │
  │  │  │  └──────────────────────────────────────────────┘  │  │  │
  │  │  │         │ iPCK0          │ iPCK1                    │  │  │
  │  │  │         └────────┬───────┘                          │  │  │
  │  │  │                  ↓                                   │  │  │
  │  │  │         ┌────────────────┐                          │  │  │
  │  │  │         │ BUFGMUX        │ ← timing_sel             │  │  │
  │  │  │         │ (Glitch-free)  │                          │  │  │
  │  │  │         └────────┬───────┘                          │  │  │
  │  │  │                  ↓                                   │  │  │
  │  │  │         ┌────────────────┐                          │  │  │
  │  │  │         │ BUFG (iBUFG)   │                          │  │  │
  │  │  │         └────────┬───────┘                          │  │  │
  │  │  │                  │ PCK                               │  │  │
  │  │  └──────────────────┼───────────────────────────────────┘  │  │
  │  │                     │                                      │  │
  │  │  ┌──────────────────┼───────────────────────────────────┐  │  │
  │  │  │ Timing Generator │                                   │  │  │
  │  │  │ - VGA 640x480@60  (timing_sel=0)                    │  │  │
  │  │  │ - 480p 720x480@60 (timing_sel=1)                    │  │  │
  │  │  │ → H_SYNC, V_SYNC, H_CNT, V_CNT, DE                  │  │  │
  │  │  └──────────────────┬───────────────────────────────────┘  │  │
  │  └─────────────────────┼──────────────────────────────────────┘  │
  │                        │ H_CNT, V_CNT, timing_sel                │
  │                        ↓                                         │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │ Pattern Generator (pattern_sel[1:0])                     │  │
  │  │ - 2'b00: Color Bars (8 vertical bars)                    │  │
  │  │ - 2'b01: Checkerboard (64x64 pixel blocks)               │  │
  │  │ - 2'b10: Gradation (horizontal gradient)                 │  │
  │  │ → VGA_R[7:0], VGA_G[7:0], VGA_B[7:0]                     │  │
  │  └──────────────────────────────────────────────────────────┘  │
  └─────────────────────────────────────────────────────────────────┘
           │ PCK, VGA_R/G/B[7:0], VGA_HS, VGA_VS, VGA_DE
           │
           ↓
  ┌─────────────────────────────────────────────────────────────────┐
  │  rgb2dvi (Digilent RGB to DVI/HDMI Encoder IP)                 │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │ MMCM (PixelClk × 5 = SerialClk)                          │  │
  │  │ - VGA:  25.175 MHz × 5 = 125.875 MHz                     │  │
  │  │ - 480p: 27.27 MHz × 5 = 136.36 MHz                       │  │
  │  └──────────────────────────────────────────────────────────┘  │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │ TMDS Encoder (8b/10b encoding)                           │  │
  │  │ - RGB data → TMDS encoded data                           │  │
  │  │ - Control signals (HS, VS) encoding                      │  │
  │  └──────────────────────────────────────────────────────────┘  │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │ OSERDESE2 (Parallel to Serial)                           │  │
  │  │ - 10-bit parallel → 1-bit serial (DDR)                   │  │
  │  │ - 4 channels: CLK + R + G + B                            │  │
  │  └──────────────────────────────────────────────────────────┘  │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │ OBUFDS (Differential Output Buffer)                      │  │
  │  │ - Single-ended → Differential TMDS                       │  │
  │  └──────────────────────────────────────────────────────────┘  │
  └─────────────────────────────────────────────────────────────────┘
           │
           ↓
  ┌─────────────────────────────────────────────────────────────────┐
  │  HDMI Output (TMDS Differential Pairs)                          │
  │  - HDMI_CLK_P/N  (Clock channel)                                │
  │  - HDMI_P[2:0]/N[2:0]  (Data channels: R, G, B)                 │
  └─────────────────────────────────────────────────────────────────┘
```

## Clock Domains

| Clock Domain | Frequency | Source | Purpose |
|--------------|-----------|--------|---------|
| **S_AXI_ACLK** | 100 MHz | PS FCLK_CLK0 | AXI register access |
| **CLK** | 33.333 MHz | PS FCLK_CLK1 | MMCM input clock |
| **PCK** | 25.175 MHz (VGA)<br>27.27 MHz (480p) | pckgen_dual MMCM output | Pixel clock |
| **SerialClk** | 125.875 MHz (VGA)<br>136.36 MHz (480p) | rgb2dvi MMCM (PCK × 5) | TMDS serial clock |

## Signal Flow

1. **PS writes timing_sel/pattern_sel via AXI4-Lite**
   - CPU accesses registers at 0x43C00000 (default base address)
   - CTRL_REG (0x0): timing_sel[0], pattern_sel[1:0]
   - STATUS_REG (0x4): locked (read-only)

2. **CDC synchronizer transfers to PCK domain (VSync boundary)**
   - Two-stage synchronizer prevents metastability
   - VSync boundary latch prevents screen tearing
   - Ensures glitch-free mode switching

3. **pckgen_dual generates appropriate pixel clock (VGA or 480p)**
   - Single MMCM with two output clocks (resource efficient)
   - BUFGMUX provides glitch-free clock switching
   - CLKOUT0: 25.175 MHz for VGA 640x480@60
   - CLKOUT1: 27.27 MHz for 480p 720x480@60

4. **syncgen_multi generates H/V sync signals**
   - Timing parameters switch based on timing_sel
   - Generates H_SYNC, V_SYNC, H_CNT, V_CNT, DE signals
   - Supports two presets: VGA and 480p

5. **Pattern generator creates RGB pixel data**
   - Three test patterns selectable via pattern_sel
   - Color Bars: 8 vertical bars (White, Yellow, Cyan, Green, Magenta, Red, Blue, Black)
   - Checkerboard: 64×64 pixel alternating blocks
   - Gradation: Horizontal RGB gradient

6. **rgb2dvi encodes to TMDS and outputs differential HDMI signals**
   - Internal MMCM multiplies pixel clock by 5
   - TMDS encoder performs 8b/10b encoding
   - OSERDESE2 serializes 10-bit parallel to DDR serial
   - OBUFDS outputs differential TMDS pairs

## Module Hierarchy

```
pattern_hdmi_axi (top)
├── axi_hdmi_ctrl
│   ├── AXI4-Lite slave interface
│   ├── Register bank (CTRL_REG, STATUS_REG)
│   └── CDC synchronizer (S_AXI_ACLK → PCK)
├── pattern_multi
│   ├── syncgen_multi
│   │   ├── pckgen_dual
│   │   │   ├── MMCM_DUAL (MMCME2_BASE)
│   │   │   ├── BUFGMUX (clock mux)
│   │   │   └── BUFG (global buffer)
│   │   └── Timing generator (VGA/480p presets)
│   └── Pattern generator (Color bars/Checkerboard/Gradation)
└── rgb2dvi (Digilent IP)
    ├── MMCM (PixelClk × 5)
    ├── TMDS encoder
    ├── OSERDESE2 (serializer)
    └── OBUFDS (differential output)
```

## Key Features

- **AXI4-Lite control**: CPU can dynamically switch timing and pattern
- **Dual timing presets**: VGA 640×480@60 and 480p 720×480@60
- **Three test patterns**: Color bars, Checkerboard, Gradation
- **VSync-synchronized updates**: No screen tearing during mode switching
- **Resource efficient**: Single MMCM for dual pixel clocks
- **Glitch-free clock switching**: BUFGMUX ensures clean transitions

## Timing Constraints

The design uses the following timing constraints (see `pattern_hdmi_axi.xdc`):

1. **CDC synchronizer paths**: `set_false_path` for metastability registers
2. **Logically exclusive clocks**: VGA and 480p clocks are mutually exclusive
3. **False paths between mismatched modes**: Prevents timing analysis across inactive clock domains

## Register Map

| Address | Name | Bits | Access | Description |
|---------|------|------|--------|-------------|
| 0x0 | CTRL_REG | [0] | R/W | timing_sel: 0=VGA, 1=480p |
| 0x0 | CTRL_REG | [2:1] | R/W | pattern_sel: 00=Color bars, 01=Checkerboard, 10=Gradation |
| 0x4 | STATUS_REG | [0] | RO | locked: MMCM lock status |
