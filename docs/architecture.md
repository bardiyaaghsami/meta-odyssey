# Boot chain

```text
STM32MP135D BootROM
        |
        v
TF-A
        |
        v
OP-TEE
        |
        v
U-Boot
        |
        v
Linux 6.6
        |
        v
st-image-core
```

| Stage | Role on this board |
| --- | --- |
| BootROM | On-chip ROM. Loads TF-A from the selected boot device. v0.1.0 uses SD. |
| TF-A | DDR init include, STPMIC1, clocks, UART4, SDMMC, and the eMMC pin description. |
| OP-TEE | PMIC interrupt, secure GPIO locks, SCMI regulators, ETZPC for the non-secure boot peripherals. |
| U-Boot | Loads Linux from the SD layout. Console is UART4. Environment partition is `u-boot-env` on SDMMC1. |
| Linux | UART, SD, eMMC, both Ethernet ports, USB. |
| Userspace | OpenSTLinux `st-image-core`. No application layer. |

Machine overrides are `stm32mp1common` and `stm32mp13common`. Compatible
string: `st,stm32mp135d-odyssey`.

DDR is 512 MiB at `0xc0000000`, from ST's
`stm32mp13-ddr3-1x4Gb-1066-binF.dtsi`. This layer does not replace that
include and does not program OTP. The TF-A `board_id` node is non-secure
OTP read data only.

## IWDG2

TF-A has `&iwdg2 { status = "disabled"; }`. v0.1.0 keeps that so a debug
session is not reset by the TF-A watchdog. It is not a production policy.
See [known-issues.md](known-issues.md).

## Left out

No LCD panel, backlight, touch, or OP-TEE LTDC ETZPC cell. Linux UART4
does not request PA13 or PE5. The SD boot record is in
[BUILD_VALIDATION_REPORT.md](BUILD_VALIDATION_REPORT.md).
