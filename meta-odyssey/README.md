# meta-odyssey

Machine layer for the Seeed Studio ODYSSEY STM32MP135D on OpenSTLinux
Scarthgap. Machine name `odyssey-stm32mp135d`, collection `odyssey`,
priority 8.

`scripts/setup.sh` symlinks this directory to `sources/layers/meta-odyssey`
and appends it to `bblayers.conf`. Do not add a second layer that also
installs `odyssey-stm32mp135d.conf`. `build.sh` stops if `meta-patvaz` is
still on `BBLAYERS`.

`recipes-bsp/external-dt/external-dt_6.0.bbappend` copies the board device
trees into ST's `external-dt` tree. TF-A, OP-TEE, U-Boot, and Linux then
build `stm32mp135d-odyssey` from there. There is no kernel bbappend and no
image recipe. The image is `st-image-core`.

`recipes-security/optee/optee-os-stm32mp_%.bbappend` passes
`CFG_STM32MP13=y` and `CFG_DRAM_SIZE=0x20000000` (512 MiB). Without those,
the OP-TEE makefile treats this DT name as an STM32MP15 with 1 GiB of DDR.

Linux UART4 is enabled at `serial@40010000` and does not request PA13 or
PE5. OP-TEE marks those pins secure; TF-A and OP-TEE program the AF8 mux.
The LCD panel, backlight, and touch controller are not enabled. TF-A
`&iwdg2` is `status = "disabled"`. That is so the board can be debugged
without the TF-A watchdog resetting it. It is not a product watchdog
setting, and nothing here writes OTP or fuses.

`COPYING.MIT` applies to files added by this layer. Device trees keep the
SPDX license in each file.
