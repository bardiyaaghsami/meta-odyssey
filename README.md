# ODYSSEY STM32MP135D Yocto BSP

Board support for the Seeed Studio ODYSSEY STM32MP135D (STM32MP135D,
one Cortex-A7, 512 MiB DDR3L) on OpenSTLinux v6.2.1, Yocto Scarthgap 5.0.17.

`meta-odyssey` is the machine layer: machine configuration, board device
trees, and two bbappends. OpenSTLinux itself is not in this git tree.
`./scripts/setup.sh` fetches the pinned manifest into `sources/`. Download
and sstate caches stay on the build machine and are gitignored.

## Build

Host packages, the AppArmor sysctl BitBake needs on Ubuntu 24.04, and the
ST EULA variable are in [docs/build.md](docs/build.md).

```bash
./scripts/setup.sh
./scripts/build.sh
./scripts/create-sdcard.sh
```

That produces `st-image-core` and an SD raw image. It does not write a
block device. Flashing is [docs/flashing.md](docs/flashing.md).

## What was tested

The SD image from this tree boots Linux. On that card:

- UART4 console, `/dev/ttySTM0`, 115200 8N1
- root filesystem mounted from SD
- `end0` and `end1` report UP and LOWER_UP
- eMMC shows up as a 3.5 GiB device
- USB host controllers enumerate
- `systemctl --failed` prints nothing

Link state is not a traffic test. eMMC detection is not an eMMC boot.
USB host enumeration is not a mass-storage test. OP-TEE, SCMI, CPUFreq,
and thermal were checked on the previous image from this tree, before the
Linux UART4 pinctrl change, and were not repeated. Suspend and resume
were not tested. Details and checksums are in
[docs/BUILD_VALIDATION_REPORT.md](docs/BUILD_VALIDATION_REPORT.md). Open
items are in [docs/known-issues.md](docs/known-issues.md).

LCD panel, backlight, touch, Qt, Weston as a product image, Web HMI, and
Modbus are not part of v0.1.0. The boot device label is `sdcard` only.
TF-A leaves IWDG2 disabled; see the known-issues note before treating that
as a watchdog policy.

## Baseline

| Item | Value |
| --- | --- |
| OpenSTLinux | v6.2.1 |
| Manifest tag | `openstlinux-6.6-yocto-scarthgap-mpu-v26.06.10` |
| Manifest commit | `71e658b9a8cff67bef0f53a3543dad19d61380f2` |
| Yocto | 5.0.17 Scarthgap |
| BitBake | 2.8.1 |
| Kernel | Linux 6.6.129-stm32mp-r3.1 |
| TF-A | v2.10.24-stm32mp-r3.1 |
| U-Boot | v2023.10-stm32mp-r3.1 |
| OP-TEE | 4.0.0-stm32mp-r3.1 |
| Distro | `openstlinux-weston` |
| Machine | `odyssey-stm32mp135d` |
| Image | `st-image-core` |

`setup.sh` checks these layer revisions and stops if a checkout differs:
[manifests/openstlinux-6.2.1.md](manifests/openstlinux-6.2.1.md),
`scripts/layer-revisions.txt`.

## Layout

```text
meta-odyssey/     machine, board device trees, bbappends
scripts/          setup, build, SD image, flash
manifests/        pinned OpenSTLinux tag and layer revisions
docs/             build, hardware, license, validation
```

Pinmux and regulator notes: [docs/hardware.md](docs/hardware.md).
Boot chain: [docs/architecture.md](docs/architecture.md).

## License

Files written here are MIT ([LICENSE](LICENSE)). The board device trees
keep their SPDX lines and name STMicroelectronics and the Seeed Studio /
xogium trees they follow. Fetched OpenSTLinux stays under its own
licenses. See [docs/licensing.md](docs/licensing.md).

Patches belong in `meta-odyssey`, `scripts/`, and `docs/`. Do not commit
`sources/`, download caches, or images. Do not program OTP or fuses.
