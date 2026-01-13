# EBAZ4205 Tutorial

English | [日本語](README_JP.md)

A collection of FPGA/SoC development tutorials using EBAZ4205 (a board with a Zynq-7000 SoC).

## Overview

This repository contains tutorial projects to learn development for the Xilinx Zynq-7000 SoC using the EBAZ4205 board.

### Target Device

- **SoC**: Xilinx Zynq-7000 (xc7z010clg400-1)
- **Board**: EBAZ4205

## Directory Structure

```
EBAZ4205_tutorial/
├── documents/              # Datasheets, schematics, reference materials, boot images, etc.
│   ├── EBAZ4205/            # Board materials (schematics, manuals, images, etc.)
│   ├── xilinx_user_guide/   # Official Xilinx User Guides
│   ├── TF_boot_image/       # Boot images
│   ├── ether_phy/           # Ethernet PHY-related documents
│   ├── adapter/             # Adapter / verification materials
│   └── ...
├── tutorials/              # Tutorial projects
│   ├── 01_blink/          # LED blinking (basic)
│   ├── 02_blinkspeed/     # LED blink speed control
│   ├── 03_pattern/        # Pattern display (HDMI output)
│   ├── 04_gradation/      # Gradation display (HDMI output)
│   ├── 05_Zynq7000/       # Zynq PS+PL integrated project
│   └── PS_LCD_test/       # PS-side LCD test
└── LICENSE
```

## Tutorial Contents

### 01_blink

A basic PL project to control RGB LED blinking.

- Clock division of the system clock
- LED control using a counter
- Constraint file (XDC) settings

### 02_blinkspeed

Learn how to control the LED blink speed by button input.

- Debounce circuit implementation
- User input handling

### 03_pattern

Display patterns via HDMI output.

- Sync signal generation (syncgen)
- Pixel clock generation (pckgen)
- HDMI output control

### 04_gradation

An HDMI output application using gradation display.

### 05_Zynq7000

A project that integrates the Zynq SoC PS (Processing System) and PL (Programmable Logic).

- Using the Vitis development environment
- UART communication
- PS-PL integration

### PS_LCD_test

A test project for LCD control from the PS side.

## Development Environment

- **Vivado**: 2023.2
- **Vitis**: 2023.2

## References

The following materials are included in the `documents/` folder:

- EBAZ4205 schematics, manuals, PCB data, Linux image (`documents/EBAZ4205/`)
- Zynq-7000 TRM (Technical Reference Manual) (`documents/xilinx_user_guide/`)
- Boot images (`documents/TF_boot_image/`)
- Ethernet PHY documents (`documents/ether_phy/`)

## Where to Buy (Reference)

- https://ja.aliexpress.com/item/1005006074065888.html

## License

MIT License

Copyright (c) 2025 tomorrow56 A.K.A. ThousanDIY

## Acknowledgements

Some of the code is based on samples from [Cobac.Net](https://www.cobac.net/).
