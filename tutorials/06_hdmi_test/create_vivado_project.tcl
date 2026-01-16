# Vivado Project Creation Script for HDMI AXI Control
# This script creates a complete Vivado project from scratch
# Usage: vivado -mode batch -source create_vivado_project.tcl
# Or in Vivado Tcl Console: source create_vivado_project.tcl

# Project settings
set project_name "hdmi_axi_project"
set project_dir "./vivado_project"
set part_name "xc7z010clg400-1"

# Get script directory
set script_dir [file dirname [file normalize [info script]]]
set rtl_dir "${script_dir}/hdmi_axi_src/rtl"
set rgb2dvi_dir "${script_dir}/hdmi_axi_src/ip/rgb2dvi/src"
set xdc_file "${script_dir}/hdmi_axi_src/constraints/pattern_hdmi_axi.xdc"

puts "=========================================="
puts "Creating Vivado Project for HDMI AXI Control"
puts "=========================================="
puts "Project: $project_name"
puts "Part: $part_name"
puts "Directory: $project_dir"
puts ""

# Create project
create_project $project_name $project_dir -part $part_name -force

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property default_lib work [current_project]

puts "Adding RTL source files..."

# Add RTL source files for AXI HDMI control
add_files -fileset sources_1 [list \
    "${rtl_dir}/pckgen_dual.v" \
    "${rtl_dir}/syncgen_multi.v" \
    "${rtl_dir}/pattern_multi.v" \
    "${rtl_dir}/axi_hdmi_ctrl.v" \
    "${rtl_dir}/pattern_hdmi_axi.v" \
]

# Add rgb2dvi IP source files (VHDL)
add_files -fileset sources_1 [glob ${rgb2dvi_dir}/*.vhd]

# Update compile order
update_compile_order -fileset sources_1

puts "Adding constraints file..."

# Add constraints
add_files -fileset constrs_1 $xdc_file

puts "Creating Block Design..."

# Create block design
create_bd_design "system"

# Add Zynq Processing System
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

# Configure PS (enable FCLK_CLK1 for 33.333MHz)
set_property -dict [list \
  CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
  CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {33} \
  CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
  CONFIG.PCW_FPGA_FCLK1_ENABLE {1} \
  CONFIG.PCW_EN_CLK1_PORT {1} \
  CONFIG.PCW_EN_RST1_PORT {1} \
  CONFIG.PCW_USE_M_AXI_GP0 {1} \
  CONFIG.PCW_USE_S_AXI_HP0 {0} \
  CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
  CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
  CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
  CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} \
] [get_bd_cells processing_system7_0]

# Run connection automation for PS
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
  -config {make_external "FIXED_IO, DDR" apply_board_preset "0" Master "Disable" Slave "Disable" } \
  [get_bd_cells processing_system7_0]

puts "Adding pattern_hdmi_axi module..."

# Create instance of pattern_hdmi_axi (custom RTL module)
create_bd_cell -type module -reference pattern_hdmi_axi pattern_hdmi_axi_0

# Set CLK pin properties to avoid automatic association
set_property CONFIG.ASSOCIATED_RESET {} [get_bd_pins pattern_hdmi_axi_0/CLK]

# Associate S_AXI interface with S_AXI_ACLK explicitly
set_property CONFIG.ASSOCIATED_BUSIF {S_AXI} [get_bd_pins pattern_hdmi_axi_0/S_AXI_ACLK]

puts "Adding Processor System Reset for 33MHz clock..."

# Add Processor System Reset for FCLK_CLK1 (33.333MHz)
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_33M
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] \
  [get_bd_pins rst_ps7_0_33M/slowest_sync_clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
  [get_bd_pins rst_ps7_0_33M/ext_reset_in]

puts "Creating SmartConnect..."

# Create SmartConnect (supports multiple clock domains)
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc
set_property -dict [list \
  CONFIG.NUM_SI {1} \
  CONFIG.NUM_CLKS {2} \
] [get_bd_cells axi_smc]

puts "Connecting clocks and resets..."

# Connect FCLK_CLK0 (100MHz) for PS and SmartConnect S00
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
  [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
  [get_bd_pins axi_smc/aclk]

# Connect FCLK_CLK1 (33.333MHz) for pattern_hdmi_axi CLK, S_AXI_ACLK, and SmartConnect M00
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] \
  [get_bd_pins pattern_hdmi_axi_0/CLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] \
  [get_bd_pins pattern_hdmi_axi_0/S_AXI_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] \
  [get_bd_pins axi_smc/aclk1]

# Connect resets
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET1_N] \
  [get_bd_pins pattern_hdmi_axi_0/RST]
connect_bd_net [get_bd_pins rst_ps7_0_33M/peripheral_aresetn] \
  [get_bd_pins pattern_hdmi_axi_0/S_AXI_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_33M/peripheral_aresetn] \
  [get_bd_pins axi_smc/aresetn]

puts "Connecting AXI interfaces..."

# Connect PS M_AXI_GP0 to SmartConnect
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
  [get_bd_intf_pins axi_smc/S00_AXI]

# Connect SmartConnect to pattern_hdmi_axi
connect_bd_intf_net [get_bd_intf_pins axi_smc/M00_AXI] \
  [get_bd_intf_pins pattern_hdmi_axi_0/S_AXI]

puts "Making external HDMI ports..."

# HDMI outputs
create_bd_port -dir O HDMI_CLK_N
connect_bd_net [get_bd_ports HDMI_CLK_N] [get_bd_pins pattern_hdmi_axi_0/HDMI_CLK_N]

create_bd_port -dir O HDMI_CLK_P
connect_bd_net [get_bd_ports HDMI_CLK_P] [get_bd_pins pattern_hdmi_axi_0/HDMI_CLK_P]

create_bd_port -dir O -from 2 -to 0 HDMI_N
connect_bd_net [get_bd_ports HDMI_N] [get_bd_pins pattern_hdmi_axi_0/HDMI_N]

create_bd_port -dir O -from 2 -to 0 HDMI_P
connect_bd_net [get_bd_ports HDMI_P] [get_bd_pins pattern_hdmi_axi_0/HDMI_P]

puts "Assigning AXI address..."

# Assign address
assign_bd_address [get_bd_addr_segs {pattern_hdmi_axi_0/S_AXI/reg0 }]
set_property offset 0x43C00000 [get_bd_addr_segs {processing_system7_0/Data/SEG_pattern_hdmi_axi_0_reg0}]
set_property range 4K [get_bd_addr_segs {processing_system7_0/Data/SEG_pattern_hdmi_axi_0_reg0}]

puts "Validating Block Design..."

# Validate design
regenerate_bd_layout
validate_bd_design
save_bd_design

puts "Creating HDL wrapper..."

# Create HDL wrapper
make_wrapper -files [get_files ${project_dir}/${project_name}.srcs/sources_1/bd/system/system.bd] -top
add_files -norecurse ${project_dir}/${project_name}.gen/sources_1/bd/system/hdl/system_wrapper.v

# Set top module
set_property top system_wrapper [current_fileset]
update_compile_order -fileset sources_1

puts ""
puts "=========================================="
puts "Project creation completed successfully!"
puts "=========================================="
puts "Project location: ${project_dir}/${project_name}.xpr"
puts "AXI Base Address: 0x43C00000"
puts ""
puts "Next steps:"
puts "1. Open project in Vivado GUI"
puts "2. Review Block Design (system.bd)"
puts "3. Run Synthesis"
puts "4. Run Implementation"
puts "5. Generate Bitstream"
puts ""
