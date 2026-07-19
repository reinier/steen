# Base image choice: Fedora Sway Atomic

- **Status:** accepted
- **Created:** 2026-07-19
- **Area:** image (`Containerfile` `FROM`) — the decision every other item rests on
- **Depends:** —
- **Related:** rheniite `FROM ghcr.io/zirconium-dev/zirconium`; Zirconium's own
  `FROM` chain (mkosi on `fedora-bootc-ostree`,
  [`inspiration/zirconium`](../../conium/inspiration/zirconium));
  [wayblue](https://github.com/wayblueorg/wayblue) (Fedora Atomic niri image, the
  closest precedent to Steen's shape).

## Decision

Steen builds **`FROM quay.io/fedora-ostree-desktops/sway-atomic:44`** — Fedora Sway
Atomic (formerly Sericea), a **GNOME-free wlroots/Wayland atomic desktop** base.

## Why (the three candidates weighed)

| | `fedora-bootc` | Silverblue + strip GNOME | **Sway Atomic** (chosen) |
|---|---|---|---|
| Base-desktop plumbing | build it all | inherited (GNOME's) | **inherited (wlroots)** |
| GNOME baggage | none | present, or fragile to remove | **none** |
| What Steen subtracts | nothing | a whole DE (dep-graph fights, re-pulled on bumps) | ~a handful of Sway utils DMS already replaces |
| Effort / risk | highest (rebuild the desktop base) | low but fragile | **low + clean** |
| Result | leanest | compromised | nearly as lean, no GNOME |
| Precedent | Zirconium (from bare) | — | wayblue's niri image |

The win we're buying: **the base-desktop plumbing (PipeWire, portals, polkit agent,
keyring, fonts, NetworkManager, plymouth, flatpak) is pre-assembled and co-tested by
Fedora** — that's the bulk of what a `fedora-bootc` build would hand-assemble in
`0002`. Sway Atomic captures that *without* GNOME: what it bundles that Steen
doesn't want (waybar, rofi, dunst, swaylock, Thunar) is a short list, and **DMS
replaces every one** — so the subtraction is trivial vs. removing a DE from
Silverblue (the "worst of both worlds" option we rejected).

## Consequences threaded into other items

- **`0002`** shrinks from "build the desktop base" to "subtract the Sway defaults DMS
  replaces + add the two niri-specific bits (portal-gnome, nautilus)".
- **`0004`** (greetd + dms-greeter) is unchanged — it replaces whatever login
  manager the base ships regardless.
- **`0006` / `0008`** (`/opt` relocation) unchanged — `/opt`, `/usr/local`, `/home`
  are `/var`-backed symlinks on *every* Fedora ostree base, Sway Atomic included.
- Install path is unaffected: install any Fedora atomic desktop, then
  `bootc switch ghcr.io/reinier/steen:latest` (rebasing *from* Sway Atomic is the
  smallest delta, but any base works).

## To confirm at implementation

- Exact variant slug + tag on `quay.io/fedora-ostree-desktops` (`sway-atomic` vs
  legacy `sericea`; tag `44` = `$(rpm -E %fedora)`).
- The image is `FROM`-able and `bootc container lint`-clean on F44 (Atomic Desktops
  gained bootc in F41; verify no lint regressions).

## Fallback

If the inherited Sway defaults prove noisier than expected to tame, the documented
fallback is `fedora-bootc` + the full hand-built `0002` (the original plan, kept in
git history). Silverblue-strip stays rejected.
