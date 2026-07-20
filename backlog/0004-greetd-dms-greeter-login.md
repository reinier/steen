# Login: greetd + dms-greeter, straight into niri

- **Status:** done (CI-green 2026-07-20; real-boot checks in [0018](0018-first-boot-checklist.md))
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
COPR — but as of 0003's revision `avengemedia/danklinux` is **already** enabled for
quickshell 0.3.0, so dms-greeter costs no new repo. **Match its version to dms 1.5.2**
(both come from the same upstream release train). Document it plainly in the README and
`docs/third-party-repos.md` (see 0005 for that doc's start) so the exception is
visible, not smuggled.

> Revisit trigger: if `dms-greeter` ever lags Fedora's DMS/quickshell and breaks
> (the failure mode that pushed bluefin off the DMS git COPR), fall back to
> **greetd + tuigreet** (COPR-free) or GDM. Keep that escape hatch noted.

## Implementation sketch (port from Zirconium)

0. **The base's display manager is already gone.** The base logged in via **`sddm`
   0.21.0** with only a `sway.desktop` session; 0002's removal of the Sway stack
   orphaned `sddm` and dnf autoremoved it. So there is **nothing to remove here** —
   just verify no display-manager unit remains, then install greetd below. See
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

## Implemented (2026-07-20)

Inspected the actual `dms-greeter` 1.5.2 package before porting, which made most of
Zirconium's scaffolding unnecessary:

| Zirconium did | Steen | Why |
|---|---|---|
| hand-wrote `sysusers.d` (`greeter`, uid 767) | **omitted** | the package ships its own (dynamic uid) |
| hand-wrote `tmpfiles.d` for the cache dir | **omitted** | the package creates `/var/cache/dms-greeter` + `/var/lib/greeter` |
| passed `--cache-dir /var/cache/dms-greeter` | **omitted** | that's already the binary's default |
| `sed` out a stale niri `debug {}` block | **omitted** | verified gone from the 1.5.2 binary — the FIXME's "when dms-greeter gets a new release" has happened |
| `-C /etc/greetd/niri/config.kdl` | **omitted** | `-C` is for a *custom compositor config*; the niri hook is now `/usr/share/greetd/niri_overrides.kdl` |
| PAM `greetd-spawn` + `pam_env` wayland | **kept** | still the way to force `XDG_SESSION_TYPE=wayland` |

So Steen installs `dms-greeter` (which pulls `greetd` from Fedora) and ships three
small files: `/etc/greetd/config.toml`, `/usr/lib/pam.d/greetd-spawn`, and the
`pam_env` conf. `greetd.service` is enabled; `dms.service` (a user unit shipped by
`dms`) is enabled `--global` so the shell starts in every user session.

**Version tracking:** `dms-greeter` lives in the same `avengemedia/danklinux` channel
already enabled for quickshell, so it follows the same stable train as `dms` — no
version pins. The guard *prints* greetd/dms-greeter/dms versions so drift is visible,
and hard-fails if `sddm` ever reappears (two display managers fighting over the seat).

## Deferred to first boot

- **Keyring auto-unlock.** Zirconium additionally `sed`-ed `/etc/pam.d/greetd` to
  enable the `gnome_keyring.so` lines. Not ported blind — Fedora's stock greetd PAM
  may already differ, and the base ships `gcr3` rather than `gcr`. Verify whether the
  keyring unlocks at login and patch only if it doesn't ([0018](0018-first-boot-checklist.md) §B/§C).
- **Greeter appearance.** Zirconium seeded the greeter's DMS settings/colours from its
  baked `zdots`; Steen has no baked config, so the greeter uses defaults. If it should
  match the desktop theme, that's a `/usr/share/greetd/niri_overrides.kdl` + greeter
  settings job later.

## Verification

CI (done): `greetd` + `dms-greeter` installed, config/PAM present, `greetd.service`
enabled, no `sddm`.

Real hardware ([0018](0018-first-boot-checklist.md)): dms-greeter appears, password
logs straight into niri with no picker, `loginctl` shows a wayland session, keyring
unlocked without a second prompt.
