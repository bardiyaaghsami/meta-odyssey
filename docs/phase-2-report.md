# Phase 2 completion report

Historical record, 2026-10-08, written before the board files and scripts
were added. It is not the v0.1.0 status. See
[BUILD_VALIDATION_REPORT.md](BUILD_VALIDATION_REPORT.md).

Date: 2026-10-08.

At the time of this note, Phase 3 had not started. No recipe, device tree,
or machine file had been migrated. The private layer was not modified.

## What was created

Public skeleton: this repository.

- `README.md`, `LICENSE`, `.gitignore`
- `meta-odyssey/conf/layer.conf` skeleton, `README.md`, `COPYING.MIT`
- `scripts/README.md` stating that no scripts exist yet
- `manifests/openstlinux-6.2.1.md` with the pinned tag and layer revisions
- `docs/BSP_AUDIT.md` copied from the Phase 1 audit
- `docs/architecture.md`, `build.md`, `flashing.md`, `hardware.md`, `supported-hardware.md`, `known-issues.md`
- `docs/licensing.md`, `baseline-preservation.md`, `migration-inventory.md`

Preservation snapshot: stored outside this repository. It is not part of
this Git tree.

## Decisions

- Public v0.1.0 TF-A keeps IWDG2 disabled. Documented as a development configuration, not a production watchdog policy.
- Public sources are the tested working tree, not `HEAD` alone.
- LCD/LTDC Linux nodes and the OP-TEE LTDC ETZPC cell stay excluded.
- The temporary OP-TEE deferred-probe patch stays excluded.
- No claim is made that this tree builds or boots.

## Validation performed

- Original workspace `git status` was compared after the skeleton was written. No board file was edited.
- The public tree contains no `build/`, `tmp/`, `downloads/`, `sstate-cache`, or image artifacts.
- `meta-odyssey` contains no `.dts`, `.dtsi`, `.bb`, `.bbappend`, or `.patch` files.
- The migration inventory lists each tested hardware fix, the display exclusion, and the diagnostic exclusion.
- Licensing is split: MIT for new project files, upstream SPDX retained for device trees when they arrive.

## Not done

- Recipe migration
- Setup or build scripts
- A BitBake run of `meta-odyssey`
- A hardware boot of this tree
- A git commit of this skeleton (left for review)
