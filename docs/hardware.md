# Hardware

Seeed Studio ODYSSEY STM32MP135D. The tables below match the
`meta-odyssey` device trees. The test column is the SD image from this
tree, flashed on 2026-10-08.

## Board

| Function | Connection |
| --- | --- |
| SoC | STM32MP135D, one Cortex-A7. CRYP/SAES left disabled. |
| Memory | 512 MiB DDR3L at `0xc0000000` |
| Console | UART4, PA13 TX AF8, PE5 RX AF8, 115200 8N1 |
| PMIC | STPMIC1, I2C4 address `0x33`, SCL PE15, SDA PB7 |
| SD | SDMMC1, 4-bit, card detect PH10, supply SCMI LDO5 (`vdd_sd`) |
| eMMC | SDMMC2, 8-bit, non-removable, 3.3 V DDR |
| Ethernet 1 | RMII, PHY `0007.c131` address 0, reset PG3, MAC from the EEPROM. Linux: `end0` |
| Ethernet 2 | RMII, same PHY id, reset PA11, supply SCMI PWR_SW2 (`v3v3_sw`). Linux: `end1` |
| EEPROM | I2C1 `atmel,24c256` at `0x50`, write-protect PF12 |
| USB host | EHCI/OHCI, USB PHY port 0, Type-A, VBUS from PWR_SW2 |
| USB OTG | PHY port 1, ID on PA10 |

OP-TEE locks PA13, PB7, PE5, PE15, and PF8. UART4, I2C4, and wakeup use
them. Extra SCMI domains from OP-TEE: LDO4 `vdd_usb`, LDO5 `vdd_sd`,
PWR_SW2 `v3v3_sw`.

## UART4

Linux enables `serial@40010000` (`serial0`,
`stdout-path = "serial0:115200n8"`) and does not request PA13 or PE5.
The node has no `pinctrl-*`, `dmas`, or `dma-names`. TF-A and OP-TEE
program AF8. On the flashed image `/dev/ttySTM0` works. The earlier Linux
lines `Can't access gpio 13` and `Error applying setting` are gone.

Linux therefore has no UART4 pin state to restore. Suspend and resume were
not tested. U-Boot still has `uart4_pins_odyssey` and still requests those
pins. That node was not changed, and the U-Boot console was not rechecked
on its own after the Linux rebuild.

## Watchdogs

TF-A `&iwdg2` is `status = "disabled"` so the TF-A watchdog does not reset
the board during bring-up. A device-tree status does not override a
watchdog the BootROM or option bytes force on. This layer does not read or
write those, and it does not burn fuses.

Linux `&arm_wdt` is a different watchdog. It stays `okay` with
`timeout-sec = <32>`.

## What was tested

Image `stm32mp135d-odyssey-sdcard.raw`, 5153751040 bytes, SHA256
`005c9c0e5542591504c9a667cbde519a9e58fdda2edcd5270537fdcee992f47f`.

Linux DTB `kernel/stm32mp135d-odyssey.dtb`, 63087 bytes, SHA256
`939a21a6bec3eeea5325c1a0fd4f8ae5ed7d9d31bafa0d25a1ba412e2a3c6d7c`.
The DTB in the boot filesystem matches.

| Check | On this image |
| --- | --- |
| Linux from SD | Pass |
| UART4 `/dev/ttySTM0` | Pass |
| PA13 pinctrl error | Pass. Not present |
| SD root filesystem | Pass. Mounted |
| `end0`, `end1` | Link up (UP, LOWER_UP). Traffic not tested |
| eMMC | Detected, 3.5 GiB. Not used as a boot device |
| USB host | Controllers enumerate. Mass storage not tested |
| `systemctl --failed` | Pass. No failed units |
| Suspend / resume | Not tested |

OP-TEE, SCMI, CPUFreq, and thermal passed on the previous image from this
tree, before the UART4 Linux change. They were not run again on this image.

## Not in this release

No panel timing, LTDC, backlight, or touch. OP-TEE does not include the
LTDC ETZPC cell `0x603`. Qt, a Weston product image, Web HMI, and Modbus
are not in the layer. `BOOTDEVICE_LABELS` is `sdcard` only.
