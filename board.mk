# SPDX-License-Identifier: MIT
# /*!
# ****************************
# \file       stm32f7508-dk/board.mk
# \brief      STM32F7508-DK description for the build: CPU, board files, memories.
#
# \author     Z. BEN-AKKA
# \version    1.0
# \date       11/10/2026
#
# \details
#   Included by the Makefile of the repository root, which builds the
#   applications; nothing here depends on them. BOARD_DIR is set by that
#   Makefile to this folder. Every board provides the same variables:
#     CROSS, BOARD_ARCH, BOARD_CFLAGS, BOARD_SRCS   toolchain and board files
#     BOARD_MEMORIES, BOARD_DEFAULT_MEMORY          where an image can live
#     MEMORY_<m>_LDSCRIPT, _ADDR, _OPENOCD, _DFU     how to link and program it
#     BOARD_OPENOCD                                 OpenOCD config for reset
#
# \section board_mk_version_history Version history
# | Version | Date       | Author      | Description                                  |
# |:-------:|:----------:|:------------|:---------------------------------------------|
# | 1.0     | 11/10/2026 | Z. BEN-AKKA | Board part of the former board Makefile.     |
# ****************************
# */

# Cortex-M7. -mfloat-abi=soft is explicit on purpose: the M7 has an FPU, but
# the coprocessor is never enabled, so any VFP instruction would fault.
CROSS      := arm-none-eabi-
BOARD_ARCH := -mcpu=cortex-m7 -mthumb -mfloat-abi=soft

# mcu.h and board.h, then the board sources linked into every image
BOARD_CFLAGS := -I$(BOARD_DIR)
BOARD_SRCS   := $(BOARD_DIR)/startup.c $(BOARD_DIR)/board.c

# Memories an image can be linked into
BOARD_MEMORIES       := flash qspi
BOARD_DEFAULT_MEMORY := flash

# Internal flash, 64 KB; also reachable by the ST ROM bootloader (USB DFU)
MEMORY_flash_LDSCRIPT := $(BOARD_DIR)/linker/internal-flash.ld
MEMORY_flash_ADDR     := 0x08000000
MEMORY_flash_OPENOCD  := -f interface/stlink.cfg -f target/stm32f7x.cfg
MEMORY_flash_DFU      := yes

# N25Q128A QSPI flash, 16 MB, executed in place once a bootloader maps it.
# The OpenOCD board config adds the stmqspi bank and sets up the QSPI pins.
MEMORY_qspi_LDSCRIPT := $(BOARD_DIR)/linker/qspi.ld
MEMORY_qspi_ADDR     := 0x90000000
MEMORY_qspi_OPENOCD  := -f board/stm32f746g-disco.cfg
MEMORY_qspi_DFU      :=

BOARD_OPENOCD := $(MEMORY_flash_OPENOCD)
