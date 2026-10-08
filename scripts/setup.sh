#!/bin/bash
# Fetch the pinned OpenSTLinux tree and configure an ODYSSEY build directory.
# Safe to rerun. Does not install packages and does not change host sysctl.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"
odyssey_load_pins

ROOT=$(odyssey_root)
SOURCES="${ROOT}/sources"
PINS="${ROOT}/scripts/layer-revisions.txt"
ENVSETUP="${SOURCES}/layers/meta-st/scripts/envsetup.sh"
LAYER_LINK="${SOURCES}/layers/meta-odyssey"
REPO_TOOL_DIR="${ROOT}/scripts/.repo-tool"
REPO_URL="https://storage.googleapis.com/git-repo-downloads/repo"
REPO_ASC_URL="https://storage.googleapis.com/git-repo-downloads/repo.asc"
REPO_KEY="8BB9AD793E8E6153AF0F9A4416530D5E920F5C65"

die() { echo "ERROR: $*" >&2; exit 1; }

if [[ ! -r /etc/os-release ]]; then
    die "/etc/os-release is missing."
fi
# shellcheck disable=SC1091
source /etc/os-release
echo "Host: ${NAME:-unknown} ${VERSION_ID:-unknown}"

if ! odyssey_host_package_list "${VERSION_ID:-}" >/dev/null; then
    die "Ubuntu ${VERSION_ID:-unknown} is outside the 22.04/24.04 package lists for this OpenSTLinux tag. See docs/build.md."
fi
missing=$(odyssey_missing_host_packages "${VERSION_ID}" || true)
if [[ -n "$missing" ]]; then
    echo "ERROR: host packages required by this OpenSTLinux release are missing:" >&2
    echo "$missing" >&2
    echo "Install them yourself. This script does not run apt." >&2
    exit 1
fi
for cmd in git python3 curl gpg; do
    command -v "$cmd" >/dev/null 2>&1 || die "required command not found: ${cmd}"
done
if [[ -z "$(git config --global user.name || true)" || -z "$(git config --global user.email || true)" ]]; then
    die "repo requires git user.name and user.email. Set them yourself. This script does not change git config."
fi

if odyssey_apparmor_blocks_bitbake >/dev/null; then
    odyssey_print_apparmor_help
    echo "ERROR: setup stopped before fetching sources. BitBake cannot run until that host setting is changed with your approval." >&2
    exit 1
fi

repo_bin() {
    if command -v repo >/dev/null 2>&1; then
        command -v repo
        return 0
    fi
    local launcher="${REPO_TOOL_DIR}/repo"
    if [[ -x "$launcher" ]]; then
        printf '%s\n' "$launcher"
        return 0
    fi
    return 1
}

if ! repo_bin >/dev/null 2>&1; then
    echo "Downloading the repo launcher to ${REPO_TOOL_DIR}/repo"
    mkdir -p "$REPO_TOOL_DIR"
    tmp_repo=$(mktemp)
    tmp_asc=$(mktemp)
    trap 'rm -f "$tmp_repo" "$tmp_asc"' EXIT
    curl -fsSL -o "$tmp_repo" "$REPO_URL"
    curl -fsSL -o "$tmp_asc" "$REPO_ASC_URL"
    gpg --recv-keys "$REPO_KEY"
    gpg --verify "$tmp_asc" "$tmp_repo"
    install -m 755 "$tmp_repo" "${REPO_TOOL_DIR}/repo"
    rm -f "$tmp_repo" "$tmp_asc"
    trap - EXIT
fi
REPO_BIN=$(repo_bin)

mkdir -p "$SOURCES"
if [[ -d "${SOURCES}/.repo" ]]; then
    current_tag=$(git -C "${SOURCES}/.repo/manifests" describe --tags --exact-match HEAD 2>/dev/null || true)
    current_commit=$(git -C "${SOURCES}/.repo/manifests" rev-parse HEAD)
    echo "Existing manifest: ${current_tag:-<no tag>} ${current_commit}"
    if [[ "$current_tag" != "$OSTL_TAG" || "$current_commit" != "$OSTL_MANIFEST_COMMIT" ]]; then
        die "sources/ is a repo checkout at a different revision. Expected ${OSTL_TAG} ${OSTL_MANIFEST_COMMIT}. Refusing to re-init."
    fi
    echo "Manifest matches. Running repo sync."
else
    if [[ -n "$(find "$SOURCES" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
        die "${SOURCES} is not empty and is not a repo checkout. Refusing to write into it."
    fi
    echo "Initializing ${OSTL_MANIFEST_URL} at refs/tags/${OSTL_TAG}"
    (
        cd "$SOURCES"
        "$REPO_BIN" init -u "$OSTL_MANIFEST_URL" -b "refs/tags/${OSTL_TAG}"
    )
fi
(
    cd "$SOURCES"
    "$REPO_BIN" sync
)

manifest_commit=$(git -C "${SOURCES}/.repo/manifests" rev-parse HEAD)
manifest_tag=$(git -C "${SOURCES}/.repo/manifests" describe --tags --exact-match HEAD 2>/dev/null || true)
if [[ "$manifest_tag" != "$OSTL_TAG" || "$manifest_commit" != "$OSTL_MANIFEST_COMMIT" ]]; then
    die "manifest is ${manifest_tag:-?} ${manifest_commit}, expected ${OSTL_TAG} ${OSTL_MANIFEST_COMMIT}"
fi
echo "Manifest pin OK: ${manifest_tag} ${manifest_commit}"

while read -r path rev; do
    [[ -z "$path" || "$path" == \#* ]] && continue
    got=$(git -C "${SOURCES}/${path}" rev-parse HEAD)
    if [[ "$got" != "$rev" ]]; then
        die "${path} is ${got}, expected ${rev}"
    fi
    echo "PIN OK  ${path} ${got}"
done < "$PINS"

if [[ ! -d "${ROOT}/meta-odyssey/conf" ]]; then
    die "meta-odyssey is missing next to this script."
fi
ln -sfn ../../meta-odyssey "$LAYER_LINK"
if [[ "$(readlink -f "$LAYER_LINK")" != "$(readlink -f "${ROOT}/meta-odyssey")" ]]; then
    die "could not point sources/layers/meta-odyssey at the public layer."
fi

discover="${SOURCES}/layers/meta-st/meta-st-stm32mp/conf/machine/${OSTL_MACHINE}.conf"
eula_link="${SOURCES}/layers/meta-st/meta-st-stm32mp/conf/eula/${OSTL_MACHINE}"
cat > "$discover" <<EOF
# Generated by scripts/setup.sh. Do not edit.
# envsetup.sh only looks under layers/meta-st for the machine file.
# BitBake loads the machine from layers/meta-odyssey (higher layer priority).
#@TYPE: Machine
#@NAME: ${OSTL_MACHINE}
#@DESCRIPTION: Discovery stub so OpenSTLinux envsetup.sh can see this machine
#@NEEDED_BSPLAYERS: layers/meta-openembedded/meta-oe layers/meta-openembedded/meta-python layers/meta-odyssey
EOF
if [[ ! -e "$eula_link" ]]; then
    ln -s stm32mp13-disco "$eula_link"
fi
stm_git=$(git -C "${SOURCES}/layers/meta-st/meta-st-stm32mp" rev-parse --absolute-git-dir 2>/dev/null || true)
if [[ -n "$stm_git" && -f "${stm_git}/info/exclude" ]]; then
    grep -qx "conf/machine/${OSTL_MACHINE}.conf" "${stm_git}/info/exclude" || echo "conf/machine/${OSTL_MACHINE}.conf" >> "${stm_git}/info/exclude"
    grep -qx "conf/eula/${OSTL_MACHINE}" "${stm_git}/info/exclude" || echo "conf/eula/${OSTL_MACHINE}" >> "${stm_git}/info/exclude"
fi

mkdir -p "${ROOT}/downloads" "${ROOT}/sstate-cache"
unset BUILD_DIR
export DISTRO="${OSTL_DISTRO}"
export MACHINE="${OSTL_MACHINE}"
eula_var="EULA_${OSTL_MACHINE//[-.]/}"
if [[ -z "${!eula_var:-}" ]]; then
    export "${eula_var}=${OSTL_EULA_VALUE}"
fi
export FORCE_DL_CACHEPREFIX="${ROOT}/downloads"
export FORCE_SSTATE_CACHEPREFIX="${ROOT}/sstate-cache"

echo "Sourcing OpenSTLinux envsetup.sh"
cd "$SOURCES"
# envsetup.sh expands variables it does not define, including META_LAYER_ROOT.
# With nounset that aborts this shell before the script can supply a default.
# errexit is also off so a non-zero return from the sourced script can be
# reported here instead of ending the shell on the source line.
set +u
set +e
# shellcheck disable=SC1090
source "$ENVSETUP" --no-ui --quiet
envsetup_status=$?
set -euo pipefail
if [[ "$envsetup_status" -ne 0 ]]; then
    die "OpenSTLinux envsetup.sh failed (exit ${envsetup_status})."
fi
export DISTRO="${OSTL_DISTRO}"
export MACHINE="${OSTL_MACHINE}"

bblayers="${BUILDDIR}/conf/bblayers.conf"
[[ -f "$bblayers" ]] || die "envsetup did not create ${bblayers}"
if grep -q 'meta-patvaz' "$bblayers"; then
    grep -v 'meta-patvaz' "$bblayers" > "${bblayers}.odyssey"
    mv "${bblayers}.odyssey" "$bblayers"
    echo "Removed meta-patvaz from ${bblayers}"
fi
if ! grep -q 'layers/meta-odyssey' "$bblayers"; then
    printf '\n# Public board layer. Added by scripts/setup.sh.\nBBLAYERS =+ "${OEROOT}/layers/meta-odyssey"\n' >> "$bblayers"
fi

build_link="${ROOT}/build"
if [[ "$(readlink -f "${build_link}" 2>/dev/null || true)" != "$(readlink -f "${BUILDDIR}")" ]]; then
    if [[ -e "$build_link" && ! -L "$build_link" ]]; then
        die "${build_link} exists and is not a symlink to ${BUILDDIR}. Refusing to replace it."
    fi
    ln -sfn "$BUILDDIR" "$build_link"
fi

echo
echo "Sources:  ${SOURCES}"
echo "Build:    ${BUILDDIR}"
echo "Layer:    ${ROOT}/meta-odyssey"
echo "Deploy:   ${BUILDDIR}/tmp-glibc/deploy/images/${OSTL_MACHINE}"
echo "DISTRO=${DISTRO}  MACHINE=${MACHINE}  IMAGE=${OSTL_IMAGE}"
echo "Next: ./scripts/build.sh"
