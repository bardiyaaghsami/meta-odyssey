# Hardware

Seeed Studio ODYSSEY STM32MP135D. This is what the `meta-odyssey` device
trees describe. Boot results are in
[supported-hardware.md](supported-hardware.md) and
[BUILD_VALIDATION_REPORT.md](BUILD_VALIDATION_REPORT.md).

| Function | Board description |
| --- | --- |
| SoC | STM32MP135D, one Cortex-A7. No CRYP/SAES enable. |
| Memory | 512 MiB DDR3L at `0xc0000000` |
| Console | UART4, PA13 TX AF8, PE5 RX AF8, 115200 8N1 |
| PMIC | STPMIC1 at I2C4 `0x33`, SCL PE15, SDA PB7 |
| SD card | SDMMC1, 4-bit, card detect PH10, supply SCMI LDO5 |
| eMMC | SDMMC2, 8-bit, non-removable, 3.3 V DDR. Boot from eMMC is not the v0.1.0 path. |
| Ethernet 1 | RMII, PHY id `0007.c131` address 0, reset PG3, MAC from I2C EEPROM |
| Ethernet 2 | RMII, same PHY id, reset PA11, supply SCMI PWR_SW2 |
| EEPROM | I2C1 `atmel,24c256` at `0x50`, write-protect PF12 |
| USB host | EHCI/OHCI on USB PHY port 0, Type-A connector, VBUS from PWR_SW2 |
| USB OTG | PHY port 1, ID on PA10 |

Secure GPIO locks in the OP-TEE tree: PA13, PB7, PE5, PE15, PF8. UART4,
I2C4, and wakeup use those pins, so they stay secure.

SCMI domains added for this board, on top of the SoC domains already in
the tree: LDO4 (`vdd_usb`), LDO5 (`vdd_sd`), and PWR_SW2 (`v3v3_sw`).

The LCD connector (RGB666, PI7 enable, PB13 backlight, touch on I2C) is
not in v0.1.0. The exclusion list is
[migration-inventory.md](migration-inventory.md).
