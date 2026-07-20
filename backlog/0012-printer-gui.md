# Printer management GUI

- **Status:** accepted
- **Created:** 2026-07-19
- **Area:** image (`Containerfile`)
- **Depends:** 0002 (CUPS lives in the base-desktop plumbing)
- **Related:** rheniite
  [`Containerfile`](../../rheniite/rheniite/Containerfile) "Printer management GUI".

## Port, not redesign

No GNOME Control Center on niri, and the DMS printer panel needs a backend "cups"
capability this stack doesn't advertise — so ship the self-contained
`system-config-printer` GTK tool. It drives CUPS via the `cups-pk-helper` polkit
mechanism, so a wheel user adds/removes printers with their own password (no root,
no CUPS SystemGroup membership).

## Notes

**Audit result (2026-07-20), corrected after implementing 0002.** The base ships
`cups` 2.4.19, `avahi` and `nss-mdns` (so CUPS + mDNS discovery need no action) and it
*did* ship `system-config-printer` 1.5.18 — **but 0002's removal of the Sway desktop
orphaned it, and dnf autoremoved it**. So this item must install both:

```dockerfile
RUN dnf5 -y install system-config-printer cups-pk-helper && dnf5 clean all
```

`cups-pk-helper` (absent from the base) is what lets a wheel user add/remove printers
via polkit with their own password instead of root.

See [`../notes/base-audit-sway-atomic-44.md`](../notes/base-audit-sway-atomic-44.md).

## Verification

- `system-config-printer` finds a network printer (driverless `dnssd://`), adds a
  queue with a polkit password prompt, and prints a test page.
