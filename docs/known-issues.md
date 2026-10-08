# Known issues

## UART4 pins are secure

Linux enables `serial@40010000` and does not request PA13 or PE5. OP-TEE
locks both. TF-A and OP-TEE set AF8, and `/dev/ttySTM0` works on the
flashed image. The old Linux messages `Can't access gpio 13` and
`Error applying setting` are gone.

Two follow-ons were not tested on this image:

- Suspend and resume. With no UART4 pinctrl state, Linux will not restore
  the mux. It stays as secure firmware left it.
- U-Boot still contains `uart4_pins_odyssey` and still requests those pins.
  That node was left as-is. The U-Boot console was not rechecked on its own
  after the Linux rebuild.

## IWDG2 is off in TF-A

```
&iwdg2 {
    status = "disabled";
};
```

v0.1.0 keeps this so the TF-A watchdog does not reset the board during
bring-up. A later release that turns it on needs its own timeout and a
boot test. `status = "disabled"` does not override a watchdog the BootROM
or option bytes force on. This layer does not read or write those, and it
does not burn fuses. Linux `&arm_wdt` is a different watchdog: it stays
enabled with a 32-second timeout.

## Not retested, or not tested, on the flashed image

Image SHA256
`005c9c0e5542591504c9a667cbde519a9e58fdda2edcd5270537fdcee992f47f`.

- Ethernet beyond link state. `end0` and `end1` are UP and LOWER_UP.
- USB mass storage. Host controllers enumerate.
- Suspend and resume. See UART4 above.
- eMMC boot. The part enumerates as 3.5 GiB. The flash layout is SD only.
- OP-TEE, SCMI, CPUFreq, and thermal. Those passed on the previous image,
  before the UART4 Linux change.

## Display

Panel timing, LTDC, backlight, and touch are not in this layer. OP-TEE
does not include the LTDC ETZPC cell.

## BitBake on Ubuntu 24.04

BitBake exits while `kernel.apparmor_restrict_unprivileged_userns=1`.
The scripts do not change that sysctl. A reboot can set it back to `1`.
See [build.md](build.md).

Earlier phase notes (`BSP_AUDIT.md`, `BSP_MIGRATION_REPORT.md`,
`baseline-preservation.md`, `migration-inventory.md`, `phase-2-report.md`)
are the migration record, not the current test log. Use
[BUILD_VALIDATION_REPORT.md](BUILD_VALIDATION_REPORT.md) for that.
