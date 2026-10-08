# Baseline preservation

Historical record, 2026-10-08, written before the public migration.
Nothing in the source workspace was committed, staged, or edited for this
record. Current status is in
[BUILD_VALIDATION_REPORT.md](BUILD_VALIDATION_REPORT.md).

A byte copy of the dirty diff and the untracked diagnostic patch is stored
outside this repository. That snapshot is not part of this Git tree.

That snapshot is preservation only. It contains the experimental LCD diff
and must not be copied into `meta-odyssey`.

## Git

| Item | Value |
| --- | --- |
| Branch | `master` |
| HEAD | `3bafc7d75eac842d0db14aae9c414271fed76fb2` |
| Subject | image: record the ODYSSEY SD card flash layout |
| Author date | 2026-10-04 14:12:35 +0330 |
| Manifest tag | `openstlinux-6.6-yocto-scarthgap-mpu-v26.06.10` |
| Manifest commit | `71e658b9a8cff67bef0f53a3543dad19d61380f2` |

`git diff --stat` against HEAD:

```text
linux/stm32mp135d-odyssey.dts     | 132 +++++++++++++++++++++
optee/stm32mp135d-odyssey.dts     |  70 ++++++++++-
tf-a/stm32mp135d-odyssey.dts      |  3 +-
optee-os-stm32mp_%.bbappend       |  5 +
4 files changed, 206 insertions(+), 4 deletions(-)
```

Untracked, not in that diff stat:

- `docs/BSP_AUDIT.md`
- `recipes-security/optee/optee-os-stm32mp/0002-odyssey-temporary-deferred-probe-log.patch`

## Working-tree SHA256

| SHA256 | Bytes | File |
| --- | ---: | --- |
| `4b03e344aca16f05edc8a9b411fe9a7e7a3fef8b37a7a7f60cbc537ccbc880b1` | 12969 | Linux DTS, includes the LCD experiment |
| `7cce20046036aa689bc6e417957ae351854ff0374a6df9ca0c66fcf843e90c54` | 11081 | OP-TEE DTS, hardware fixes plus LTDC ETZPC cell |
| `17f4a1550e5570f6274ac2bbc0a0313c3469b71a6dc7398aaa75889e7fb8853c` | 7521 | TF-A DTS, IWDG2 disabled |
| `b0ab7902777abf1e8b8fd0a8b5a40f43be688939d651cd2e2ed7fea41d0547d1` | 983 | OP-TEE bbappend, includes the diagnostic `SRC_URI` |
| `d5c5c20014f8631d2e0fa145f173779c7f6a40d5bf36f72b448ddced20193914` | 1335 | temporary deferred-probe patch |
| `2b00533d85c974b1537e3703becfe0faff97b13ac94cad53f0e466c00929910b` | 18472 | `docs/BSP_AUDIT.md` |

HEAD git blob ids for the four modified tracked files:

| Blob | File |
| --- | --- |
| `07b5d8734f11363834563d142cfb55fcccf00e96` | Linux DTS |
| `4d766574c71b5893f535892a5bc60c5704287ff9` | OP-TEE DTS |
| `c0add92101be126dac4c7faf592159c7e3029b4c` | TF-A DTS |
| `3c0c03c7b4a0134767bca5fd65202a7a8ab625d4` | OP-TEE bbappend |

## What the dirty diff contains

Tested board support, uncommitted, required later:

- OP-TEE PMIC `interrupts-extended`, wakeup, and notification ids
- OP-TEE `&cpu0 { cpu-supply = <&vddcpu>; }`
- OP-TEE SCMI exports for LDO4, LDO5, and PWR_SW2
- OP-TEE secure GPIO locks PA13, PB7, PE5, PE15, PF8
- OP-TEE `&pwr_irq` on PF8
- OP-TEE ETZPC for DDRCTRLPHY, SDMMC1, SDMMC2, ETH1, ETH2, OTG, USBPHYCTRL
- TF-A `&iwdg2 { status = "disabled"; }` (approved development configuration)

Experimental display, uncommitted, excluded:

- Linux `sys_3v3`, `panel-odyssey`, `backlight-odyssey`, LTDC pinctrl, `&ltdc` (132 lines)
- OP-TEE `DECPROT(STM32MP1_ETZPC_LTDC_ID, DECPROT_NS_RW, DECPROT_UNLOCK)`

Temporary diagnostic, excluded:

- bbappend `SRC_URI` line and `0002-odyssey-temporary-deferred-probe-log.patch`

No commit of these changes was made in the original repository.
