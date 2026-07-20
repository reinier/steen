# Login: greetd + dms-greeter, straight into niri

- **Status:** accepted
- **Created:** 2026-07-19
- **Area:** image (`Containerfile`, greeter config, PAM, sysusers/tmpfiles, preset)
- **Depends:** 0002, 0003
- **Related:** Zirconium's greeter setup —
  [`mkosi.extra/usr/share/factory/etc/greetd/config.toml`](../../conium/inspiration/zirconium),
  `usr/lib/sysusers.d/dms-greeter.conf`, `usr/lib/pam.d/greetd-spawn`,
  `tmpfiles.d/99-dms-greeter.conf`, `mkosi.postinst.chroot` (dms-greeter patch).

## Decision (made) and its one caveat

Chosen: **greetd + dms-greeter**, boots straight into niri with **no session
picker** — the exact Zirconium/rheniite feel. The caveat, accepted deliberately:
**`dms-greeter` is not in Fedora** — it comes from the `avengemedia/danklinux`
COPR. So Steen, whose desktop core is otherwise 100% Fedora, takes **one
desktop-layer COPR** here. Document it plainly in the README and
`docs/third-party-repos.md` (see 0005 for that doc's start) so the exception is
visible, not smuggled.

> Revisit trigger: if `dms-greeter` ever lags Fedora's DMS/quickshell and breaks
> (the failure mode that pushed bluefin off the DMS git COPR), fall back to
> **greetd + tuigreet** (COPR-free) or GDM. Keep that escape hatch noted.

## Implementation sketch (port from Zirconium)

0. **Remove the base's display manager:** `dnf5 -y remove sddm`. The audit confirmed
   the base logs in via **`sddm` 0.21.0** (`sddm-wayland-sway` already went with sway
   in 0002), and the only wayland session was `sway.desktop`. See
   [`../notes/base-audit-sway-atomic-44.md`](../notes/base-audit-sway-atomic-44.md).
1. Install `greetd` (Fedora, absent from the base) + `dms-greeter` (COPR
   `avengemedia/danklinux`, added for the one install then the `.repo` removed — same
   discipline as every other third-party source; `gpgcheck=1`).
2. `greetd/config.toml` (from Zirconium):
   ```toml
   [default_session]
   command = "dms-greeter --command niri --cache-dir /var/cache/dms-greeter -C /etc/greetd/niri/config.kdl"
   user = "greeter"
   ```
   with `service = "greetd-spawn"`.
3. Greeter user via `sysusers.d` (Zirconium uses uid/gid 767); greeter DMS state
   symlinks via `tmpfiles.d`; PAM `greetd-spawn` (+ `pam_env` forcing
   `XDG_SESSION_TYPE=wayland`).
4. Vendor the greeter's own niri config at `/etc/greetd/niri/config.kdl`.
5. Enable `greetd` in the systemd **system preset**; wire DMS `dms.service` +
   keyring/gcr in the **user preset** (mirror Zirconium's presets).
6. Zirconium's `mkosi.postinst.chroot` patched a stale niri `debug{}` block out of
   the dms-greeter config and verified the niri build — re-check whether the
   **stable** niri/dms-greeter still need that patch (likely not; verify).

## Verification

- Reboot → dms-greeter appears (Material look), password logs straight into a niri
  session, no picker.
- `loginctl` shows a wayland session; keyring is unlocked (no second prompt).
