# Shared helpers for the public ODYSSEY BSP scripts.

odyssey_root() {
    local here
    here=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
    printf '%s\n' "$here"
}

odyssey_load_pins() {
    local root
    root=$(odyssey_root)
    # shellcheck disable=SC1091
    source "${root}/scripts/pins.env"
}

odyssey_die() {
    echo "ERROR: $*" >&2
    exit 1
}

odyssey_sources_dir() {
    printf '%s\n' "$(odyssey_root)/sources"
}

odyssey_build_link() {
    printf '%s\n' "$(odyssey_root)/build"
}

odyssey_host_package_list() {
    local version_id="${1:-}"
    case "$version_id" in
        22.04)
            printf '%s\n' \
                gawk wget git diffstat unzip texinfo gcc-multilib \
                build-essential chrpath socat cpio python3 python3-pip python3-pexpect \
                xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
                pylint xterm bsdmainutils \
                libssl-dev libgmp-dev libmpc-dev \
                lz4 zstd git-lfs libusb-1.0-0
            ;;
        24.04)
            printf '%s\n' \
                gawk wget git diffstat unzip texinfo gcc-multilib \
                build-essential chrpath socat cpio python3 python3-pip python3-pexpect \
                xz-utils debianutils iputils-ping python3-git python3-jinja2 libsdl1.2-dev \
                pylint xterm bsdmainutils \
                libssl-dev libgmp-dev libmpc-dev \
                lz4 zstd git-lfs libusb-1.0-0
            ;;
        *)
            return 1
            ;;
    esac
}

odyssey_missing_host_packages() {
    local version_id="$1"
    local pkg
    local missing=()
    odyssey_host_package_list "$version_id" >/dev/null || return 2
    for pkg in $(odyssey_host_package_list "$version_id"); do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        printf '%s\n' "${missing[@]}"
        return 1
    fi
    return 0
}

# Prints the sysctl value. Returns 0 when the restriction is active (value 1).
odyssey_apparmor_blocks_bitbake() {
    local value
    if ! command -v sysctl >/dev/null 2>&1; then
        echo "unknown"
        return 0
    fi
    value=$(sysctl -n kernel.apparmor_restrict_unprivileged_userns 2>/dev/null || echo unknown)
    printf '%s\n' "$value"
    [[ "$value" == "1" ]]
}

odyssey_print_apparmor_help() {
    cat <<'EOF'
BitBake cannot start while kernel.apparmor_restrict_unprivileged_userns=1.
Ubuntu 24.04 enables that restriction. It is a host security setting.

This project does not change it. If you accept the change for this boot, run:

    sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0

That lasts until the next reboot. Read the Ubuntu 24.04 notes on
unprivileged user namespaces before making it permanent. Then rerun this
script. Do not run that command unless you intend to relax the host policy.
EOF
}

odyssey_require_apparmor() {
    local value
    value=$(odyssey_apparmor_blocks_bitbake || true)
    if [[ "$value" == "1" ]]; then
        odyssey_print_apparmor_help
        return 1
    fi
    return 0
}
