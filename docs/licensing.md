# Licensing and attribution

## This repository

The MIT text is [LICENSE](../LICENSE), also copied to `meta-odyssey/COPYING.MIT`.

MIT covers the layer configuration, the two bbappends, the scripts, and
the docs. It does not cover OpenSTLinux or the board device trees. Those
files already have another SPDX line. Leave it.

## Board device trees

The SPDX line was kept as it arrived:

| File | SPDX-License-Identifier |
| --- | --- |
| `tf-a/stm32mp135d-odyssey.dts` | `(GPL-2.0+ OR BSD-3-Clause)` |
| `tf-a/stm32mp135d-odyssey-fw-config.dts` | `(GPL-2.0+ OR BSD-3-Clause)` |
| `optee/stm32mp135d-odyssey.dts` | `(GPL-2.0+ OR BSD-3-Clause)` |
| `u-boot/stm32mp135d-odyssey.dts` | `(GPL-2.0+ OR BSD-3-Clause)` |
| `linux/stm32mp135d-odyssey.dts` | `(GPL-2.0+ OR BSD-3-Clause)` |
| `u-boot/stm32mp135d-odyssey-u-boot.dtsi` | `GPL-2.0-or-later OR BSD-3-Clause` |

`GPL-2.0+` is the identifier already in the TF-A, OP-TEE, U-Boot, Linux,
and firmware-config files. It was not rewritten to `GPL-2.0-or-later`.

Headers name the trees they follow:

- STMicroelectronics `stm32mp135f-dk` device trees and the OpenSTLinux
  Scarthgap bindings those trees were retargeted onto
- Seeed Studio / xogium historical board trees, including
  `v2.8-stm32mp-odyssey-r1` (TF-A) and `v6.1-stm32mp-odyssey-r4` (Linux)

The xogium checkouts and the ST layers are not vendored here.

## OpenSTLinux

Fetched by `scripts/setup.sh`. Not committed:

- Manifest `https://github.com/STMicroelectronics/oe-manifest.git`
- Tag `openstlinux-6.6-yocto-scarthgap-mpu-v26.06.10`
- Commit `71e658b9a8cff67bef0f53a3543dad19d61380f2`
- `meta-st-stm32mp` `49046b2a0ad4dc29117025c94838b9befff86f23`
- The TF-A, OP-TEE, U-Boot, and Linux recipes from that tag

Upstream licenses stay with those projects, including the ST software
license agreement that `envsetup.sh` records. A new build writes
`EULA_odysseystm32mp135d=0` unless you export `1` before `setup.sh`.
This tree does not accept that license for you.

No product application, Web HMI, Modbus service, or Qt application is in
the layer.
