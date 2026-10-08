# Supported hardware

Seeed Studio ODYSSEY STM32MP135D. Results are from the SD image built here,
raw SHA256
`005c9c0e5542591504c9a667cbde519a9e58fdda2edcd5270537fdcee992f47f`.
The same record is in [BUILD_VALIDATION_REPORT.md](BUILD_VALIDATION_REPORT.md).

## Tested on the flashed image

- Linux boots from SD
- UART4, `/dev/ttySTM0`, 115200 8N1
- Linux no longer reports the PA13 pinctrl error
- SD root filesystem is mounted
- `end0` and `end1` are UP and LOWER_UP
- eMMC enumerates as a 3.5 GiB device
- USB host controllers enumerate
- `systemctl --failed` is empty

## Tested on the previous image

Checked before the Linux UART4 pinctrl rebuild. Not run again on the
image above.

- OP-TEE
- SCMI regulators
- CPUFreq
- thermal

## Not tested on the flashed image

- Ethernet traffic. The links are up.
- USB mass storage. The host controllers enumerate.
- Suspend and resume. Linux has no UART4 pinctrl state to restore.
- Boot from eMMC. The device enumerates. `BOOTDEVICE_LABELS` is `sdcard` only.

## Not in v0.1.0

- FPC070 panel, 800x480 timing, LTDC, backlight, touch
- Qt, a Weston product image, Web HMI, Modbus
