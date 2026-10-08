# Build

Machine, device trees, and bbappends live in `meta-odyssey`. OpenSTLinux
is not in git. `./scripts/setup.sh` fetches it.

## Host

Tested host family: Ubuntu 24.04, with the package list shipped beside
OpenSTLinux `envsetup.sh` as `Ubuntu_24.04`. Ubuntu 22.04 uses the matching
`Ubuntu_22.04` list. The scripts check those packages with `dpkg` and do
not install them.

Ubuntu 24.04 packages:

```text
gawk wget git diffstat unzip texinfo gcc-multilib
build-essential chrpath socat cpio python3 python3-pip python3-pexpect
xz-utils debianutils iputils-ping python3-git python3-jinja2 libsdl1.2-dev
pylint xterm bsdmainutils
libssl-dev libgmp-dev libmpc-dev
lz4 zstd git-lfs libusb-1.0-0
```

Also required, and checked by name: `curl`, `gpg`, and a `git` identity
(`user.name` and `user.email`). `repo` is downloaded into
`scripts/.repo-tool/` if it is not already on `PATH`. SD image generation
needs `sgdisk` from the `gdisk` package.

BitBake 2.8.1 in this Scarthgap tag calls `unshare`. Ubuntu 24.04 sets
`kernel.apparmor_restrict_unprivileged_userns=1`, and BitBake then stops
with `User namespaces are not usable by BitBake, possibly due to AppArmor`.

The scripts leave the sysctl alone. If you want BitBake to run until the
next reboot:

```bash
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
```

Then rerun `./scripts/setup.sh`. Skip the sysctl if you do not want user
namespaces opened up.

## Pins

| Item | Value |
| --- | --- |
| Manifest | `https://github.com/STMicroelectronics/oe-manifest.git` |
| Tag | `openstlinux-6.6-yocto-scarthgap-mpu-v26.06.10` |
| Manifest commit | `71e658b9a8cff67bef0f53a3543dad19d61380f2` |
| Distro | `openstlinux-weston` |
| Machine | `odyssey-stm32mp135d` |
| Image | `st-image-core` |

Layer revisions are in `scripts/layer-revisions.txt`. `setup.sh` fails if a
checkout does not match.

## Commands

```bash
./scripts/setup.sh
./scripts/build.sh
./scripts/create-sdcard.sh
```

`setup.sh` can be rerun. If `sources/` is already a checkout of another
tag, the script stops and leaves it alone. The build directory is
`sources/build-openstlinuxweston-odyssey-stm32mp135d`, also linked as
`build/`. `downloads/` and `sstate-cache/` are created next to the
repository if missing, and both are gitignored. A new clone does not need
copies of either cache; they only shorten a rebuild on the same machine.

`setup.sh` links `sources/layers/meta-odyssey` at a path relative to the
manifest root. It also drops a machine stub into the fetched `meta-st`
tree, because `envsetup.sh` only looks there for the machine name. BitBake
loads the real machine file from `meta-odyssey` (priority 8, above the ST
layer). The stub is not committed.

`build.sh` parses, checks that `meta-odyssey` is on `BBLAYERS` and
`meta-patvaz` is not, then runs `bitbake st-image-core`. Log:
`logs/st-image-core.log`.

Deploy directory after a successful build:

`build/tmp-glibc/deploy/images/odyssey-stm32mp135d/`

`create-sdcard.sh` calls the ST `create_sdcard_from_flashlayout.sh` on
`flashlayout_st-image-core/optee/FlashLayout_sdcard_stm32mp135d-odyssey-optee.tsv`.
It does not set `DEVICE` and does not write a block device. Optional output:

```bash
./scripts/create-sdcard.sh --output /path/to/image.raw
```

A new build gets `EULA_odysseystm32mp135d=0` unless you export another
value. That is the value used for the image that was flashed. Export
`EULA_odysseystm32mp135d=1` before `setup.sh` to accept the ST license.

The 2026-10-08 build, and the UART4 rebuild after it, are recorded in
[BUILD_VALIDATION_REPORT.md](BUILD_VALIDATION_REPORT.md). The image from
the rebuild boots Linux from SD.
