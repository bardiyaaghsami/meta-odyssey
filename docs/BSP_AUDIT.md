# BSP audit — ODYSSEY STM32MP135D

Historical Phase 1 record from 2026-10-07. It describes the tree that was
inspected before `meta-odyssey` existed. It is not the v0.1.0 status.
Current results are in [BUILD_VALIDATION_REPORT.md](BUILD_VALIDATION_REPORT.md).

Phase 1 only. This document records the workspace as inspected on 2026-10-07.
No board-support file was edited, renamed, or deleted for this audit.

The public v0.1.0 baseline must be taken from the **working tree**, not from
`HEAD` alone. Several hardware fixes that the board now boots with are still
uncommitted. One uncommitted TF-A change disables the watchdog and needs a
decision before it is copied.

## Classification

| Class | Meaning |
| --- | --- |
| A | Generic ODYSSEY board support. Keep in the public BSP. |
| B | PATVAZ or product framing. Names and narrative only. No application recipes exist. |
| C | Experimental LCD / panel work. Exclude from public v0.1.0. |
| D | Generated file or upstream checkout. Do not commit. |
| E | Needs a decision before the public baseline copies it. |

## Baseline

| Item | Value | Source |
| --- | --- | --- |
| Board | Seeed Studio ODYSSEY STM32MP135D | machine description |
| OpenSTLinux | v6.2.1, tag `openstlinux-6.6-yocto-scarthgap-mpu-v26.06.10` | `scripts/workspace.env` |
| Manifest | `https://github.com/STMicroelectronics/oe-manifest.git` | `scripts/workspace.env` |
| Yocto | 5.0.17 Scarthgap, BitBake 2.8.1 | `docs/workspace.md`, recorded from that tag |
| Distro used by the working build | `openstlinux-weston` | `scripts/workspace.env` |
| Image | `st-image-core` | `scripts/workspace.env` |
| Machine | `odyssey-stm32mp135d` | `conf/machine/odyssey-stm32mp135d.conf` |
| Kernel | `linux-stm32mp` 6.6.129-stm32mp-r3.1 | `docs/odyssey-build.md` |
| TF-A | `tf-a-stm32mp` v2.10.24-stm32mp-r3.1 | `docs/odyssey-build.md` |
| U-Boot | `u-boot-stm32mp` v2023.10-stm32mp-r3.1 | `docs/odyssey-build.md` |
| OP-TEE | `optee-os-stm32mp` 4.0.0-stm32mp-r3.1 | `docs/odyssey-build.md` |

`openstlinux-weston` is the ST distribution name used to initialize the
environment. The built image is `st-image-core`. The current rootfs manifest
(`st-image-core-openstlinux-weston-odyssey-stm32mp135d.rootfs.manifest`,
1123 packages) contains no `weston`, `qtbase`, `qtdeclarative`, `wayland`, or
Modbus package. `kernel-module-qt1070` is the upstream Atmel AT42QT1070
kernel module, not the Qt toolkit. `libdrm-tests` and several upstream panel
kernel modules are present because they come from the ST kernel configuration
and `st-image-core`, not from a project recipe.

There is no custom image recipe, no `meta-qt6`, and no application layer.

## Repository map

Tracked project content is 27 files. `sources/` is an OpenSTLinux `repo`
checkout and is gitignored except `sources/layers/meta-patvaz/`.

| Path | Class | Role |
| --- | --- | --- |
| `sources/layers/meta-patvaz/` | A, with B in the name | The only custom Yocto layer |
| `scripts/workspace.env` | A | Pins the ST tag, distro, default machine, and image |
| `scripts/fetch-sources.sh` | A | `repo init` / `repo sync` of the pinned manifest. Refuses a different tag |
| `scripts/setup-env.sh` | A | Sources ST `envsetup.sh`, selects the machine, appends the project layer |
| `scripts/lib/common.sh` | A | Host-package checks and path helpers. Function prefix is `patvaz_` |
| `scripts/check-workspace.sh` | A | Read-only workspace check. Default expected machine is still `stm32mp13-disco` |
| `scripts/inspect-deploy.sh` | A | Read-only deploy listing. Also defaults to `stm32mp13-disco` |
| `README.md` | B | Describes a future HMI, Weston, and Qt 6. Those are not in the layer |
| `docs/*.md` | A as engineering notes | Milestone notes. `docs/odyssey-build.md` is stale about display |
| `.gitignore` | A | Ignores the ST checkout, `build/`, downloads, and sstate. Does not yet list `*.raw` |
| `sources/` except `meta-patvaz` | D | Upstream OpenSTLinux. Not part of this git repository |
| `sources/build-openstlinuxweston-*` | D | BitBake build directories |
| `build` | D | Symlink created by `setup-env.sh` |
| `downloads/`, `sstate-cache/` | D | Shared caches |

No `LICENSE` or `COPYING` file exists at the project root. No flash script
exists in this repository. SD-card RAW images are produced by the upstream
script `scripts/create_sdcard_from_flashlayout.sh` inside the ST build
directory, from:

`flashlayout_st-image-core/optee/FlashLayout_sdcard_stm32mp135d-odyssey-optee.tsv`

## Layer and machine

`sources/layers/meta-patvaz/conf/layer.conf`

- Collection name `patvaz`, priority 8, series `scarthgap`.
- `LAYERDEPENDS_patvaz = "core openembedded-layer stm-st-stm32mp st-openstlinux"`.
- `BBFILES` searches `recipes-*/*/*.bb` and `*.bbappend` only. No nested recipe directories are missed today, but a deeper tree would be invisible.

`sources/layers/meta-patvaz/conf/machine/odyssey-stm32mp135d.conf`

- Class A.
- `MACHINEOVERRIDES` prepends `stm32mp1common:stm32mp13common:`.
- Includes `st-machine-common-stm32mp.inc`, `st-machine-providers-stm32mp.inc`, and `tune-cortexa7.inc`.
- `DEFAULTTUNE = "cortexa7thf-neon-vfpv4"`.
- `BOOTSCHEME_LABELS += "optee"` and `BOOTDEVICE_LABELS += "sdcard"`.
- `STM32MP_DT_FILES_SDCARD += "stm32mp135d-odyssey"`.
- `MACHINE_FEATURES` adds `watchdog`, `nosmp`, and `usbg0`.
- `ST_OPTEE_EXPORT_TA_REF_BOARD:stm32mp1common = "stm32mp135d-odyssey.dts"`.
- Does not inherit the STM32MP135F-DK device tree.
- Does not set `IMAGE_INSTALL` or any product package.

`setup-env.sh` writes two generated files into the ST checkout because
`envsetup.sh` only searches `layers/meta-st` for `${MACHINE}.conf`:

- `sources/layers/meta-st/meta-st-stm32mp/conf/machine/odyssey-stm32mp135d.conf` (stub, class D)
- `sources/layers/meta-st/meta-st-stm32mp/conf/eula/odyssey-stm32mp135d` (symlink to `stm32mp13-disco`, class D)

BitBake loads the real machine file from `meta-patvaz` because that layer has
higher priority. The script also appends this line to the generated
`bblayers.conf` when it is missing:

```
BBLAYERS += "${OEROOT}/layers/meta-patvaz"
```

`local.conf` is generated by ST `envsetup.sh`. It is not a project file.
`BUILDDIR` for this machine is
`sources/build-openstlinuxweston-odyssey-stm32mp135d`.

## Recipes, appends, and patches

The layer contains two recipe files and one patch. There is no
`recipes-kernel` append. `recipes-kernel/README` states that Linux board
support is the external device tree only.

### `recipes-bsp/external-dt/external-dt_6.0.bbappend` — A

This is the integration point required by `meta-st-stm32mp`. It must be
preserved, not replaced by editing ST layers.

- `FILESEXTRAPATHS` and `SRC_URI:append:odyssey-stm32mp135d` add the six board device trees.
- `do_install_patvaz_dt` runs after `do_symlink_externaldtsrc` and before `do_configure`.
- It installs the trees under `${S}/stm32mp1/{tf-a,u-boot,linux,optee}`.
- It inserts `stm32mp135d-odyssey.dtb` into the U-Boot and Linux external-dt Makefiles beside `stm32mp135f-dk-ostl.dtb`.
- It appends an ODYSSEY flavor to `stm32mp1/optee/conf.mk`:
  - `flavor_dts_file-135D_ODYSSEY = stm32mp135d-odyssey.dts`
  - added to `flavorlist-MP13`
  - added to `flavorlist-no_cryp-512M`

The task name `do_install_patvaz_dt` is product-branded. The behavior is board support.

### `recipes-security/optee/optee-os-stm32mp_%.bbappend`

Committed part, class A:

```
EXTRA_OEMAKE:append:odyssey-stm32mp135d = " CFG_STM32MP13=y CFG_DRAM_SIZE=0x20000000"
ST_OPTEE_EXPORT_TA_OEMAKE_EXTRA:odyssey-stm32mp135d = "CFG_EXT_DTS=${STAGING_EXTDT_DIR}/${EXTDT_DIR_OPTEE}"
```

`CFG_STM32MP13=y` keeps the build on STM32MP13. `CFG_DRAM_SIZE=0x20000000`
matches the 512 MiB DDR node and `stm32mp13-ddr3-1x4Gb-1066-binF.dtsi`.
Without those settings OP-TEE selects STM32MP15 and 1 GiB.

Uncommitted part, class E, exclude from v0.1.0:

`SRC_URI` adds `0002-odyssey-temporary-deferred-probe-log.patch`. The patch
prints `*** ODYSSEY DEFERRED DRIVER DIAGNOSTIC ***` from `core/kernel/dt_driver.c`
on the probe-failure path. Probe order and the panic decision are unchanged.
The file header says to remove it after the diagnostic. It is untracked.

## Device trees

All six board trees carry an SPDX line. Five use `(GPL-2.0+ OR BSD-3-Clause)`.
`stm32mp135d-odyssey-u-boot.dtsi` uses `GPL-2.0-or-later OR BSD-3-Clause`.
Comments attribute content to ST `stm32mp135f-dk.dts` and to Seeed/xogium tags
`v2.8-stm32mp-odyssey-r1` (TF-A) and `v6.1-stm32mp-odyssey-r4` (Linux), retargeted
onto the Scarthgap labels. DDR timings are the current ST include
`stm32mp13-ddr3-1x4Gb-1066-binF.dtsi`, not a private copy. Compatible is
`st,stm32mp135d-odyssey`, `st,stm32mp135`. CRYP/SAES and the Discovery kit
panel, Wi-Fi SDIO, and Type-C controller are not enabled.

### TF-A `tf-a/stm32mp135d-odyssey.dts` — A, plus one E delta

Committed board support:

- 512 MiB at `0xc0000000`.
- Fixed `vin` 5 V and `v3v3_ao` 3.3 V.
- `&bsec` `board_id@f0` with `st,non-secure-otp` only. No fuse programming.
- `&cpu0 { cpu-supply = <&vddcpu>; }`.
- `&ddr` supplied by `vdd_ddr` and `vref_ddr`.
- STPMIC1 at I2C4 address `0x33`. Buck1 `vddcpu` is 1.25–1.35 V. Buck2 `vdd_ddr` is 1.35 V. Buck3 `vdd` is 3.3 V.
- HSE-based PLL1/PLL2/PLL3/PLL4. PLL4 VCO is 600 MHz, `st,pll_div_pqr = <11 59 5>`. SDMMC1 and SDMMC2 use `CLK_SDMMC*_PLL4P`.
- SDMMC1 4-bit SD, `vmmc-supply = <&vdd_sd>`, `disable-wp`.
- SDMMC2 8-bit eMMC, non-removable, DDR 3.3 V, no 1.8 V. Description is present. eMMC boot is not a second flash layout.
- UART4 on PA13 AF8 TX and PE5 AF8 RX, 115200. I2C4 on PE15 SCL and PB7 SDA.
- `&hash` and `&rng` okay. `&uart8` and `&usart1` disabled.

Uncommitted delta, class E:

`HEAD` has `&iwdg2 { timeout-sec = <32>; status = "okay"; }`.
The working tree replaces that with `&iwdg2 { status = "disabled"; }`.
That is the entire TF-A diff (3 lines). Do not copy the disable into v0.1.0
until it is explicitly accepted. The public baseline should keep the committed
32-second watchdog.

`tf-a/stm32mp135d-odyssey-fw-config.dts` is class A. It sets `DDR_SIZE` to
`0x20000000` and includes the current STM32MP13 firmware-config fragments.

### OP-TEE `optee/stm32mp135d-odyssey.dts`

`HEAD` is an incomplete board tree: PMIC wakeup is `st,wakeup-pin-number = <1>`
and `st,notif-it-id = <0>`, and the SCMI, ETZPC, secure-GPIO, CPU-supply, and
`pwr_irq` nodes are absent. The working tree adds 70 lines. Those lines are
what the booting board uses.

Keep in v0.1.0 (class A, currently uncommitted):

| Node | Why it is board support |
| --- | --- |
| PMIC `interrupts-extended = <&exti 55 IRQ_TYPE_EDGE_FALLING>`, `wakeup-source`, `st,pmic-it-id = <IT_PONKEY_F IT_PONKEY_R>`, `st,notif-it-id = <0 2>` | STPMIC1 interrupt binding used by the booting firmware |
| `&cpu0 { cpu-supply = <&vddcpu>; }` | CPU regulator. Buck1 range is unchanged |
| `&scmi_regu` `voltd-vdd-usb` = `VOLTD_SCMI_STPMIC1_LDO4` / `&vdd_usb` | USB PHY supply exported to Linux |
| `&scmi_regu` `voltd-vdd-sd` = `VOLTD_SCMI_STPMIC1_LDO5` / `&vdd_sd` | SD/eMMC supply exported to Linux |
| `&scmi_regu` `voltd-v3v3-sw` = `VOLTD_SCMI_STPMIC1_PWR_SW2` / `&v3v3_sw` | Ethernet 2 PHY and USB-A VBUS |
| `&gpioa` `TZPROT(13)` | UART4 TX stays secure |
| `&gpiob` `TZPROT(7)` | I2C4 SDA stays secure |
| `&gpioe` `TZPROT(5)` and `TZPROT(15)` | UART4 RX and I2C4 SCL stay secure |
| `&gpiof` `TZPROT(8)` | WKUP1 stays secure |
| `&pwr_irq` wakeup GPIO PF8 active-high, plus five empty slots | PMIC/wakeup interrupt path |
| `&etzpc` DDRCTRLPHY `DECPROT_NS_R_S_W` | Non-secure read / secure write for the DDR controller |
| `&etzpc` SDMMC1, SDMMC2, ETH1, ETH2, OTG, USBPHYCTRL as `DECPROT_NS_RW` | Linux access to the peripherals that are already validated |

Exclude from v0.1.0 (class C, same uncommitted node):

- `DECPROT(STM32MP1_ETZPC_LTDC_ID, DECPROT_NS_RW, DECPROT_UNLOCK)`

That cell opens the display controller for the experimental panel bring-up.
The file header still says LTDC and the panel are not enabled. v0.1.0 should
match that statement. The rest of `&etzpc` stays.

OP-TEE does not describe SDMMC. The header says the OP-TEE STM32MP131 include
has no SDMMC labels, so SD and eMMC stay in TF-A, U-Boot, and Linux.

### U-Boot — A, committed, no local diff

`u-boot/stm32mp135d-odyssey.dts` follows the Linux board tree for UART4,
both RMII Ethernet ports, I2C1 EEPROM, SDMMC1, SDMMC2, USB host, OTG, and the
SCMI regulator labels. It does not contain the panel, backlight, or LTDC nodes.

`u-boot/stm32mp135d-odyssey-u-boot.dtsi`:

- Includes `stm32mp13-u-boot.dtsi`.
- Environment partition `u-boot-env` on SDMMC1.
- FWU metadata store is SDMMC1.
- `bootph-all` on `&sdmmc1`, `&uart4`, and the ODYSSEY UART4 pin groups.
- Does not reuse the Discovery programmer GPIOs. PA13 is UART4 TX.

### Linux `linux/stm32mp135d-odyssey.dts`

Committed tree, class A. This is the v0.1.0 Linux baseline:

- UART4 console, 115200n8, pins PA13 / PE5, DMA properties deleted.
- LEDs on PH2, PC3, PH5, and USB-enable LED PG1.
- Ethernet 1 RMII, PHY `ethernet-phy-id0007.c131` address 0, reset PG3, MAC from EEPROM.
- Ethernet 2 RMII, same PHY ID, reset PA11, `phy-supply = <&scmi_v3v3_sw>`, `st,ext-phyclk`.
- I2C1 EEPROM `atmel,24c256` at `0x50`, write-protect PF12, MAC cells at offset 0 and 0x10.
- SDMMC1 4-bit, card detect PH10, `vmmc-supply = <&scmi_vdd_sd>`.
- SDMMC2 8-bit eMMC, non-removable, 3.3 V DDR, supplies `scmi_vdd_sd`.
- USB host EHCI/OHCI on `usbphyc_port0`, connector `usb-a-connector`, VBUS `scmi_v3v3_sw`.
- USB OTG on `usbphyc_port1`, ID pin PA10 analog.
- SCMI regulator labels for BUCK1, BUCK3, BUCK4, LDO1, LDO4, LDO5, LDO6, and PWR_SW2.
- `&qspi`, `&sai1`, `&spi5`, and `&usart2` disabled.
- `&crc1`, `&dts`, `&rtc`, and `&arm_wdt` okay. Watchdog timeout is 32 seconds.

Uncommitted addition, class C, 132 lines, exclude from v0.1.0:

| Lines | Content |
| --- | --- |
| 88–143 | `sys_3v3` fixed 3.3 V regulator, `backlight-odyssey` (`gpio-backlight` on PB13, active-high, `default-on`), `panel-odyssey` (`panel-dpi`, PI7 `enable-gpios` active-high, historical 800×480 timing at 27 MHz, `data-mapping = "bgr666"`) |
| 471–545 | `ltdc_pins_odyssey`, `ltdc_sleep_pins_odyssey`, and `&ltdc` enabled with that pinctrl and one endpoint to the panel |

The 800×480 timing is historical and experimental. It is not a datasheet-confirmed
timing for FPC070BD40-01/B. There is no touchscreen node and no I2C3, PA4, PI0,
PD7, or PH3 display-touch configuration.

`docs/odyssey-build.md` still says the device trees do not enable LTDC, a panel,
or a backlight. That sentence describes `HEAD`, not the working tree.

## Git state

`HEAD` is `3bafc7d` ("image: record the ODYSSEY SD card flash layout").

Uncommitted, and required to understand the booting board:

| File | Diff | Class |
| --- | --- | --- |
| `optee/stm32mp135d-odyssey.dts` | +70 lines: PMIC IRQ, CPU supply, three SCMI domains, secure GPIOs, `pwr_irq`, ETZPC | A, except the LTDC cell which is C |
| `linux/stm32mp135d-odyssey.dts` | +132 lines: panel, backlight, LTDC | C |
| `tf-a/stm32mp135d-odyssey.dts` | IWDG2 changed from enabled/32 s to `status = "disabled"` | E |
| `optee-os-stm32mp_%.bbappend` | temporary deferred-probe patch | E |
| `optee-os-stm32mp/0002-odyssey-temporary-deferred-probe-log.patch` | untracked | E |

U-Boot, the machine file, the external-dt append, and the firmware-config file
have no local diff.

## v0.1.0 inclusion list

Include:

- Machine `odyssey-stm32mp135d` and a renamed public layer that preserves the external-dt install task, OP-TEE flavor lines, `CFG_STM32MP13`, and `CFG_DRAM_SIZE=0x20000000`.
- All six device-tree files from the working tree, with these edits during migration:
  - Linux: omit lines 88–143 and 471–545.
  - OP-TEE: omit only the LTDC `DECPROT` cell.
  - TF-A: keep `&iwdg2 { timeout-sec = <32>; status = "okay"; }` from `HEAD`.
- UART4, SDMMC1, SDMMC2 description, both Ethernet ports, USB host, OTG PHY, STPMIC1, SCMI domains LDO4/LDO5/PWR_SW2, secure GPIO ownership, and the non-display ETZPC cells.
- The existing fetch/setup scripts, retargeted at the public layer name.
- Upstream SD FlashLayout generation. A new flash script must take an explicit device, show `lsblk`, reject the root disk, print source and destination, and wait for confirmation.

Exclude:

- `panel-odyssey`, `backlight-odyssey`, `sys_3v3`, LTDC pinctrl, and `&ltdc`.
- The LTDC ETZPC cell.
- The temporary OP-TEE diagnostic patch.
- Any PATVAZ application, Web HMI, Modbus, VFD, Qt, QML, or product service. None of these exist as recipes today.
- The OpenSTLinux checkout, build directories, downloads, sstate, and `*.raw` images.

eMMC stays experimental: the SDMMC2 nodes describe the device, and
`BOOTDEVICE_LABELS` contains only `sdcard`.

## Licensing

Do not relicense the device trees. They already declare GPL/BSD SPDX lines and
name ST and Seeed/xogium sources. Project-created files that have no SPDX yet
are the shell scripts, `layer.conf`, the machine conf, READMEs, and this audit.
A project license can cover those new files later. It must not be applied to
the device trees or to the upstream OpenSTLinux trees.

Major upstreams to attribute:

- STMicroelectronics OpenSTLinux `oe-manifest` tag `openstlinux-6.6-yocto-scarthgap-mpu-v26.06.10`
- `meta-st-stm32mp` revision `49046b2a0ad4dc29117025c94838b9befff86f23` (from `docs/workspace.md`)
- TF-A, OP-TEE, U-Boot, and Linux recipes inside that tag
- Seeed/xogium historical board trees cited in the device-tree headers, used as hardware description rather than copied wholesale

## Unresolved

1. Whether the uncommitted IWDG2 disable was intentional. v0.1.0 should not take it by default.
2. The layer collection is named `patvaz`. The public layer should be `meta-odyssey` without deleting `meta-patvaz`.
3. `check-workspace.sh` and `inspect-deploy.sh` still treat `stm32mp13-disco` as the expected machine.
4. `.gitignore` does not yet ignore `*.raw`, `*.wic`, `*.ext4`, `*.tar.xz`, or `*.tar.zst` by name. Those artifacts currently live under the ignored build directory.
5. `docs/odyssey-build.md` predates the display experiment and the uncommitted OP-TEE fixes.
6. No project `LICENSE` file exists.
7. This audit did not rebuild or flash anything.

## Phase 1 record

Inspected: `meta-patvaz` layer, machine, both bbappends, the diagnostic patch, all six device trees, `scripts/*`, `.gitignore`, root `README.md`, `docs/workspace.md`, `docs/odyssey-build.md`, `git status` and `git diff`, and the current `st-image-core` rootfs manifest.

Created: `docs/BSP_AUDIT.md`.

Modified: nothing else.

Next action: stop. Phase 2 (repository skeleton) waits for review of this audit, especially the IWDG2 decision and the v0.1.0 exclusion list.
