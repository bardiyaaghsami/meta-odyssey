# BSP migration report

Historical Phase 3 record, 2026-10-08. The Linux UART4 pinctrl change and
the SD boot came after this report. Current status is in
[BUILD_VALIDATION_REPORT.md](BUILD_VALIDATION_REPORT.md).

Phase 3 compared the public layer with the tested working tree, not with
Git `HEAD` alone. That workspace was not modified. No image was built in
this phase.

`HEAD` remains `3bafc7d75eac842d0db14aae9c414271fed76fb2`.

## Comparison

| Original file | Public destination | Status | Changes | Reason | Validation |
| --- | --- | --- | --- | --- | --- |
| `meta-patvaz/conf/machine/odyssey-stm32mp135d.conf` | `meta-odyssey/conf/machine/odyssey-stm32mp135d.conf` | Migrated | None. Byte-identical. | Preserve the tested machine identity, Cortex-A7 tune, SD/OP-TEE boot labels, and DT name. | Static. File present. No extra `MACHINE_FEATURES`. |
| `meta-patvaz/conf/layer.conf` | `meta-odyssey/conf/layer.conf` | Replaced | Collection `odyssey`, priority 8, Scarthgap. Comment updated after migration. | Do not publish the `patvaz` collection name. | Static. `BBFILES` matches `recipes-*/*/*.bbappend`. |
| `external-dt_6.0.bbappend` | `meta-odyssey/recipes-bsp/external-dt/external-dt_6.0.bbappend` | Migrated | Task renamed `do_install_odyssey_dt`. Temp file suffix `.odyssey`. | Same external-dt install mechanism without the product task name. | Static. All six `file://` paths exist beside the bbappend. No absolute developer paths. |
| `tf-a/stm32mp135d-odyssey.dts` | same relative path | Migrated | Working tree kept, including `&iwdg2 { status = "disabled"; }`. A comment states this is a development policy. | Approved v0.1.0 TF-A configuration. | Static. IWDG2 disabled. DDR include and 512 MiB node present. SPDX unchanged. |
| `tf-a/stm32mp135d-odyssey-fw-config.dts` | same relative path | Migrated | None. | `DDR_SIZE` `0x20000000`. | Static. SPDX unchanged. |
| `optee/stm32mp135d-odyssey.dts` | same relative path | Migrated with one deletion | Removed `DECPROT(STM32MP1_ETZPC_LTDC_ID, ...)`. All other working-tree fixes kept. | LTDC access is experimental display scope. | Static. PMIC IRQ, CPU supply, LDO4, LDO5, PWR_SW2, secure GPIOs, `pwr_irq`, and non-display ETZPC cells present. LTDC cell absent. SPDX unchanged. |
| `u-boot/stm32mp135d-odyssey.dts` | same relative path | Migrated | None. | Working tree already had no panel or LTDC nodes. | Static. UART4, Ethernet, SDMMC, USB, SCMI labels present. SPDX unchanged. |
| `u-boot/stm32mp135d-odyssey-u-boot.dtsi` | same relative path | Migrated | None. | SD environment and `bootph-all` on UART4. | Static. SPDX unchanged. |
| `linux/stm32mp135d-odyssey.dts` | same relative path | Migrated from `HEAD` | The 132-line working-tree display addition was not copied. | That addition is the experimental panel, backlight, and LTDC enable. | Static. Identical to development `HEAD`. No `panel-odyssey`, backlight node, PI7, PB13, or `&ltdc`. SPDX unchanged. Linux `&arm_wdt` remains 32 s and okay. |
| `optee-os-stm32mp_%.bbappend` | `meta-odyssey/recipes-security/optee/optee-os-stm32mp_%.bbappend` | Migrated with a deletion | Kept `CFG_STM32MP13=y`, `CFG_DRAM_SIZE=0x20000000`, and `CFG_EXT_DTS`. Removed the diagnostic `SRC_URI`. | The patch is temporary and is not a demonstrated boot dependency. | Static. No `0002-odyssey-temporary-deferred-probe-log.patch` in the layer. |
| `0002-odyssey-temporary-deferred-probe-log.patch` | none | Excluded | Not copied. | Temporary diagnostic. | Static. Filename absent from `meta-odyssey`. |
| Linux `panel-odyssey`, `backlight-odyssey`, `sys_3v3`, LTDC pinctrl, `&ltdc` | none | Excluded | Not copied. | Experimental display. | Static. Those node names are absent. Remaining "panel" / "LTDC" strings are comments that say they are not enabled. |
| Development `scripts/setup-env.sh` | none | Not migrated | Still appends `meta-patvaz` inside the development workspace. | Phase 4 owns the public setup script. | Not applicable. |

## Device tree result

Linux public tree equals the development `HEAD` blob
`07b5d8734f11363834563d142cfb55fcccf00e96`. Brace balance is zero on every
migrated `.dts` and `.dtsi`.

OP-TEE public tree is the working tree minus the LTDC `DECPROT` line.
TF-A public tree is the working tree plus the IWDG2 comment.
U-Boot files are copies of the working tree.

## Recipe result

No new recipes. Two bbappends:

- `external-dt_6.0.bbappend` installs the six board files and appends the
  ODYSSEY flavor to `stm32mp1/optee/conf.mk`.
- `optee-os-stm32mp_%.bbappend` passes `CFG_STM32MP13=y` and
  `CFG_DRAM_SIZE=0x20000000`.

`FILESEXTRAPATHS` is `${THISDIR}/stm32mp135d-odyssey`. References are
relative. No absolute developer path appears in `meta-odyssey`.

## Static validation

| Check | Result |
| --- | --- |
| Expected machine, bbappends, and six device trees exist | Pass |
| Experimental panel, backlight, PI7, PB13, `bgr666`, 27 MHz timing, `&ltdc` | Absent |
| OP-TEE LTDC ETZPC cell | Absent |
| Diagnostic patch | Absent |
| OP-TEE PMIC, SCMI, secure GPIO, `pwr_irq`, non-display ETZPC | Present |
| TF-A IWDG2 disabled | Present |
| SPDX lines unchanged | Pass |
| Generated images or `deploy/` inside the public repository | Absent |
| Development `git status` after migration | Unchanged |
| Isolated `bitbake -p` | Not completed |

An isolated parse directory was created outside both repositories. Its
`bblayers.conf` points at `meta-odyssey` and its
`TMPDIR` is private. BitBake exited 1 before recipe parsing:

```text
ERROR: User namespaces are not usable by BitBake, possibly due to AppArmor.
```

`kernel.apparmor_restrict_unprivileged_userns` was `1`. It was not changed.
The development `bblayers.conf` still lists `meta-patvaz`.

This is not a build validation and not a hardware validation.

## Unresolved risks

- Metadata has not been parsed, so a bbappend override or missing ST task
  name (`do_symlink_externaldtsrc`) is not confirmed by BitBake.
- The public layer is not added by any setup script yet. A build that
  leaves `meta-patvaz` on `BBLAYERS` would see two machine files at the
  same priority.
- IWDG2 disabled is the tested development configuration. It is not a
  production watchdog policy, and device tree status does not override a
  hardware-forced watchdog.
- eMMC boot remains unverified.
- Removing the diagnostic patch has no demonstrated dependency. That is
  only a source-level statement until a firmware build runs without it.
