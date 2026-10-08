#!/bin/bash
# Parse metadata, then build st-image-core for the ODYSSEY machine.
# Does not flash and does not change host sysctl.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"
odyssey_load_pins

ROOT=$(odyssey_root)
SOURCES="${ROOT}/sources"
ENVSETUP="${SOURCES}/layers/meta-st/scripts/envsetup.sh"
LOG_DIR="${ROOT}/logs"
LOG_FILE="${LOG_DIR}/st-image-core.log"

if ! odyssey_require_apparmor; then
    exit 1
fi
[[ -f "$ENVSETUP" ]] || odyssey_die "OpenSTLinux sources are missing. Run ./scripts/setup.sh"
[[ -d "${ROOT}/meta-odyssey" ]] || odyssey_die "meta-odyssey is missing."

mkdir -p "$LOG_DIR"
unset BUILD_DIR
export DISTRO="${OSTL_DISTRO}"
export MACHINE="${OSTL_MACHINE}"
export FORCE_DL_CACHEPREFIX="${ROOT}/downloads"
export FORCE_SSTATE_CACHEPREFIX="${ROOT}/sstate-cache"

cd "$SOURCES"
# Same nounset/errexit window as setup.sh. envsetup.sh expands variables
# it does not define, and a non-zero return must be visible here.
set +u
set +e
# shellcheck disable=SC1090
source "$ENVSETUP" --no-ui --quiet
envsetup_status=$?
set -euo pipefail
if [[ "$envsetup_status" -ne 0 ]]; then
    odyssey_die "OpenSTLinux envsetup.sh failed (exit ${envsetup_status})."
fi
export DISTRO="${OSTL_DISTRO}"
export MACHINE="${OSTL_MACHINE}"
cd "$BUILDDIR"

echo "BUILDDIR=${BUILDDIR}" | tee "$LOG_FILE"
echo "DISTRO=${DISTRO} MACHINE=${MACHINE} IMAGE=${OSTL_IMAGE}" | tee -a "$LOG_FILE"

layers=$(bitbake-layers show-layers)
printf '%s\n' "$layers" | tee -a "$LOG_FILE"
printf '%s\n' "$layers" | grep -q 'meta-odyssey' || odyssey_die "meta-odyssey is not in the BitBake layer list."
if printf '%s\n' "$layers" | grep -q 'meta-patvaz'; then
    odyssey_die "meta-patvaz is present. The public build must not use it."
fi

machine_value=$(bitbake-getvar --value MACHINE)
distro_value=$(bitbake-getvar --value DISTRO)
echo "effective MACHINE=${machine_value}" | tee -a "$LOG_FILE"
echo "effective DISTRO=${distro_value}" | tee -a "$LOG_FILE"
[[ "$machine_value" == "$OSTL_MACHINE" ]] || odyssey_die "MACHINE is ${machine_value}, expected ${OSTL_MACHINE}"
[[ "$distro_value" == "$OSTL_DISTRO" ]] || odyssey_die "DISTRO is ${distro_value}, expected ${OSTL_DISTRO}"

echo "Parsing metadata (bitbake -p)" | tee -a "$LOG_FILE"
bitbake -p 2>&1 | tee -a "$LOG_FILE"

appends=$(bitbake-layers show-appends)
printf '%s\n' "$appends" | tee -a "$LOG_FILE"
printf '%s\n' "$appends" | grep -q 'external-dt_6.0.bb:' || odyssey_die "external-dt append was not applied."
printf '%s\n' "$appends" | grep -q 'meta-odyssey' || odyssey_die "meta-odyssey append path was not applied."
printf '%s\n' "$appends" | grep -q 'optee-os-stm32mp' || odyssey_die "OP-TEE append was not applied."

dt_files=$(bitbake-getvar --value STM32MP_DT_FILES_SDCARD)
echo "STM32MP_DT_FILES_SDCARD=${dt_files}" | tee -a "$LOG_FILE"
printf '%s\n' "$dt_files" | grep -q 'stm32mp135d-odyssey' || odyssey_die "ODYSSEY device tree is not selected."

echo "Building ${OSTL_IMAGE}" | tee -a "$LOG_FILE"
start=$(date +%s)
set +e
bitbake "${OSTL_IMAGE}" 2>&1 | tee -a "$LOG_FILE"
status=${PIPESTATUS[0]}
set -e
end=$(date +%s)
echo "BITBAKE_EXIT:${status}" | tee -a "$LOG_FILE"
echo "BUILD_SECONDS:$((end - start))" | tee -a "$LOG_FILE"
deploy="${BUILDDIR}/tmp-glibc/deploy/images/${OSTL_MACHINE}"
echo "DEPLOY:${deploy}" | tee -a "$LOG_FILE"
if [[ "$status" -ne 0 ]]; then
    echo "ERROR: bitbake ${OSTL_IMAGE} failed with exit ${status}. Log: ${LOG_FILE}" >&2
    exit "$status"
fi
echo "Build finished. Artifacts: ${deploy}"
