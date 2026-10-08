# Pinned OpenSTLinux sources

`scripts/setup.sh` fetches this manifest and refuses a checkout on another
tag. The trees are not committed.

| Item | Value |
| --- | --- |
| Manifest URL | `https://github.com/STMicroelectronics/oe-manifest.git` |
| Manifest tag | `openstlinux-6.6-yocto-scarthgap-mpu-v26.06.10` |
| Manifest commit | `71e658b9a8cff67bef0f53a3543dad19d61380f2` |
| OpenSTLinux ecosystem | v6.2.1 |
| Yocto | 5.0.17 Scarthgap |
| BitBake | 2.8.1 (`layers/openembedded-core/bitbake`) |

`git -C sources/.repo/manifests describe --tags --exact-match HEAD` returned
the tag above.

## Layer revisions

`git rev-parse HEAD` in each checkout:

| Path | Revision |
| --- | --- |
| `layers/openembedded-core` | `52380df998b3a8fe6a091f8547434a3231320a8e` |
| `layers/openembedded-core/bitbake` | `b2404004135b669f8258c85c7b5aed4570a805c7` |
| `layers/meta-openembedded` | `5124ac4a658899158f4a7a2ddf1d2ca931ec7d0e` |
| `layers/meta-st/meta-st-openstlinux` | `b0316f706bcf34e8449d43aba3c630030f2cc366` |
| `layers/meta-st/meta-st-stm32mp` | `49046b2a0ad4dc29117025c94838b9befff86f23` |
| `layers/meta-st/meta-st-stm32mp-addons` | `ad667afe266eb1ca706bf92ea6d99cc9ec74d662` |
| `layers/meta-st/scripts` | `8826802b453ef2ead61b07c7bc5ab525a405df04` |

## Component versions

These are the recipe versions that `st-image-core` built from this tree.

| Component | Version |
| --- | --- |
| `linux-stm32mp` | 6.6.129-stm32mp-r3.1 |
| `tf-a-stm32mp` | v2.10.24-stm32mp-r3.1 |
| `u-boot-stm32mp` | v2023.10-stm32mp-r3.1 |
| `optee-os-stm32mp` | 4.0.0-stm32mp-r3.1 |

## Fetch

`scripts/setup.sh` runs `repo init` on that tag and `repo sync`, then
checks every revision in `scripts/layer-revisions.txt`.
