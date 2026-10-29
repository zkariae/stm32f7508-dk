// SPDX-License-Identifier: MIT
/*!
****************************
\file       stm32f7508-dk/board.c
\brief      STM32F7508-DK wiring: pins, panel, QSPI flash, board descriptors.

\author     Z. BEN-AKKA
\version    1.4
\date       29/10/2026

\details
  API documented in board.h.

\section board_board_c_version_history Version history
| Version | Date       | Author      | Description                                   |
|:-------:|:----------:|:------------|:----------------------------------------------|
| 1.0     | 11/10/2026 | Z. BEN-AKKA | Board wiring and descriptors, from defines.h. |
| 1.1     | 16/10/2026 | Z. BEN-AKKA | Add USART1 RX pin to the VCP descriptor.      |
| 1.2     | 16/10/2026 | Z. BEN-AKKA | Map VCP RX to USART1_RX on PB7.               |
| 1.3     | 28/10/2026 | Z. BEN-AKKA | PG12 (LTDC_B4) on AF9, not AF14.              |
| 1.4     | 29/10/2026 | Z. BEN-AKKA | Formatted with clang-format.                  |
****************************
*/

#include "board.h"

#include <stdint.h>

#include "delay/delay.h"
#include "gpio/gpio.h"

const Led BOARD_LED_LD1 = {
    .port = GPIOI_BASE,
    .pin = LED_PIN,
    .active_high = 1,
};

const Uart BOARD_UART_VCP = {
    .base = USART1_BASE,
    .enr = &RCC_APB2ENR,
    .enr_bit = RCC_APB2ENR_USART1EN,
    .tx_port = GPIOA_BASE,
    .tx_pin = VCP_TX_PIN,
    .tx_af = 7, // AF7 = USART1_TX (datasheet, alternate function mapping)
    .rx_port = GPIOB_BASE,
    .rx_pin = 7, // PB7, USART1_RX and ST-LINK VCP_RX.
    .rx_af = 7,  // AF7 = USART1_RX.
};

const LtdcTiming BOARD_LCD_TIMING = {
    .width = LCD_WIDTH,
    .height = LCD_HEIGHT,
    .hsw = LCD_HSW,
    .hbp = LCD_HBP,
    .hfp = LCD_HFP,
    .vsw = LCD_VSW,
    .vbp = LCD_VBP,
    .vfp = LCD_VFP,
};

/// LTDC signals of the panel (MB1191 schematic), on AF14 except PG12 (AF9).
static const struct {
  uint8_t port, pin, af;
} lcd_pins[] = {
    // Red
    {PORT_I, 15, 14},
    {PORT_J, 0, 14},
    {PORT_J, 1, 14},
    {PORT_J, 2, 14},
    {PORT_J, 3, 14},
    {PORT_J, 4, 14},
    {PORT_J, 5, 14},
    {PORT_J, 6, 14},
    // Green
    {PORT_J, 7, 14},
    {PORT_J, 8, 14},
    {PORT_J, 9, 14},
    {PORT_J, 10, 14},
    {PORT_J, 11, 14},
    {PORT_K, 0, 14},
    {PORT_K, 1, 14},
    {PORT_K, 2, 14},
    // Blue
    {PORT_E, 4, 14},
    {PORT_J, 13, 14},
    {PORT_J, 14, 14},
    {PORT_J, 15, 14},
    {PORT_G, 12, 9}, // B4 is AF9 on PG12 (datasheet, alternate function mapping)
    {PORT_K, 4, 14},
    {PORT_K, 5, 14},
    {PORT_K, 6, 14},
    // Control
    {PORT_I, 10, 14}, // HSYNC
    {PORT_I, 9, 14},  // VSYNC
    {PORT_I, 14, 14}, // CLK
    {PORT_K, 7, 14},  // DE
};

#define LCD_PIN_COUNT (sizeof(lcd_pins) / sizeof(lcd_pins[0]))

void BoardLcdPinsInit(void)
{
  for (uint32_t i = 0; i < LCD_PIN_COUNT; i++) {
    GpioEnableClock(GPIO_PORT(lcd_pins[i].port));
    GpioSetAf(GPIO_PORT(lcd_pins[i].port), lcd_pins[i].pin, lcd_pins[i].af);
  }
}

void BoardLcdPowerOn(void)
{
  GpioEnableClock(GPIOI_BASE);
  GpioEnableClock(GPIOK_BASE);

  GpioSetOutput(GPIOI_BASE, LCD_DISP_PIN);
  GpioSetOutput(GPIOK_BASE, LCD_BL_PIN);

  // Panel before backlight, to avoid a flash of noise at power-up
  GpioSet(GPIOI_BASE, LCD_DISP_PIN);
  DelayMs(20);
  GpioSet(GPIOK_BASE, LCD_BL_PIN);
}

void BoardLcdBacklightOn(void)
{
  GpioSet(GPIOK_BASE, LCD_BL_PIN);
}

void BoardLcdBacklightOff(void)
{
  GpioClear(GPIOK_BASE, LCD_BL_PIN);
}

void BoardQspiPinsInit(void)
{
  GpioEnableClock(GPIOB_BASE);
  GpioEnableClock(GPIOD_BASE);
  GpioEnableClock(GPIOE_BASE);

  GpioSetAf(GPIOB_BASE, 2, 9);  // CLK
  GpioSetAf(GPIOB_BASE, 6, 10); // NCS (AF10)
  GpioSetAf(GPIOD_BASE, 11, 9); // IO0
  GpioSetAf(GPIOD_BASE, 12, 9); // IO1
  GpioSetAf(GPIOE_BASE, 2, 9);  // IO2
  GpioSetAf(GPIOD_BASE, 13, 9); // IO3
}
