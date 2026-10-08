# BSP regression checklist

Static checks compare the device trees and recipes in `meta-odyssey`.
Hardware checks are a boot of the SD image built from this tree after the
Linux UART4 change. Raw image SHA256
`005c9c0e5542591504c9a667cbde519a9e58fdda2edcd5270537fdcee992f47f`.

| Item | Static check | Static result | Hardware result |
| --- | --- | --- | --- |
| SD boot | TF-A, OP-TEE, U-Boot, and Linux board trees present. Flash layout is SD / OP-TEE | Pass | Pass. Linux boots from SD |
| DDR initialization | Memory `0xc0000000` / `0x20000000`. Firmware config `DDR_SIZE 0x20000000`. OP-TEE `CFG_DRAM_SIZE=0x20000000` | Pass | Pass. Linux reached userspace |
| UART4 console | `serial0` is `&uart4`. `stdout-path` is `serial0:115200n8`. Linux status okay at `serial@40010000` | Pass | Pass. `/dev/ttySTM0` works |
| UART4 pinctrl | Linux has no UART4 `pinctrl-*`, `dmas`, or `dma-names`, and no `uart4_pins_odyssey` group. TF-A, OP-TEE, and U-Boot still mux PA13 AF8 and PE5 AF8. OP-TEE secure locks remain | Pass | Pass. The Linux PA13 access error is gone on this image. Suspend/resume not tested |
| SDMMC1 | 4-bit SD, card detect, SCMI LDO5 | Pass | Pass. Root filesystem is mounted |
| SDMMC2 / eMMC | 8-bit non-removable node present. Boot device label is `sdcard` only | Description present | Detected as a 3.5 GiB device. Boot from eMMC not tested |
| Ethernet 1 and 2 | RMII nodes, PHY id, resets, supplies | Pass | Link pass. `end0` and `end1` are UP and LOWER_UP. Traffic regression not tested on this image |
| USB host | EHCI/OHCI on USB PHY port 0 | Pass | Controllers enumerate. Mass storage not retested on this image |
| PMIC and SCMI | STPMIC1, EXTI 55, LDO4, LDO5, PWR_SW2 | Pass | Pass on the previous image. Not repeated after the UART4 rebuild |
| CPUFreq and thermal | SoC nodes left in place | Pass | Pass on the previous image. Not repeated after the UART4 rebuild |
| ETZPC | DDRCTRLPHY, SDMMC, Ethernet, USB. LTDC cell absent | Pass | Not repeated as a separate check on this image |
| Watchdog | TF-A `&iwdg2` disabled. Linux `&arm_wdt` 32 s and okay. No OTP or fuse content | Pass | Not retested on this image |
| systemd | `st-image-core` | Not a device-tree check | Pass. `systemctl --failed` is empty |

## Not in the layer

- `panel-odyssey`, backlight, PI7 enable, PB13 backlight, LTDC pinctrl, `&ltdc`
- OP-TEE LTDC `DECPROT` cell
- `0002-odyssey-temporary-deferred-probe-log.patch`
