# Build validation report

Date: 2026-10-08. Board: ODYSSEY STM32MP135D.

`st-image-core` built, the SD raw image was generated, and that image
booted from SD after the Linux UART4 pinctrl change. The hardware table
is for that image. Rows marked "previous image" were checked before the
rebuild and were not run again.

## Commands that produced the image

```text
./scripts/setup.sh
./scripts/build.sh
./scripts/create-sdcard.sh
bitbake external-dt
bitbake linux-stm32mp
./scripts/build.sh
./scripts/create-sdcard.sh
```

The second `build.sh` reused sstate. The build directory was not cleaned.
`flash-sdcard.sh` was not used for the boot; the card was written
separately. Nothing was written to eMMC.

## Environment

| Item | Value |
| --- | --- |
| Host | Ubuntu 24.04 |
| OpenSTLinux tag | `openstlinux-6.6-yocto-scarthgap-mpu-v26.06.10` |
| Manifest commit | `71e658b9a8cff67bef0f53a3543dad19d61380f2` |
| BitBake | 2.8.1 |
| Distro | `openstlinux-weston` |
| Distro version string | `5.0.17-snapshot-20261008` |
| Distro codename | `scarthgap` |
| Machine | `odyssey-stm32mp135d` |
| Image | `st-image-core` |
| BUILDDIR | `sources/build-openstlinuxweston-odyssey-stm32mp135d` |
| Kernel | `6.6.129-stm32mp-r3.1` |
| TF-A | `v2.10.24-stm32mp-r3.1` |
| OP-TEE | `4.0.0-stm32mp-r3.1` |
| U-Boot | `v2023.10-stm32mp-r3.1` |

`meta-odyssey` loads at priority 8. Until this layer has a Git commit,
BitBake reports its revision as `<unknown>:<unknown>`.

## Build results

| Check | Status |
| --- | --- |
| `bitbake -p` | PASS. Exit 0. 3047 recipes, 5015 targets, 0 errors |
| MACHINE / DISTRO | PASS. `odyssey-stm32mp135d` / `openstlinux-weston` |
| `meta-odyssey` loaded, second board layer absent | PASS |
| Machine file | PASS. `STM32MP_DT_FILES_SDCARD` includes `stm32mp135d-odyssey` from this layer |
| First `st-image-core` | PASS. Exit 0. 7418 tasks, 5751 seconds, 0 reused from sstate |
| UART4 rebuild of `external-dt` and `linux-stm32mp` | PASS. Installed Linux DTS matches `meta-odyssey` |
| Second `st-image-core` | PASS. Exit 0. 7418 tasks, 7206 not rerun, 250 seconds |
| SD raw image | PASS. 5153751040 bytes. GPT start sectors match the FlashLayout offsets |
| Linux DTB has no experimental LCD | PASS. No `panel-dpi`, `gpio-backlight`, or `bgr666`. Display controller disabled |

The first image build printed three warnings: systemd `/home/root`,
libcamera `ioctl`, and pipewire `fstat64`. None of those recipes failed.
Decompiling the board DTB prints the existing `unique_unit_address`
warnings for shared audio and SPI addresses.

Deploy directory:

`sources/build-openstlinuxweston-odyssey-stm32mp135d/tmp-glibc/deploy/images/odyssey-stm32mp135d`

The Linux DTB model is `Seeed Studio ODYSSEY STM32MP135D`. Memory is
`0xc0000000` / `0x20000000`. `serial@40010000` is okay, with no UART4
`pinctrl-*`, `dmas`, or `dma-names`. `serial0` is that node.
`stdout-path` is `serial0:115200n8`. Both Ethernet controllers and both
SDMMC controllers are okay. `arm,smc-wdt` is okay with `timeout-sec` 32.
The TF-A BL2 DTB sets `watchdog@5a002000` (`iwdg2`) to disabled. The
OP-TEE `st,decprot` value does not contain the LTDC cell `0x603`.

`fip-b` and `u-boot-env` are empty because the TSV binary is `none`.

## SHA256 of the flashed image

Measured from the deploy directory after the UART4 rebuild.

| File | SHA256 |
| --- | --- |
| `kernel/stm32mp135d-odyssey.dtb` | `939a21a6bec3eeea5325c1a0fd4f8ae5ed7d9d31bafa0d25a1ba412e2a3c6d7c` |
| `stm32mp135d-odyssey-sdcard.raw` | `005c9c0e5542591504c9a667cbde519a9e58fdda2edcd5270537fdcee992f47f` |
| `kernel/uImage` | `26edf61ed4609e0032fb496c9c98e977953c300f6434aaa0f4357fc2dbc0f0e9` |
| `st-image-core-openstlinux-weston-odyssey-stm32mp135d.splitted-bootfs.ext4` | `fb308bee86ff4f8d3431e7ed9a795eeed25fff03fa158660cc72a8d3455d343e` |
| `st-image-core-openstlinux-weston-odyssey-stm32mp135d.splitted-rootfs.ext4` | `899098a99b17bf5a74f75d521ab21b6cefb4fa497d0e65ead808286b62e294c3` |
| `arm-trusted-firmware/tf-a-stm32mp135d-odyssey-optee-sdcard.stm32` | `61ef3379ec9b02816fc08d0ce0e72965dd04faa5cb53ef4ff5b9878a93a4a838` |
| `fip/fip-stm32mp135d-odyssey-optee-sdcard.bin` | `1d1fc5c70e0fbc2d932a121d7a5294c154e79cb23adf627bc33c4b8546e58a5f` |
| `optee/tee-pager_v2-stm32mp135d-odyssey-optee.bin` | `8e31fcd717db17f397f71a1970d59f1e6c0c5d503510d73a8b98b1bb09600c6c` |
| `u-boot/u-boot-stm32mp135d-odyssey-default.dtb` | `79772cc010f6d9e9203a038fe1bfcca5f44cb56c57b86c5c8b72d81004a14bb3` |
| `flashlayout_st-image-core/optee/FlashLayout_sdcard_stm32mp135d-odyssey-optee.tsv` | `849233c6c62b1a17a82cb5fa32e419faabf1ebf368b9296987b4e9e1c383345e` |

The Linux DTB is 63087 bytes. The raw image is 5153751040 bytes. The DTB
inside the boot filesystem matches the kernel DTB checksum. TF-A, FIP,
OP-TEE, the U-Boot DTB, and the FlashLayout checksums are the same as the
image from before the Linux UART4 change.

## Hardware boot

Flashed image: `stm32mp135d-odyssey-sdcard.raw` with the checksum above.
Board: ODYSSEY STM32MP135D. Boot device: SD.

| Check | Result |
| --- | --- |
| Linux boots from SD | PASS |
| UART4 `/dev/ttySTM0` | PASS |
| Linux PA13 pinctrl error | PASS. Resolved on this image |
| SD root filesystem mounted | PASS |
| `end0` and `end1` | PASS for link. Both report UP and LOWER_UP |
| Ethernet traffic regression | NOT TESTED on this image |
| eMMC | PASS for detection. 3.5 GiB device. Boot from eMMC NOT TESTED |
| USB host controllers | PASS. Controllers enumerate |
| USB mass storage | NOT TESTED on this image |
| `systemctl --failed` | PASS. Zero failed units |
| OP-TEE, SCMI, CPUFreq, thermal | PASS on the previous image. Not repeated here |
| Suspend / resume | NOT TESTED |

## Other notes

TF-A `iwdg2` is disabled in v0.1.0. A DT `status` does not override a
watchdog forced by BootROM or option bytes. No OTP or fuse was programmed.

After a reboot, Ubuntu 24.04 can set
`kernel.apparmor_restrict_unprivileged_userns` back to `1`. Until
`meta-odyssey` has a commit, BitBake prints its layer revision as
`<unknown>:<unknown>`.
