# stm32f7508-dk

Board support for the **STM32F7508-DK** discovery kit (STM32F750N8, Cortex-M7),
for register-level, bare-metal C firmware: no HAL, no CMSIS.

This repository is the board side of
[stm32f7508-dk-baremetal](https://github.com/zkariae/stm32f7508-dk-baremetal),
where it lives as a Git submodule at `stm32f7508-dk/`. It describes the
hardware and how to build for it and program it; what to build (the
applications, the generic drivers) is in the main repository (`../dev`,
`../Makefile`).

## Contents

| File            | Role                                                                 |
|:----------------|:---------------------------------------------------------------------|
| `mcu.h`         | STM32F750N8 registers, bit fields and memory map (RM0385)            |
| `board.h/.c`    | Pins, RK043FN48H LCD panel, N25Q128A QSPI flash, and the descriptors passed to the drivers (`BOARD_LED_LD1`, `BOARD_UART_VCP`, `BOARD_LCD_TIMING`...) |
| `startup.c`     | Vector table, reset handler, entry into the ROM DFU when USER is held |
| `linker/`       | Memory layouts: internal flash, and execute-in-place from QSPI       |
| `board.mk`      | Toolchain, board sources, memories (`flash`, `qspi`) and the recipes the root Makefile calls: `board_compile`, `board_link`, `board_flash`, `board_dfu`, `board_reset`... |
| `.clang-format` | Code style; keep identical to `dev/.clang-format`                    |

## Contract with dev/

Every board provides `mcu.h` (registers, included by the drivers),
`board.h` (wiring, included by the applications) and `board.mk` (build
description, included by the root Makefile). A new board is a new
repository with the same three files.

## Usage

From the root of the main repository:

```sh
git submodule update --init      # after cloning the main repository
make 01-blink-flash             # build and flash with the ST-LINK
make help                       # every target
```

## License

MIT, see [LICENSE](LICENSE).
