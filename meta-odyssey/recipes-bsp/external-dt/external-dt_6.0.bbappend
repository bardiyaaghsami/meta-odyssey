FILESEXTRAPATHS:prepend := "${THISDIR}/stm32mp135d-odyssey:"

SRC_URI:append:odyssey-stm32mp135d = " \
    file://tf-a/stm32mp135d-odyssey.dts \
    file://tf-a/stm32mp135d-odyssey-fw-config.dts \
    file://u-boot/stm32mp135d-odyssey.dts \
    file://u-boot/stm32mp135d-odyssey-u-boot.dtsi \
    file://linux/stm32mp135d-odyssey.dts \
    file://optee/stm32mp135d-odyssey.dts \
"

# Install board files into the external-dt source after envsetup's provider
# has moved that tree to STAGING_EXTDT_DIR. ST layers are not edited.
do_install_odyssey_dt() {
    if [ "${MACHINE}" != "odyssey-stm32mp135d" ]; then
        return 0
    fi
    install -d ${S}/stm32mp1/tf-a ${S}/stm32mp1/u-boot ${S}/stm32mp1/linux ${S}/stm32mp1/optee
    install -m 0644 ${WORKDIR}/tf-a/stm32mp135d-odyssey.dts ${S}/stm32mp1/tf-a/
    install -m 0644 ${WORKDIR}/tf-a/stm32mp135d-odyssey-fw-config.dts ${S}/stm32mp1/tf-a/
    install -m 0644 ${WORKDIR}/u-boot/stm32mp135d-odyssey.dts ${S}/stm32mp1/u-boot/
    install -m 0644 ${WORKDIR}/u-boot/stm32mp135d-odyssey-u-boot.dtsi ${S}/stm32mp1/u-boot/
    install -m 0644 ${WORKDIR}/linux/stm32mp135d-odyssey.dts ${S}/stm32mp1/linux/
    install -m 0644 ${WORKDIR}/optee/stm32mp135d-odyssey.dts ${S}/stm32mp1/optee

    # U-Boot expands $(dtb-y) while reading the dtbs: prerequisite, so the
    # board dtb has to sit in the existing list, not after that rule.
    for mk in ${S}/stm32mp1/u-boot/Makefile ${S}/stm32mp1/linux/Makefile; do
        sed -i '/stm32mp135d-odyssey\.dtb/d' "$mk"
        awk '
            /stm32mp135f-dk-ostl\.dtb/ && !inserted {
                print
                print "\tstm32mp135d-odyssey.dtb \\"
                inserted = 1
                next
            }
            { print }
        ' "$mk" > "$mk.odyssey"
        mv "$mk.odyssey" "$mk"
    done

    # OP-TEE enables CFG_STM32MP13 and the 512 MiB DDR size only for device
    # tree names listed in stm32mp1/optee/conf.mk. STM32MP135D has no CRYP.
    if ! grep -q '135D_ODYSSEY' ${S}/stm32mp1/optee/conf.mk; then
        cat >> ${S}/stm32mp1/optee/conf.mk << 'EOF'

# Seeed Studio ODYSSEY STM32MP135D: 512 MiB DDR3, no CRYP/SAES/PKA.
flavor_dts_file-135D_ODYSSEY = stm32mp135d-odyssey.dts
flavorlist-MP13 += $(flavor_dts_file-135D_ODYSSEY)
flavorlist-no_cryp-512M += $(flavor_dts_file-135D_ODYSSEY)
EOF
    fi
}
addtask install_odyssey_dt after do_symlink_externaldtsrc before do_configure
