# EBAZ4205 constraints file for AXI-controlled HDMI pattern generator
# Project: 06_hdmi_test with AXI4-Lite control
# Note: CLK and RST are provided by PS FCLK_CLK1 and FCLK_RESET1_N (no external pins)

# HDMI TX outputs
set_property -dict {PACKAGE_PIN F20 IOSTANDARD TMDS_33} [get_ports HDMI_CLK_N]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD TMDS_33} [get_ports HDMI_CLK_P]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD TMDS_33} [get_ports {HDMI_N[0]}]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD TMDS_33} [get_ports {HDMI_P[0]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD TMDS_33} [get_ports {HDMI_N[1]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD TMDS_33} [get_ports {HDMI_P[1]}]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD TMDS_33} [get_ports {HDMI_N[2]}]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD TMDS_33} [get_ports {HDMI_P[2]}]

# Clock domain crossing constraints
# CDC synchronizer paths - relax timing for metastability registers
set_false_path -through [get_pins -hierarchical -filter {NAME =~ "*_meta_reg*/D"}]

# Logically exclusive clocks (only one active at a time via BUFGMUX)
# VGA mode (iPCK0) and 480p mode (iPCK1) are mutually exclusive
set_clock_groups -logically_exclusive \
  -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ "*pckgen_dual/MMCM_DUAL/CLKOUT0"}]] \
  -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ "*pckgen_dual/MMCM_DUAL/CLKOUT1"}]]

# False paths between mismatched pixel clock modes
# CLKOUT0 (VGA) should not cross to rgb2dvi clocks derived from CLKOUT1 (480p)
set_false_path -from [get_clocks -of_objects [get_pins system_i/pattern_hdmi_axi_0/inst/pattern_multi/syncgen_multi/pckgen_dual/MMCM_DUAL/CLKOUT0]] \
  -to [get_clocks -of_objects [get_pins system_i/pattern_hdmi_axi_0/inst/rgb2dvi_inst/ClockGenInternal.ClockGenX/GenMMCM.PixelClkBuffer/O] -filter {IS_GENERATED && MASTER_CLOCK == PixelClkInX5_1}]
# CLKOUT1 (480p) should not cross to rgb2dvi clocks derived from CLKOUT0 (VGA)
set_false_path -from [get_clocks -of_objects [get_pins system_i/pattern_hdmi_axi_0/inst/pattern_multi/syncgen_multi/pckgen_dual/MMCM_DUAL/CLKOUT1]] \
  -to [get_clocks -of_objects [get_pins system_i/pattern_hdmi_axi_0/inst/rgb2dvi_inst/ClockGenInternal.ClockGenX/GenMMCM.PixelClkBuffer/O] -filter {IS_GENERATED && MASTER_CLOCK == PixelClkInX5}]
