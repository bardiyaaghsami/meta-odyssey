# Flashing

`scripts/flash-sdcard.sh` writes a raw image with `dd`. `setup.sh`,
`build.sh`, and `create-sdcard.sh` do not call it.

The card that booted was `stm32mp135d-odyssey-sdcard.raw` from
`build/tmp-glibc/deploy/images/odyssey-stm32mp135d/`:

- SHA256 `005c9c0e5542591504c9a667cbde519a9e58fdda2edcd5270537fdcee992f47f`
- 5153751040 bytes

`./scripts/build.sh` then `./scripts/create-sdcard.sh` writes that file.
The default path is gitignored.

```bash
./scripts/flash-sdcard.sh /path/to/image.raw /dev/sdX
```

The script:

1. Requires both arguments. It has no default device.
2. Requires the image to be a non-empty regular file and the destination to be a block device.
3. Prints `lsblk` for that device, including size, model, and the removable flag.
4. Rejects partitions. Pass the whole disk.
5. Rejects disks that are not reported as removable.
6. Rejects any device that still has a mount point.
7. Rejects the disk that holds `/` and the root filesystem device itself.
8. Requires an interactive terminal and asks you to type the destination path.
9. Runs `dd if=<image> of=<device> bs=8M conv=fdatasync status=progress` only after that confirmation.

If `sgdisk -v /dev/sdX` reports a problem after the card is larger than the
image, run `sgdisk -e /dev/sdX`. That moves the backup GPT header to the
end of the card. It does not rewrite partition contents. Run it only after
you have confirmed the device again.

Console is UART4, 115200 8N1.

These scripts do not run `fuse prog` or `fuse override`.
