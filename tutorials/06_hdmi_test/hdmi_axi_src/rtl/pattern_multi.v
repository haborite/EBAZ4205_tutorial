/* Multi-pattern test pattern generator with pattern_sel control
 * Pattern 0: Color bars
 * Pattern 1: Checkerboard
 * Pattern 2: Gradation
 */

module pattern_multi(
    input               CLK,
    input               RST,
    input               timing_sel,    // 0=VGA, 1=480p
    input       [1:0]   pattern_sel,   // 0=bars, 1=checker, 2=gradation
    output  reg [7:0]   VGA_R, VGA_G, VGA_B,
    output              VGA_HS, VGA_VS,
    output  reg         VGA_DE,
    output              PCK,
    output              locked
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

// Sync generator
wire [9:0] HCNT, VCNT;

syncgen_multi syncgen_multi(
    .CLK        (CLK),
    .RST        (RST),
    .timing_sel (timing_sel),
    .PCK        (PCK),
    .locked     (locked),
    .VGA_HS     (VGA_HS),
    .VGA_VS     (VGA_VS),
    .HCNT       (HCNT),
    .VCNT       (VCNT)
);

// Display area calculation
wire [9:0] HBLANK = HFRONT + HWIDTH + HBACK;
wire [9:0] VBLANK = VFRONT + VWIDTH + VBACK;

wire disp_enable = (VBLANK <= VCNT)
                && (HBLANK - 10'd1 <= HCNT) && (HCNT < HPERIOD - 10'd1);

// Active display coordinates
wire [9:0] disp_x = HCNT - HBLANK + 10'd1;
wire [9:0] disp_y = VCNT - VBLANK;

// Active resolution (depends on timing_sel)
wire [9:0] HACTIVE = timing_sel ? 10'd720 : 10'd640;
wire [9:0] VACTIVE = 10'd480;

// Pattern generation
reg [7:0] pattern_r, pattern_g, pattern_b;

always @(*) begin
    case (pattern_sel)
        2'd0: begin  // Color bars (8 vertical bars)
            case (disp_x * 8 / HACTIVE)
                3'd0: {pattern_r, pattern_g, pattern_b} = {8'hFF, 8'hFF, 8'hFF}; // White
                3'd1: {pattern_r, pattern_g, pattern_b} = {8'hFF, 8'hFF, 8'h00}; // Yellow
                3'd2: {pattern_r, pattern_g, pattern_b} = {8'h00, 8'hFF, 8'hFF}; // Cyan
                3'd3: {pattern_r, pattern_g, pattern_b} = {8'h00, 8'hFF, 8'h00}; // Green
                3'd4: {pattern_r, pattern_g, pattern_b} = {8'hFF, 8'h00, 8'hFF}; // Magenta
                3'd5: {pattern_r, pattern_g, pattern_b} = {8'hFF, 8'h00, 8'h00}; // Red
                3'd6: {pattern_r, pattern_g, pattern_b} = {8'h00, 8'h00, 8'hFF}; // Blue
                3'd7: {pattern_r, pattern_g, pattern_b} = {8'h00, 8'h00, 8'h00}; // Black
                default: {pattern_r, pattern_g, pattern_b} = {8'h00, 8'h00, 8'h00};
            endcase
        end
        
        2'd1: begin  // Checkerboard (32x32 pixel squares)
            if ((disp_x[5] ^ disp_y[5]) == 1'b1)
                {pattern_r, pattern_g, pattern_b} = {8'hFF, 8'hFF, 8'hFF};
            else
                {pattern_r, pattern_g, pattern_b} = {8'h00, 8'h00, 8'h00};
        end
        
        2'd2: begin  // Horizontal gradation
            pattern_r = disp_x[9:2];
            pattern_g = disp_x[9:2];
            pattern_b = disp_x[9:2];
        end
        
        default: begin  // Black
            {pattern_r, pattern_g, pattern_b} = {8'h00, 8'h00, 8'h00};
        end
    endcase
end

// RGB output
always @(posedge PCK) begin
    if (RST)
        {VGA_R, VGA_G, VGA_B} <= 24'h0;
    else if (disp_enable)
        {VGA_R, VGA_G, VGA_B} <= {pattern_r, pattern_g, pattern_b};
    else
        {VGA_R, VGA_G, VGA_B} <= 24'h0;
end

// Display enable delayed by 1 clock for VGA_DE
always @(posedge PCK) begin
    if (RST)
        VGA_DE <= 1'b0;
    else
        VGA_DE <= disp_enable;
end

endmodule
