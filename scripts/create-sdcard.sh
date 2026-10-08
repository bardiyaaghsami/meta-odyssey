#!/bin/bash
# Build an SD raw image from the ST FlashLayout. Does not write to a block device.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"
odyssey_load_pins

ROOT=$(odyssey_root)
OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)
            OUTPUT="${2:-}"
            shift 2
            ;;
        *)
            odyssey_die "unknown argument: $1"
            ;;
    esac
done

command -v sgdisk >/dev/null 2>&1 || odyssey_die "sgdisk is missing. Install the gdisk package yourself. This script does not run apt."

BUILD=$(readlink -f "${ROOT}/build" 2>/dev/null || true)
[[ -n "$BUILD" && -d "$BUILD" ]] || odyssey_die "build/ is missing. Run ./scripts/setup.sh and ./scripts/build.sh first."
DEPLOY="${BUILD}/tmp-glibc/deploy/images/${OSTL_MACHINE}"
# ST names this file from the board device tree (stm32mp135d-odyssey),
# not from MACHINE (odyssey-stm32mp135d).
tsv_dir="${DEPLOY}/flashlayout_${OSTL_IMAGE}/optee"
shopt -s nullglob
tsv_candidates=("${tsv_dir}/"FlashLayout_sdcard_*-optee.tsv)
shopt -u nullglob
if [[ ${#tsv_candidates[@]} -ne 1 ]]; then
    odyssey_die "expected one SD FlashLayout in ${tsv_dir}, found ${#tsv_candidates[@]}."
fi
TSV="${tsv_candidates[0]}"
TOOL="${DEPLOY}/scripts/create_sdcard_from_flashlayout.sh"
[[ -f "$TSV" ]] || odyssey_die "FlashLayout not found: ${TSV}"
[[ -f "$TOOL" ]] || odyssey_die "ST sdcard tool not found: ${TOOL}"

# Paths in the TSV are relative. The official file lives two directories
# below the images. A copy one directory below the images still resolves
# those paths through the tool's parent-directory search, and the copy's
# directory name must not contain "flashlayout" or the tool renames the raw.
LAYOUT_DIR="${DEPLOY}/sdcard-layout"
LAYOUT_TSV="${LAYOUT_DIR}/stm32mp135d-odyssey-sdcard.tsv"
mkdir -p "$LAYOUT_DIR"
cp -f "$TSV" "$LAYOUT_TSV"

missing=0
while IFS=$'\t' read -r _opt _id _name _type _ip _offset binary _boot; do
    [[ "$binary" == "Binary" || "$binary" == "none" || -z "$binary" ]] && continue
    found=""
    for base in "$LAYOUT_DIR" "$LAYOUT_DIR/.." "$LAYOUT_DIR/../.." "$DEPLOY"; do
        if [[ -f "${base}/${binary}" ]]; then
            found="${base}/${binary}"
            break
        fi
    done
    if [[ -z "$found" ]]; then
        echo "MISSING ${binary}" >&2
        missing=1
    fi
done < "$LAYOUT_TSV"
[[ "$missing" -eq 0 ]] || odyssey_die "required FlashLayout binaries are missing."

RAW_NAME="stm32mp135d-odyssey-sdcard.raw"
# The tool writes the raw next to the image binaries, which is $DEPLOY.
GENERATED="${DEPLOY}/${RAW_NAME}"
rm -f "$GENERATED"
# Do not export DEVICE. The tool must not be pointed at a block device.
env -u DEVICE -u DEBUG "$TOOL" "$LAYOUT_TSV"
[[ -f "$GENERATED" ]] || odyssey_die "ST tool finished but ${GENERATED} is missing."

if [[ -n "$OUTPUT" ]]; then
    mkdir -p "$(dirname "$OUTPUT")"
    mv -f "$GENERATED" "$OUTPUT"
    FINAL="$OUTPUT"
else
    FINAL="$GENERATED"
fi
echo "SD image: ${FINAL}"
stat -c 'size_bytes=%s' "$FINAL"
sha256sum "$FINAL"
