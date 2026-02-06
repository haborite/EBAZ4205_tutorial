# Zynq-7000 Tutorial

This tutorial provides comprehensive examples for Zynq-7000 development, covering both hardware design in Vivado and software development in Vitis.

## Overview

The 05_Zynq7000 tutorial includes:

### Hardware Design (Vivado)
- **Block Design**: Complete Zynq PS configuration with peripherals
- **GPIO Configuration**: External GPIO and EMIO setup
- **Peripheral Integration**: UART, Ethernet, Timer, and other peripherals
- **Bitstream Generation**: FPGA programming files

### Software Applications (Vitis)
- **LED External Test 1**: Direct GPIO register access for LED control
- **LED External Test 2**: Xilinx GPIO driver-based LED control  
- **lwIP Echo Server**: Network echo server using lwIP stack
- **Memory Test**: Comprehensive memory validation
- **Peripheral Test**: Multi-peripheral functionality testing
- **PS LCD**: LCD display control via PS GPIO

## Hardware Requirements

- Zynq-7000 based development board (EBAZ4205)
- LEDs for testing applications
- Ethernet connection for network applications
- LCD display for PS LCD application
  - [Adapter with LCD](https://ja.aliexpress.com/item/1005006074065888.html) (recommended)
- JTAG or UART connection for programming/debugging

## Software Requirements

- Xilinx Vivado Design Suite
- Xilinx Vitis IDE
- Zynq-7000 BSP (Board Support Package)
- Required Xilinx driver libraries

## Getting Started

1. **Hardware Setup**
   - Open Vivado project in `vivado/` directory
   - Review block design configuration
   - Generate bitstream and export to Vitis

2. **Software Development**
   - Import Vitis workspace from `vitis/` directory
   - Build desired application projects
   - Program FPGA and run applications

3. **Testing**
   - Monitor UART output for debugging
   - Verify hardware functionality
   - Test application-specific features

## Directory Structure

```
05_Zynq7000/
├── vivado/                 # Vivado hardware design
│   ├── block_design.png    # Block design overview
│   └── project files       # Vivado project files
├── vitis/                  # Vitis software applications
│   ├── README.md           # Detailed software documentation
│   ├── README_JP.md        # Japanese documentation
│   └── application folders # Individual application projects
└── README.md               # This file
```

## Applications Summary

| Application | Purpose | Key Features |
|-------------|---------|--------------|
| LED External Test 1 | Basic GPIO control | Direct register access, 8-state pattern |
| LED External Test 2 | Driver-based GPIO | XGpio driver, error handling |
| lwIP Echo Server | Network testing | TCP/UDP echo, IPv4/IPv6 support |
| Memory Test | Memory validation | Comprehensive testing, error reporting |
| Peripheral Test | Multi-peripheral testing | GPIO, UART, I2C, SPI, Timer, DMA |
| PS LCD | Display control | EMIO GPIO, color rendering |

## Common Development Workflow

1. **Hardware Design**: Configure FPGA in Vivado
2. **Software Development**: Create applications in Vitis
3. **Testing**: Program and validate functionality
4. **Debugging**: Monitor UART and verify operation

## Support

- **Vivado Documentation**: See `vivado/` directory
- **Vitis Documentation**: See `vitis/README.md`
- **Hardware Reference**: EBAZ4205 documentation
- **Xilinx Documentation**: https://docs.xilinx.com/

---

**Last Updated**: February 2026  
**Platform**: Xilinx Zynq-7000  
**Target Board**: EBAZ4205
