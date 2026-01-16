/* Multi-preset sync signal generator with timing_sel control
 * Preset 0: VGA 640x480@60
 * Preset 1: 480p 720x480@60
 */

module syncgen_multi(
    input               CLK,
    input               RST,
    input               timing_sel,  // 0=VGA, 1=480p
    output              PCK,
    output              locked,
    output  reg         VGA_HS,
    output  reg         VGA_VS,
    output  reg [9:0]   HCNT,
    output  reg [9:0]   VCNT
);

// Timing parameters for VGA 640x480@60
localparam VGA_HPERIOD = 10'd800;
localparam VGA_HFRONT  = 10'd16;
localparam VGA_HWIDTH  = 10'd96;
localparam VGA_HBACK   = 10'd48;
localparam VGA_VPERIOD = 10'd525;
localparam VGA_VFRONT  = 10'd10;
localparam VGA_VWIDTH  = 10'd2;
localparam VGA_VBACK   = 10'd33;

// Timing parameters for 480p 720x480@60
localparam P480_HPERIOD = 10'd858;
localparam P480_HFRONT  = 10'd16;
localparam P480_HWIDTH  = 10'd62;
localparam P480_HBACK   = 10'd60;
localparam P480_VPERIOD = 10'd525;
localparam P480_VFRONT  = 10'd9;
localparam P480_VWIDTH  = 10'd6;
localparam P480_VBACK   = 10'd30;

// Select timing parameters based on timing_sel
wire [9:0] HPERIOD = timing_sel ? P480_HPERIOD : VGA_HPERIOD;
wire [9:0] HFRONT  = timing_sel ? P480_HFRONT  : VGA_HFRONT;
wire [9:0] HWIDTH  = timing_sel ? P480_HWIDTH  : VGA_HWIDTH;
wire [9:0] HBACK   = timing_sel ? P480_HBACK   : VGA_HBACK;
wire [9:0] VPERIOD = timing_sel ? P480_VPERIOD : VGA_VPERIOD;
wire [9:0] VFRONT  = timing_sel ? P480_VFRONT  : VGA_VFRONT;
wire [9:0] VWIDTH  = timing_sel ? P480_VWIDTH  : VGA_VWIDTH;
wire [9:0] VBACK   = timing_sel ? P480_VBACK   : VGA_VBACK;

// Dual MMCM pixel clock generator
pckgen_dual pckgen_dual (
    .SYSCLK(CLK),
    .timing_sel(timing_sel),
    .PCK(PCK),
    .locked(locked)
);

// Horizontal counter
wire hcntend = (HCNT == HPERIOD - 10'h001);

always @(posedge PCK) begin
    if (RST)
        HCNT <= 10'h000;
    else if (hcntend)
        HCNT <= 10'h000;
    else
        HCNT <= HCNT + 10'h001;
end

// Vertical counter
always @(posedge PCK) begin
    if (RST)
        VCNT <= 10'h000;
    else if (hcntend) begin
        if (VCNT == VPERIOD - 10'h001)
            VCNT <= 10'h000;
        else
            VCNT <= VCNT + 10'h001;
    end
end

// Sync signals
wire [9:0] hsstart = HFRONT - 10'h001;
wire [9:0] hsend   = HFRONT + HWIDTH - 10'h001;
wire [9:0] vsstart = VFRONT;
wire [9:0] vsend   = VFRONT + VWIDTH;

always @(posedge PCK) begin
    if (RST)
        VGA_HS <= 1'b1;
    else if (HCNT == hsstart)
        VGA_HS <= 1'b0;
    else if (HCNT == hsend)
        VGA_HS <= 1'b1;
end

always @(posedge PCK) begin
    if (RST)
        VGA_VS <= 1'b1;
    else if (HCNT == hsstart) begin
        if (VCNT == vsstart)
            VGA_VS <= 1'b0;
        else if (VCNT == vsend)
            VGA_VS <= 1'b1;
    end
end

endmodule
