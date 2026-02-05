# Zynq-7000 All Applications

This repository contains a comprehensive collection of applications for the Zynq-7000 platform, demonstrating various aspects of embedded systems development including GPIO control, networking, memory testing, peripheral validation, and display management.

## Table of Contents

- [Applications Overview](#applications-overview)
- [Hardware Requirements](#hardware-requirements)
- [Software Requirements](#software-requirements)
- [Getting Started](#getting-started)
- [Applications](#applications)
  - [LED External Test 1](#led-external-test-1)
  - [LED External Test 2](#led-external-test-2)
  - [lwIP Echo Server](#lwip-echo-server)
  - [Memory Test](#memory-test)
  - [Peripheral Test](#peripheral-test)
  - [PS LCD](#ps-lcd)
- [Common Development Workflow](#common-development-workflow)
- [Troubleshooting](#troubleshooting)
- [License Information](#license-information)

## Applications Overview

This project includes six main applications, each designed to test and demonstrate specific functionality of the Zynq-7000 platform:

1. **LED External Test 1** - Direct GPIO register access for LED control
2. **LED External Test 2** - Xilinx GPIO driver-based LED control
3. **lwIP Echo Server** - Network echo server using lwIP stack
4. **Memory Test** - Comprehensive memory validation
5. **Peripheral Test** - Multi-peripheral functionality testing
6. **PS LCD** - LCD display control via PS GPIO

## Hardware Requirements

- Zynq-7000 based development board
- Configured FPGA bitstream with required peripherals
- LEDs (for LED test applications)
- Ethernet connection (for lwIP echo server)
- LCD display (for PS LCD application)
- JTAG or UART connection for programming/debugging
- Appropriate power supply

## Software Requirements

- Xilinx Vitis IDE
- Xilinx Vivado Design Suite
- Zynq-7000 BSP (Board Support Package)
- Required Xilinx driver libraries
- Terminal application for UART communication

## Getting Started

1. Clone or download this repository
2. Open Vitis IDE and import the workspace
3. Build the desired application project
4. Program the FPGA with the appropriate bitstream
5. Run the application and monitor output via UART

## Applications

### LED External Test 1

**Location:** `led_ext_1/`

**Overview:** Demonstrates basic LED control using direct GPIO register access. Creates an 8-state LED blinking pattern with console output.

**Key Features:**
- Direct memory access to GPIO registers
- 8-state LED pattern (0x0 to 0x7)
- Console debugging output
- Continuous operation

**Technical Details:**
- LED control: `XPAR_GPIO_0_BASEADDR + 0x00`
- Direction control: `XPAR_GPIO_0_BASEADDR + 0x04`
- Delay: 40,000,000 iterations

**Author:** Copyright (C) 2020 Cobac.Net All Rights Reserved

---

### LED External Test 2

**Location:** `led_ext_2/`

**Overview:** LED control using the official Xilinx GPIO driver (XGpio) with proper initialization and error handling.

**Key Features:**
- Xilinx GPIO driver implementation
- 3-LED control (bits 0-2)
- Driver initialization with error checking
- Configurable timing

**Technical Details:**
- GPIO Channel: 1
- LED definitions: LED1 (0x01), LED2 (0x02), LED3 (0x04)
- Delay: 50,000,000 iterations
- Device ID: `XPAR_GPIO_0_DEVICE_ID`

---

### lwIP Echo Server

**Location:** `lwip_echo_server/`

**Overview:** Network echo server implementation using the lightweight IP stack (lwIP). Supports both IPv4 and IPv6 protocols.

**Key Features:**
- TCP/UDP echo server on port 7
- IPv4 and IPv6 support
- Configurable network settings
- Platform-specific optimizations

**Network Configuration:**
- **IPv4:** 192.168.1.10/255.255.255.0, Gateway: 192.168.1.1
- **IPv6:** FE80:0:0:0:20A:35FF:FE00:102
- **MAC:** 00:0a:35:00:01:02

**Usage Examples:**
```bash
# IPv4 test
telnet 192.168.1.10 7

# IPv6 test
telnet -6 FE80:0:0:0:20A:35FF:FE00:102%eth1 7
```

**Reference:** Xilinx Application Note XAPP 1026

---

### Memory Test

**Location:** `memory_test/`

**Overview:** Comprehensive memory testing application that validates all memory regions present in the hardware design.

**Key Features:**
- Memory range detection and testing
- Multiple test patterns
- Cache-aware testing (D-Cache disabled)
- Comprehensive error reporting

**Technical Details:**
- Tests in 4KB chunks
- Uses Xilinx memory test library
- No heap allocation (minimal footprint)
- Platform-specific optimizations

**License:** SPDX-License-Identifier: MIT

---

### Peripheral Test

**Location:** `peripheral_test/`

**Overview:** Comprehensive testing suite for various Zynq-7000 peripherals with both polled and interrupt-driven operation modes.

**Supported Peripherals:**
- GPIO, UART (polled/interrupt), I2C, SPI
- Timer (polled/interrupt), Watchdog (interrupt)
- DMA (interrupt), Device Configuration
- Interrupt Controller

**Test Modules:**
- Individual test files for each peripheral
- Self-test functionality
- Error detection and reporting
- Performance metrics

**Key Features:**
- Standalone driver library usage
- ARM Cortex-A9 support
- Resource management
- Comprehensive error handling

---

### PS LCD

**Location:** `ps_lcd/`

**Overview:** LCD control application using Processing System GPIO functionality through EMIO pins.

**Key Features:**
- LCD control via PS GPIO
- EMIO pin configuration
- Color display support
- LCD initialization sequences

**EMIO Pin Mapping:**
- Chip Select: Pin 54
- Command/Data: Pin 55
- Reset: Pin 56
- Serial Clock: Pin 57
- Serial Data: Pin 58

**Color Support:**
- 16 predefined colors (WHITE, BLACK, RED, GREEN, BLUE, etc.)
- RGB color rendering
- Display management

**License:** SPDX-License-Identifier: MIT

## Common Development Workflow

1. **Hardware Setup**
   - Configure FPGA design in Vivado
   - Generate bitstream and export to Vitis
   - Connect required peripherals

2. **Software Development**
   - Import application into Vitis workspace
   - Configure BSP settings
   - Build the application

3. **Testing and Debugging**
   - Program FPGA with bitstream
   - Run application via JTAG or from memory
   - Monitor UART output for debugging

4. **Validation**
   - Verify hardware functionality
   - Check console output for errors
   - Test application-specific features

## Troubleshooting

### Common Issues

1. **Build Errors**
   - Verify BSP configuration
   - Check driver library inclusion
   - Ensure correct hardware platform

2. **Runtime Errors**
   - Verify FPGA programming
   - Check peripheral connections
   - Monitor UART for error messages

3. **Hardware Issues**
   - Verify power supply
   - Check clock configuration
   - Validate pin assignments

### Debugging Tips

- Use UART output for debugging information
- Verify hardware design matches software expectations
- Check interrupt controller configuration
- Validate memory maps and address spaces

## License Information

Applications in this repository are subject to different license terms:

- **LED External Test 1:** Copyright (C) 2020 Cobac.Net All Rights Reserved
- **LED External Test 2:** Xilinx example code license
- **lwIP Echo Server:** Xilinx license terms
- **Memory Test:** SPDX-License-Identifier: MIT (AMD/Xilinx)
- **Peripheral Test:** Xilinx license terms
- **PS LCD:** SPDX-License-Identifier: MIT (AMD)

Please refer to individual application directories for specific license details.

## Support and Documentation

- **Xilinx Documentation:** https://docs.xilinx.com/
- **Zynq-7000 Technical Reference Manual:** UG585
- **Vitis Unified Software Platform Documentation:** UG1393
- **lwIP Documentation:** http://savannah.nongnu.org/projects/lwip/

## Contributing

When contributing to this repository:
1. Follow existing code style and conventions
2. Update relevant documentation
3. Test changes on target hardware
4. Ensure license compliance

---

**Last Updated:** February 2026  
**Platform:** Xilinx Zynq-7000  
**Tools:** Vitis/Vivado
