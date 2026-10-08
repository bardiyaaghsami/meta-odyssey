# stm32mp135d-odyssey.dts is not in OP-TEE's built-in flavor lists.
# Without CFG_STM32MP13 the platform makefile selects STM32MP15.
# Without CFG_DRAM_SIZE it selects 1 GiB and rejects the 512 MiB node.
# 0x20000000 is DDR_MEM_SIZE in stm32mp13-ddr3-1x4Gb-1066-binF.dtsi.
# The external-dt conf.mk records the same facts for the flavor lists.
EXTRA_OEMAKE:append:odyssey-stm32mp135d = " CFG_STM32MP13=y CFG_DRAM_SIZE=0x20000000"

# The TA SDK export build does not receive CFG_EXT_DTS. Point it at the
# same external OP-TEE directory the firmware build uses.
ST_OPTEE_EXPORT_TA_OEMAKE_EXTRA:odyssey-stm32mp135d = "CFG_EXT_DTS=${STAGING_EXTDT_DIR}/${EXTDT_DIR_OPTEE}"
