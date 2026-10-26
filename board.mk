# SPDX-License-Identifier: MIT
# /*!
# ****************************
# \file       stm32f7508-dk/board.mk
# \brief      STM32F7508-DK build: toolchain, board files, memories and recipes.
#
# \author     Z. BEN-AKKA
# \version    1.3
# \date       26/10/2026
#
# \details
#   Included by the Makefile of the repository root, which declares the
#   applications and calls the recipes below; nothing here depends on them.
#   That Makefile sets BOARD_DIR (this folder), PROJECT_CFLAGS (warnings,
#   optimisation, include paths) and TOOLS (host tools). Every board
#   provides the same names:
#     BOARD_SRCS                                  sources linked into every image
#     BOARD_MEMORIES, BOARD_DEFAULT_MEMORY        where an image can live
#     MEMORY_<m>_LDSCRIPT, _ADDR, _DFU            how it is linked and reached
#     board_compile, board_link, board_bin        build recipes, used with $(call)
#     board_flash, board_dfu, board_reset,        programming recipes
#     board_reset_sw
#     board_size, board_disasm, board_sections    inspection recipes
#
# \section board_mk_version_history Version history
# | Version | Date       | Author      | Description                                  |
# |:-------:|:----------:|:------------|:---------------------------------------------|
# | 1.0     | 11/10/2026 | Z. BEN-AKKA | Board part of the former board Makefile.     |
# | 1.1     | 11/10/2026 | Z. BEN-AKKA | Toolchain and recipes for build, flash, DFU. |
# | 1.2     | 23/10/2026 | Z. BEN-AKKA | Run OpenOCD without sudo (udev rule, plugdev). |
# | 1.3     | 26/10/2026 | Z. BEN-AKKA | Add the software reset recipe (SYSRESETREQ).  |
# ****************************
# */

####################################################################
# Toolchain
####################################################################

CROSS   := arm-none-eabi-
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
SIZE    := $(CROSS)size
OBJDUMP := $(CROSS)objdump

# Cortex-M7. -mfloat-abi=soft is explicit on purpose: the M7 has an FPU, but
# the coprocessor is never enabled, so any VFP instruction would fault.
BOARD_ARCH := -mcpu=cortex-m7 -mthumb -mfloat-abi=soft

# Freestanding code, no C library; one section per function so that the
# link drops what is unused. -I: mcu.h and board.h come from this folder.
BOARD_CFLAGS  := $(BOARD_ARCH) -ffunction-sections -fdata-sections
BOARD_CFLAGS  += -nostdlib -ffreestanding -I$(BOARD_DIR)
BOARD_LDFLAGS := $(BOARD_ARCH) -nostdlib -Wl,--gc-sections

# Linked into every image
BOARD_SRCS := $(BOARD_DIR)/startup.c $(BOARD_DIR)/board.c

####################################################################
# Memories
####################################################################

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

####################################################################
# Recipes, called with $(call board_xxx,arguments)
####################################################################

# Compile one C file. $(1): object, $(2): source, $(3): extra flags
board_compile = $(CC) $(BOARD_CFLAGS) $(PROJECT_CFLAGS) $(3) -c $(2) -o $(1)

# Link objects for a memory. $(1): ELF, $(2): objects, $(3): memory, $(4): map file
board_link = $(CC) $(2) $(BOARD_LDFLAGS) -T $(MEMORY_$(3)_LDSCRIPT) -Wl,-Map=$(4) -o $(1)

# Raw binary from an ELF. $(1): binary, $(2): ELF
board_bin = $(OBJCOPY) -O binary $(2) $(1)

# OpenOCD runs as the user: the udev rule shipped with OpenOCD
# (60-openocd.rules) gives the ST-LINK to the plugdev group, so the user must
# be in plugdev. No sudo, so automated test runs need no password.

# Program a binary into a memory with the ST-LINK. $(1): binary, $(2): memory
board_flash = openocd $(MEMORY_$(2)_OPENOCD) -c "program $(1) $(MEMORY_$(2)_ADDR) verify reset exit"

# Program a binary over USB, through the ST ROM bootloader (DFU memories only).
# $(1): binary, $(2): memory
board_dfu = python3 $(TOOLS)/dfu.py --address $(MEMORY_$(2)_ADDR) $(1)

# Reset the board without reprogramming it
board_reset = openocd $(BOARD_OPENOCD) -c "init; reset; exit"

# Software reset: write SYSRESETREQ to the Cortex-M7 AIRCR (VECTKEY 0x05FA).
# The core also pulls NRST, so RCC_CSR reports SFTRSTF and PINRSTF.
board_reset_sw = openocd $(BOARD_OPENOCD) -c "init; mww 0xE000ED0C 0x05FA0004; exit"

# Inspect an ELF. $(1): ELF
board_size     = $(SIZE) $(1)
board_disasm   = $(OBJDUMP) -d $(1)
board_sections = $(OBJDUMP) -h $(1)
