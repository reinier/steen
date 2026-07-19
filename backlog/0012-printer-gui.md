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

- CUPS itself + mDNS discovery: rheniite got them from the Zirconium base. The
  Sway Atomic base likely ships `cups`/`avahi`/`nss-mdns` too — **verify in 0002**
  (socket-activated `cups.socket`, mDNS resolves a WiFi printer) and only add
  explicitly if missing.

## Verification

- `system-config-printer` finds a network printer (driverless `dnssd://`), adds a
  queue with a polkit password prompt, and prints a test page.
