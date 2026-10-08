# Migration inventory

Historical inclusion list. The comparison is in
[BSP_MIGRATION_REPORT.md](BSP_MIGRATION_REPORT.md). Current status is in
[BUILD_VALIDATION_REPORT.md](BUILD_VALIDATION_REPORT.md).

Destination layer: `meta-odyssey/` in this repository.
Phase 3 copied the rows marked for migration. The comparison is in
[BSP_MIGRATION_REPORT.md](BSP_MIGRATION_REPORT.md). This file remains the
inclusion and exclusion list.

Classes:

- **Tested** — required for the board that boots from this layer
- **Experimental display** — exclude from v0.1.0
- **Temporary diagnostic** — exclude; no boot dependency was demonstrated
- **Unverified** — described, not accepted as a finished boot path
- **Later** — project plumbing, not a hardware fix

| Source | Intended destination | Class | Action |
| --- | --- | --- | --- |
| `meta-patvaz/conf/machine/odyssey-stm32mp135d.conf` | `meta-odyssey/conf/machine/odyssey-stm32mp135d.conf` | Tested | Migrate later. Keep `sdcard` only. |
| `meta-patvaz/conf/layer.conf` | `meta-odyssey/conf/layer.conf` | Later | Already replaced by a skeleton. Do not copy the `patvaz` collection name. |
| `external-dt_6.0.bbappend` | `meta-odyssey/recipes-bsp/external-dt/external-dt_6.0.bbappend` | Tested | Migrate the install task. Rename the task so it is not `do_install_patvaz_dt`. |
| `tf-a/stm32mp135d-odyssey.dts` | same path under `meta-odyssey/recipes-bsp/external-dt/stm32mp135d-odyssey/` | Tested | Migrate the working tree, including IWDG2 disabled. |
| `tf-a/stm32mp135d-odyssey-fw-config.dts` | same relative path | Tested | Migrate. `DDR_SIZE` `0x20000000`. |
| `optee/stm32mp135d-odyssey.dts` | same relative path | Tested, with one exclusion | Migrate the working tree. Drop the LTDC `DECPROT` cell. |
| `u-boot/stm32mp135d-odyssey.dts` | same relative path | Tested | Migrate. No display nodes are present. |
| `u-boot/stm32mp135d-odyssey-u-boot.dtsi` | same relative path | Tested | Migrate. |
| `linux/stm32mp135d-odyssey.dts` | same relative path | Tested, with an exclusion | Migrate the committed board tree plus nothing from the 132-line display diff. |
| `optee-os-stm32mp_%.bbappend` `CFG_STM32MP13` and `CFG_DRAM_SIZE=0x20000000` | `meta-odyssey/recipes-security/optee/` | Tested | Migrate those two assignments, including the TA export `CFG_EXT_DTS` line. |
| `optee-os-stm32mp_%.bbappend` diagnostic `SRC_URI` | none | Temporary diagnostic | Do not migrate. |
| `0002-odyssey-temporary-deferred-probe-log.patch` | none | Temporary diagnostic | Do not migrate. |
| Linux `sys_3v3`, `panel-odyssey`, `backlight-odyssey` | none | Experimental display | Do not migrate. |
| Linux `ltdc_pins_odyssey`, `ltdc_sleep_pins_odyssey`, `&ltdc` | none | Experimental display | Do not migrate. |
| OP-TEE LTDC `DECPROT` cell | none | Experimental display | Do not migrate. |
| SDMMC2 / eMMC nodes inside the TF-A, U-Boot, and Linux trees | kept inside those trees | Unverified | Keep the description. Do not add an eMMC flash layout in v0.1.0. |
| `scripts/fetch-sources.sh`, `setup-env.sh`, `lib/common.sh` | `scripts/` in this repository | Later | Rewrite against `meta-odyssey`. Not copied in Phase 2. |
| `scripts/check-workspace.sh`, `inspect-deploy.sh` | `scripts/` | Later | They still assume `stm32mp13-disco` as the default machine. |
| Root `README.md` and milestone `docs/*.md` in the development repo | `docs/` here | Later | Technical facts may be rewritten. Product HMI wording is not copied. |
| ST `envsetup.sh` machine stub and EULA symlink | generated at setup time | Later | Recreate from the public setup script. Do not commit them. |

## Hardware fixes that must remain accounted for

These are in the working OP-TEE or TF-A trees and are not optional cleanups:

1. Secure GPIO ownership for PA13, PB7, PE5, PE15, and PF8.
2. STPMIC1 `interrupts-extended` on EXTI 55, falling edge, with the PONKEY notification ids.
3. `&cpu0 { cpu-supply = <&vddcpu>; }` without changing the Buck1 voltage range.
4. ETZPC `DDRCTRLPHY` as non-secure read / secure write, unlocked.
5. ETZPC non-secure read/write for SDMMC1, SDMMC2, ETH1, ETH2, OTG, and USBPHYCTRL.
6. SCMI voltage domains for LDO4 (`vdd_usb`), LDO5 (`vdd_sd`), and PWR_SW2 (`v3v3_sw`).
7. TF-A IWDG2 left disabled, as a development configuration.

Item 7 is tested and approved. It is still not a production watchdog policy.
