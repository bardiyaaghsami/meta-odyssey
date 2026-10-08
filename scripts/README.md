# scripts

| Script | What it does |
| --- | --- |
| `setup.sh` | `repo sync` the pinned OpenSTLinux tag and point the build at `meta-odyssey` |
| `build.sh` | Check the layer list, parse, then `bitbake st-image-core` |
| `create-sdcard.sh` | Build an SD raw image from the FlashLayout. Does not write a device |
| `flash-sdcard.sh` | `dd` that image after the device checks in `docs/flashing.md` |

`setup.sh` and `build.sh` exit if
`kernel.apparmor_restrict_unprivileged_userns=1`. They do not change the
sysctl. See `docs/build.md`.

Nothing else calls `flash-sdcard.sh`.
