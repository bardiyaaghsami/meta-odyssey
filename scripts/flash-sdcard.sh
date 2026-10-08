#!/bin/bash
# Write an SD raw image to an explicit block device after safety checks.
# Never called by setup.sh or build.sh. Does not program OTP or fuses.
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <image.raw> <block-device>" >&2
    echo "Example: $0 /path/to/image.raw /dev/sdX" >&2
    exit 1
fi

IMAGE=$1
DEST=$2

[[ -f "$IMAGE" ]] || { echo "ERROR: image is not a regular file: ${IMAGE}" >&2; exit 1; }
[[ -s "$IMAGE" ]] || { echo "ERROR: image is empty: ${IMAGE}" >&2; exit 1; }
[[ -b "$DEST" ]] || { echo "ERROR: destination is not a block device: ${DEST}" >&2; exit 1; }

command -v lsblk >/dev/null 2>&1 || { echo "ERROR: lsblk is required." >&2; exit 1; }
command -v findmnt >/dev/null 2>&1 || { echo "ERROR: findmnt is required." >&2; exit 1; }

dest_real=$(readlink -f "$DEST")
dest_type=$(lsblk -dno TYPE "$dest_real" 2>/dev/null | tr -d '[:space:]' || true)
dest_pk=$(lsblk -dno PKNAME "$dest_real" 2>/dev/null | tr -d '[:space:]' || true)
dest_rm=$(lsblk -dno RM "$dest_real" 2>/dev/null | tr -d '[:space:]' || true)

echo "Image:       ${IMAGE}"
stat -c 'Image size:  %s bytes' "$IMAGE"
echo "Destination: ${dest_real}"
echo
lsblk -o NAME,TYPE,SIZE,RM,RO,MODEL,MOUNTPOINTS "$dest_real"
echo

if [[ "$dest_type" != "disk" ]]; then
    echo "ERROR: ${dest_real} is type '${dest_type:-unknown}', not a whole disk." >&2
    exit 1
fi
if [[ -n "$dest_pk" ]]; then
    echo "ERROR: ${dest_real} is a partition of ${dest_pk}. Pass the whole disk." >&2
    exit 1
fi
if [[ "$dest_rm" != "1" ]]; then
    echo "ERROR: ${dest_real} is not reported as removable (RM=${dest_rm:-?}). Refusing to write." >&2
    exit 1
fi

mounts=$(lsblk -ln -o MOUNTPOINTS "$dest_real" | sed '/^$/d' || true)
if [[ -n "$mounts" ]]; then
    echo "ERROR: ${dest_real} has mounted filesystems:" >&2
    printf '%s\n' "$mounts" >&2
    exit 1
fi

root_src=$(findmnt -n -o SOURCE / || true)
root_real=$(readlink -f "$root_src" 2>/dev/null || true)
root_disk=""
if [[ -n "$root_real" && -b "$root_real" ]]; then
    root_pk=$(lsblk -no PKNAME "$root_real" 2>/dev/null | head -1 || true)
    if [[ -n "$root_pk" ]]; then
        root_disk="/dev/${root_pk}"
    else
        root_disk=$root_real
    fi
fi
if [[ -n "$root_disk" && "$dest_real" == "$(readlink -f "$root_disk")" ]]; then
    echo "ERROR: ${dest_real} is the disk that holds the root filesystem (${root_src})." >&2
    exit 1
fi
if [[ -n "$root_real" && "$dest_real" == "$root_real" ]]; then
    echo "ERROR: ${dest_real} is the root filesystem device." >&2
    exit 1
fi

if [[ ! -t 0 ]]; then
    echo "ERROR: flashing requires an interactive terminal so the destination can be confirmed." >&2
    exit 1
fi

echo "This will overwrite ${dest_real}."
echo "Type the destination path exactly to continue:"
read -r confirm
if [[ "$confirm" != "$dest_real" ]]; then
    echo "Confirmation did not match. Nothing was written."
    exit 1
fi

if [[ ! -w "$dest_real" ]]; then
    echo "ERROR: ${dest_real} is not writable. Re-run this script with sufficient permission. Nothing was written." >&2
    exit 1
fi

dd if="$IMAGE" of="$dest_real" bs=8M conv=fdatasync status=progress
sync
echo "Write finished."
echo "If sgdisk -v ${dest_real} reports a problem after the card is larger than the image, run: sgdisk -e ${dest_real}"
echo "sgdisk -e moves the backup GPT to the end of the card. It does not change partition contents."
