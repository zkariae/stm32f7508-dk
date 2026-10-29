/* SPDX-License-Identifier: MIT */
/*!
****************************
\file       linker/qspi.ld
\brief      Linker script for images run in place from the QSPI flash.

\author     Z. BEN-AKKA
\version    1.2
\date       29/10/2026

\details
  Code at 0x90000000 (N25Q128A, 16 MB, memory-mapped by a bootloader such
  as 08-custombootloader). The RAM is split as in internal-flash.ld:
  - DTCM, 64 KB at 0x20000000: .data, .bss and the stack, which grows down
    from the top of the DTCM and so can never reach the framebuffer.
  - SRAM, 256 KB at 0x20010000 (SRAM1 240 KB + SRAM2 16 KB): the
    .framebuffer section, neither copied nor zeroed at reset.
  The link fails if less than _min_stack is left for the stack.

\section qspi_ld_version_history Version history
| Version | Date       | Author      | Description                                 |
|:-------:|:----------:|:------------|:--------------------------------------------|
| 1.0     | 08/10/2026 | Z. BEN-AKKA | Initial version.                            |
| 1.1     | 10/10/2026 | Z. BEN-AKKA | Header per Contributing.md.                 |
| 1.2     | 29/10/2026 | Z. BEN-AKKA | Stack in DTCM, framebuffer section in SRAM. |
****************************
*/

ENTRY(Reset_Handler)

MEMORY
{
    QSPI  (rx)  : ORIGIN = 0x90000000, LENGTH = 16M
    DTCM  (rwx) : ORIGIN = 0x20000000, LENGTH = 64K    /* CPU only, zero wait state */
    SRAM  (rwx) : ORIGIN = 0x20010000, LENGTH = 256K   /* SRAM1 240K + SRAM2 16K, reached by the LTDC */
}

_estack = ORIGIN(DTCM) + LENGTH(DTCM);   /* stack at the top of the DTCM, never under the framebuffer */
_min_stack = 16K;

SECTIONS
{
    .isr_vector :
    {
        KEEP(*(.isr_vector))           /* must be first: the bootloader reads SP and PC here */
    } > QSPI

    .text :
    {
        *(.text*)
        *(.rodata*)
    } > QSPI

    /* Initialised data: stored in QSPI, addressed in DTCM */
    _sidata = LOADADDR(.data);
    .data :
    {
        _sdata = .;
        *(.data*)
        _edata = .;
    } > DTCM AT > QSPI

    .bss :
    {
        _sbss = .;
        *(.bss*)
        *(COMMON)
        _ebss = .;
    } > DTCM

    /* Framebuffers: not loaded, the application draws every pixel before showing them */
    .framebuffer (NOLOAD) :
    {
        . = ALIGN(8);
        *(.framebuffer*)
    } > SRAM

    ASSERT(_ebss + _min_stack <= _estack, "less than _min_stack left for the stack in DTCM")
}
