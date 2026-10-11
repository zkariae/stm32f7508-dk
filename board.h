// SPDX-License-Identifier: MIT
/*!
****************************
\file       stm32f7508-dk/board.h
\brief      STM32F7508-DK wiring: pins, panel, QSPI flash, board descriptors.

\author     Z. BEN-AKKA
\version    1.0
\date       11/10/2026

\details
  Every board provides board.h; the applications include it. It describes
  the hardware around the MCU (UM2470, MB1191 schematic) and gives the
  generic drivers of dev/common the descriptors they take as parameters.

\section board_board_h_version_history Version history
| Version | Date       | Author      | Description                                   |
|:-------:|:----------:|:------------|:----------------------------------------------|
| 1.0     | 11/10/2026 | Z. BEN-AKKA | Board wiring and descriptors, from defines.h. |
****************************
*/

#ifndef BOARD_H
#define BOARD_H

#include <stdint.h>

#include "mcu.h"

#include "led/led.h"
#include "ltdc/ltdc.h"
#include "uart/uart.h"

/* Board - STM32F7508-DK (UM2470, MB1191 schematic) */
#define HSE_HZ 25000000UL ///< External crystal.

#define LED_PIN         1  ///< PI1, LD1 green, active high.
#define USER_BUTTON_PIN 11 ///< PI11, B1 blue, high when pressed.
#define VCP_TX_PIN      9  ///< PA9, USART1_TX to the ST-LINK virtual COM port.
#define LCD_DISP_PIN    12 ///< PI12, LCD_DISP: panel enable.
#define LCD_BL_PIN      3  ///< PK3, LCD_BL_CTRL: backlight enable.

/* Panel - RK043FN48H, 480x272. Back porches include the sync pulse:
 * 1 + 42 + 480 + 8 = 531 clocks per line, 10 + 2 + 272 + 4 = 288 lines. */
#define LCD_WIDTH  480U
#define LCD_HEIGHT 272U
#define LCD_HSW    1U  ///< Horizontal sync width, pixel clocks.
#define LCD_HBP    42U ///< Horizontal back porch.
#define LCD_HFP    8U  ///< Horizontal front porch.
#define LCD_VSW    10U ///< Vertical sync width, lines.
#define LCD_VBP    2U  ///< Vertical back porch.
#define LCD_VFP    4U  ///< Vertical front porch.

/* QSPI flash - Micron N25Q128A, 16 MB */
#define N25Q_CMD_QUAD_OUT_READ 0x6B       ///< 1-1-4: instruction and address on 1 line, data on 4.
#define N25Q_QUAD_OUT_DUMMY    8          ///< Power-on default dummy cycles for 0x6B.
#define N25Q128A_SIZE_LOG2     24         ///< 2^24 bytes = 16 MB.
#define N25Q128A_ID            0x18BA20UL ///< Manufacturer 0x20, type 0xBA, 128 Mbit; LSB first.

extern const Led BOARD_LED_LD1;           ///< LD1 green, PI1, active high.
extern const Uart BOARD_UART_VCP;         ///< USART1 TX on PA9, to the ST-LINK virtual COM port.
extern const LtdcTiming BOARD_LCD_TIMING; ///< RK043FN48H panel, 480x272.

/*!
\brief  Clock the ports and set the 28 LTDC signals of the panel to AF14.
*/
void BoardLcdPinsInit(void);

/*!
\brief  Enable the panel (PI12), then its backlight (PK3) 20 ms later.
\details Uses DelayMs(): SysTick must be running.
*/
void BoardLcdPowerOn(void);

/*!
\brief  Switch the panel backlight on.
*/
void BoardLcdBacklightOn(void);

/*!
\brief  Switch the panel backlight off.
*/
void BoardLcdBacklightOff(void);

/*!
\brief  Clock the ports and set the six QSPI flash signals to their AF.
*/
void BoardQspiPinsInit(void);

#endif
