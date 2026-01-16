/* AXI4-Lite controlled HDMI pattern generator top module
 * Integrates AXI control, multi-preset timing, and multi-pattern generation
 * 
 * Features:
 * - AXI4-Lite slave interface for PS control
 * - Dual timing presets: VGA 640x480@60, 480p 720x480@60
 * - Three test patterns: Color bars, Checkerboard, Gradation
 * - VSync-synchronized register updates (no tearing)
 */

module pattern_hdmi_axi #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 4
)(
    // AXI4-Lite slave interface
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 S_AXI_ACLK CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET S_AXI_ARESETN" *)
    input  wire                                 S_AXI_ACLK,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 S_AXI_ARESETN RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire                                 S_AXI_ARESETN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]       S_AXI_AWADDR,
    input  wire [2:0]                           S_AXI_AWPROT,
    input  wire                                 S_AXI_AWVALID,
    output wire                                 S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0]       S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]   S_AXI_WSTRB,
    input  wire                                 S_AXI_WVALID,
    output wire                                 S_AXI_WREADY,
    output wire [1:0]                           S_AXI_BRESP,
    output wire                                 S_AXI_BVALID,
    input  wire                                 S_AXI_BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]       S_AXI_ARADDR,
    input  wire [2:0]                           S_AXI_ARPROT,
    input  wire                                 S_AXI_ARVALID,
    output wire                                 S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0]       S_AXI_RDATA,
    output wire [1:0]                           S_AXI_RRESP,
    output wire                                 S_AXI_RVALID,
    input  wire                                 S_AXI_RREADY,
    
    // System clock and reset (for pattern generation)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK CLK" *)
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 33333336" *)
    input           CLK,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input           RST,
    
    // HDMI output
    output          HDMI_CLK_N, HDMI_CLK_P,
    output  [2:0]   HDMI_N, HDMI_P
);

// Internal signals
wire [7:0] VGA_R, VGA_G, VGA_B;
wire VGA_HS, VGA_VS, VGA_DE;
wire PCK, locked;
wire timing_sel_sync;
wire [1:0] pattern_sel_sync;

// Invert RST since it's now ACTIVE_LOW from PS
wire RST_internal;
assign RST_internal = ~RST;

// AXI control block
axi_hdmi_ctrl #(
    .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
) axi_ctrl (
    .S_AXI_ACLK(S_AXI_ACLK),
    .S_AXI_ARESETN(S_AXI_ARESETN),
    .S_AXI_AWADDR(S_AXI_AWADDR),
    .S_AXI_AWPROT(S_AXI_AWPROT),
    .S_AXI_AWVALID(S_AXI_AWVALID),
    .S_AXI_AWREADY(S_AXI_AWREADY),
    .S_AXI_WDATA(S_AXI_WDATA),
    .S_AXI_WSTRB(S_AXI_WSTRB),
    .S_AXI_WVALID(S_AXI_WVALID),
    .S_AXI_WREADY(S_AXI_WREADY),
    .S_AXI_BRESP(S_AXI_BRESP),
    .S_AXI_BVALID(S_AXI_BVALID),
    .S_AXI_BREADY(S_AXI_BREADY),
    .S_AXI_ARADDR(S_AXI_ARADDR),
    .S_AXI_ARPROT(S_AXI_ARPROT),
    .S_AXI_ARVALID(S_AXI_ARVALID),
    .S_AXI_ARREADY(S_AXI_ARREADY),
    .S_AXI_RDATA(S_AXI_RDATA),
    .S_AXI_RRESP(S_AXI_RRESP),
    .S_AXI_RVALID(S_AXI_RVALID),
    .S_AXI_RREADY(S_AXI_RREADY),
    .PCK(PCK),
    .VGA_VS(VGA_VS),
    .locked(locked),
    .timing_sel_sync(timing_sel_sync),
    .pattern_sel_sync(pattern_sel_sync)
);

// Pattern generator with multi-preset and multi-pattern support
pattern_multi pattern_multi (
    .CLK(CLK),
    .RST(RST_internal),
    .timing_sel(timing_sel_sync),
    .pattern_sel(pattern_sel_sync),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_DE(VGA_DE),
    .PCK(PCK),
    .locked(locked)
);

// HDMI signal generation IP
rgb2dvi #(
    .kClkPrimitive("MMCM"),
    .kClkRange(5)  // 25MHz <= fPCK < 30MHz
) rgb2dvi_inst (
    .PixelClk(PCK),
    .TMDS_Clk_n(HDMI_CLK_N),
    .TMDS_Clk_p(HDMI_CLK_P),
    .TMDS_Data_n(HDMI_N),
    .TMDS_Data_p(HDMI_P),
    .aRst(RST_internal),
    .vid_pData({VGA_R, VGA_B, VGA_G}),
    .vid_pHSync(VGA_HS),
    .vid_pVDE(VGA_DE),
    .vid_pVSync(VGA_VS)
);

endmodule
