## EBAZ4205 Merged Constraints File
## EBAZ4205 マージ済み制約ファイル
##
## This file merges general constraints and HDMI AXI constraints.
## このファイルは、一般的な制約とHDMI AXI制約をマージしたものです。

# ==============================================================================
# System Clock & Reset
# システムクロックおよびリセット
# ==============================================================================
# 33.33MHz External Clock / 33.33MHz 外部クロック
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { CLK }];
create_clock -add -name sys_clk_pin -period 30.00 -waveform {0 4} [get_ports { CLK }];

# Reset Button (BTN[1]) / リセットボタン (BTN[1])
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { RST }];

# ==============================================================================
# User I/O (LEDs & Buttons)
# ユーザーI/O (LEDおよびボタン)
# ==============================================================================
# RGB LEDs / RGB LED
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports {LED_RGB[2]}]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports {LED_RGB[1]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {LED_RGB[0]}]

# Push Buttons / プッシュボタン
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33} [get_ports {BTN[0]}]
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33} [get_ports {BTN[1]}]
set_property -dict {PACKAGE_PIN U20 IOSTANDARD LVCMOS33} [get_ports {BTN[2]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {BTN[3]}]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD LVCMOS33} [get_ports {BTN[4]}]

# ==============================================================================
# Ethernet (EMIO PHY)
# イーサネット (EMIO PHY)
# ==============================================================================
# MDIO Interface / MDIOインターフェース
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS33} [get_ports MDIO_ETHERNET_0_0_mdc]
set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVCMOS33} [get_ports MDIO_ETHERNET_0_0_mdio_io]

# GMII RX Interface / GMII RXインターフェース
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports ENET0_GMII_RX_CLK_0];
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports ENET0_GMII_RX_DV_0];
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports {ENET0_GMII_RXD_0[0]}];
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {ENET0_GMII_RXD_0[1]}];
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {ENET0_GMII_RXD_0[2]}];
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports {ENET0_GMII_RXD_0[3]}];

# GMII TX Interface / GMII TXインターフェース
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports ENET0_GMII_TX_CLK_0];
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports {ENET0_GMII_TX_EN_0[0]}];
set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {ENET0_GMII_TXD_0[0]}];
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports {ENET0_GMII_TXD_0[1]}];
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS33} [get_ports {ENET0_GMII_TXD_0[2]}];
set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports {ENET0_GMII_TXD_0[3]}];

# 25MHz Output Clock for PHY / PHY用25MHz出力クロック
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports FCLK_CLK3]

# ==============================================================================
# UART & GPIO
# UARTおよびGPIO
# ==============================================================================
# UART Interface / UARTインターフェース
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports UART_0_rxd]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports UART_0_txd]

# General Purpose I/O / 汎用I/O /LCD_PIN(SPI)
# BL(CS): T20
# DC    : R18
# RES   : N17
# SCL   : R19
# SDA   : P20
set_property -dict {PACKAGE_PIN T20 IOSTANDARD LVCMOS33} [get_ports {GPIO_0_0_tri_io[0]}]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports {GPIO_0_0_tri_io[1]}]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports {GPIO_0_0_tri_io[2]}]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports {GPIO_0_0_tri_io[3]}]
set_property -dict {PACKAGE_PIN P20 IOSTANDARD LVCMOS33} [get_ports {GPIO_0_0_tri_io[4]}]

# ==============================================================================
# HDMI Interface (TMDS)
# HDMIインターフェース (TMDS)
# ==============================================================================
# Note: CLK and RST are provided by PS FCLK_CLK1 and FCLK_RESET1_N (no external pins)
# 注意: CLKおよびRSTはPSのFCLK_CLK1およびFCLK_RESET1_Nから供給されます (外部ピンなし)

# HDMI Differential Clock / HDMI差動クロック
set_property -dict {PACKAGE_PIN F20 IOSTANDARD TMDS_33} [get_ports HDMI_CLK_N]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD TMDS_33} [get_ports HDMI_CLK_P]

# HDMI Differential Data / HDMI差動データ
set_property -dict {PACKAGE_PIN D20 IOSTANDARD TMDS_33} [get_ports {HDMI_N[0]}]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD TMDS_33} [get_ports {HDMI_P[0]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD TMDS_33} [get_ports {HDMI_N[1]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD TMDS_33} [get_ports {HDMI_P[1]}]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD TMDS_33} [get_ports {HDMI_N[2]}]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD TMDS_33} [get_ports {HDMI_P[2]}]

# ==============================================================================
# Clock Domain Crossing (CDC) & Timing Constraints
# クロックドメイン交差 (CDC) およびタイミング制約
# ==============================================================================
# CDC synchronizer paths - relax timing for metastability registers
# CDCシンクロナイザーパス - メタスタビリティレジスタのタイミング制約を緩和
set_false_path -through [get_pins -hierarchical -filter {NAME =~ "*_meta_reg*/D"}]

# Logically exclusive clocks (only one active at a time via BUFGMUX)
# VGA mode (iPCK0) and 480p mode (iPCK1) are mutually exclusive
# 論理的に排他的なクロック (BUFGMUX経由で一度に1つのみアクティブ)
# VGAモード(iPCK0)と480pモード(iPCK1)は相互に排他的
set_clock_groups -logically_exclusive \
  -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ "*pckgen_dual/MMCM_DUAL/CLKOUT0"}]] \
  -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ "*pckgen_dual/MMCM_DUAL/CLKOUT1"}]]

# False paths between mismatched pixel clock modes
# CLKOUT0 (VGA) should not cross to rgb2dvi clocks derived from CLKOUT1 (480p)
# 一致しないピクセルクロックモード間のフォルスパス
# CLKOUT0 (VGA) は CLKOUT1 (480p) から派生したrgb2dviクロックと交差してはならない
set_false_path -from [get_clocks -of_objects [get_pins system_i/pattern_hdmi_axi_0/inst/pattern_multi/syncgen_multi/pckgen_dual/MMCM_DUAL/CLKOUT0]] \
  -to [get_clocks -of_objects [get_pins system_i/pattern_hdmi_axi_0/inst/rgb2dvi_inst/ClockGenInternal.ClockGenX/GenMMCM.PixelClkBuffer/O] -filter {IS_GENERATED && MASTER_CLOCK == PixelClkInX5_1}]

# CLKOUT1 (480p) should not cross to rgb2dvi clocks derived from CLKOUT0 (VGA)
# CLKOUT1 (480p) は CLKOUT0 (VGA) から派生したrgb2dviクロックと交差してはならない
set_false_path -from [get_clocks -of_objects [get_pins system_i/pattern_hdmi_axi_0/inst/pattern_multi/syncgen_multi/pckgen_dual/MMCM_DUAL/CLKOUT1]] \
  -to [get_clocks -of_objects [get_pins system_i/pattern_hdmi_axi_0/inst/rgb2dvi_inst/ClockGenInternal.ClockGenX/GenMMCM.PixelClkBuffer/O] -filter {IS_GENERATED && MASTER_CLOCK == PixelClkInX5}]
