## EBAZ4205 constraints file
## chapter: 2
## project: ebaz4205_taizen

#Clock signal
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { CLK }];
create_clock -add -name sys_clk_pin -period 30.00 -waveform {0 4} [get_ports { CLK }];

#Reset
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { RST }]; # BTN[1]

# RGB LEDs
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports {LED_RGB[2]}]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports {LED_RGB[1]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {LED_RGB[0]}]

# Buttons
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33} [get_ports {BTN[0]}]

# 25MHz Out
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports FCLK_CLK3]

# EMIO PHY
set_property IOSTANDARD LVCMOS33 [get_ports ENET0_GMII_RX_CLK_0];
set_property IOSTANDARD LVCMOS33 [get_ports ENET0_GMII_TX_CLK_0];
set_property PACKAGE_PIN U14 [get_ports ENET0_GMII_RX_CLK_0];
set_property PACKAGE_PIN U15 [get_ports ENET0_GMII_TX_CLK_0];

set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_RXD_0[3]}];
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_RXD_0[2]}];
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_RXD_0[1]}];
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_RXD_0[0]}];
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_TX_EN_0[0]}];
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_TXD_0[3]}];
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_TXD_0[2]}];
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_TXD_0[1]}];
set_property IOSTANDARD LVCMOS33 [get_ports {ENET0_GMII_TXD_0[0]}];
set_property IOSTANDARD LVCMOS33 [get_ports ENET0_GMII_RX_DV_0];
set_property IOSTANDARD LVCMOS33 [get_ports MDIO_ETHERNET_0_0_mdc]
set_property IOSTANDARD LVCMOS33 [get_ports MDIO_ETHERNET_0_0_mdio_io]
set_property PACKAGE_PIN Y17 [get_ports {ENET0_GMII_RXD_0[3]}];
set_property PACKAGE_PIN V17 [get_ports {ENET0_GMII_RXD_0[2]}];
set_property PACKAGE_PIN V16 [get_ports {ENET0_GMII_RXD_0[1]}];
set_property PACKAGE_PIN Y16 [get_ports {ENET0_GMII_RXD_0[0]}];
set_property PACKAGE_PIN W19 [get_ports {ENET0_GMII_TX_EN_0[0]}];
set_property PACKAGE_PIN W18 [get_ports {ENET0_GMII_TXD_0[0]}];
set_property PACKAGE_PIN Y18 [get_ports {ENET0_GMII_TXD_0[1]}];
set_property PACKAGE_PIN V18 [get_ports {ENET0_GMII_TXD_0[2]}];
set_property PACKAGE_PIN Y19 [get_ports {ENET0_GMII_TXD_0[3]}];
set_property PACKAGE_PIN W15 [get_ports MDIO_ETHERNET_0_0_mdc]
set_property PACKAGE_PIN Y14 [get_ports MDIO_ETHERNET_0_0_mdio_io]
set_property PACKAGE_PIN W16 [get_ports ENET0_GMII_RX_DV_0];


set_property PACKAGE_PIN H16 [get_ports UART_1_rxd]
set_property IOSTANDARD LVCMOS33 [get_ports UART_1_rxd]
set_property PACKAGE_PIN H17 [get_ports UART_1_txd]
set_property IOSTANDARD LVCMOS33 [get_ports UART_1_txd]

set_property PACKAGE_PIN T20 [get_ports {GPIO_0_0_tri_io[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GPIO_0_0_tri_io[0]}]
set_property PACKAGE_PIN R18 [get_ports {GPIO_0_0_tri_io[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GPIO_0_0_tri_io[1]}]
set_property PACKAGE_PIN N17 [get_ports {GPIO_0_0_tri_io[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GPIO_0_0_tri_io[2]}]
set_property PACKAGE_PIN R19 [get_ports {GPIO_0_0_tri_io[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GPIO_0_0_tri_io[3]}]
set_property PACKAGE_PIN P20 [get_ports {GPIO_0_0_tri_io[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GPIO_0_0_tri_io[4]}]

set_property PACKAGE_PIN P19 [get_ports {BTN[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {BTN[1]}]
set_property PACKAGE_PIN U20 [get_ports {BTN[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {BTN[2]}]
set_property PACKAGE_PIN U19 [get_ports {BTN[3]}]
set_property PACKAGE_PIN V20 [get_ports {BTN[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {BTN[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {BTN[3]}]
