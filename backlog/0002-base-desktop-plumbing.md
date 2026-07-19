# Adapt the Sway Atomic base for niri/DMS

- **Status:** accepted
- **Created:** 2026-07-19 (reworked for the Sway Atomic base — see 0000)
- **Area:** image (`Containerfile`)
- **Depends:** 0000, 0001
- **Related:** what the base already ships
  ([Fedora Sway Atomic](https://fedoraproject.org/atomic-desktops/sway/));
  Zirconium's package `Remove=` list in
  [`mkosi.conf.d/theme.conf`](../../conium/inspiration/zirconium) (it already drops
  waybar/mako/swaylock/swayidle/fuzzel — the same subtraction, well-trodden);
  [wayblue](https://github.com/wayblueorg/wayblue) (a Fedora Atomic niri image).

## What changed vs. the original plan

This item used to be "build the whole desktop base on bare `fedora-bootc`". With the
Sway Atomic base (0000) it collapses to a small **adapt** step, because the base
already provides — **verify, don't install** — PipeWire/WirePlumber, xdg-desktop-
portal (+ a backend), a polkit authentication agent, gnome-keyring/gcr,
NetworkManager, plymouth, fonts, and flatpak. The job is only to (a) subtract the
Sway defaults DMS/niri replace, and (b) add the two niri-specific bits the base
lacks.

## (a) Subtract — Sway defaults DMS/niri make redundant

DMS provides the bar, launcher, notifications, and lock; niri provides the
compositor. So remove (or mask) the base's:

- `waybar` (→ DMS bar), `rofi`/`wofi` (→ DMS spotlight), `dunst` (→ DMS
  notifications), `swaylock` + `swayidle` (→ DMS lock/idle), `sway` itself + its
  session/config, and the Sway `foot`-as-default wiring (Steen uses kitty, 0003).
- **`Thunar` → replace with `nautilus`** — Steen needs Nautilus specifically for the
  Nextcloud/Synology Nautilus extensions (0008 and the Nextcloud item). Install
  `nautilus` (+ `nautilus-python` if the extensions need it).
- **Keep** `kanshi` (display hotplug config is still useful under niri — Zirconium
  keeps it), brightness/`light`/`playerctl`/`wl-clipboard`-type utilities, and
  Firefox (0005 installs it anyway; dedupe).

> Removal mechanics on a layered bootc image: prefer `dnf5 remove` in the
> Containerfile; where a package is protected/comps-pinned, `systemctl mask` the
> unit instead of fighting the dep graph. Keep this list short and reviewed.

## (b) Add — niri-specific bits the base lacks

- `niri`, `DankMaterialShell`, `quickshell`, `kitty`, `xwayland-satellite` — this is
  really **0003**; listed here only so the dependency is explicit.
- **`xdg-desktop-portal-gnome`** — niri uses it for screencast/screenshot; the Sway
  base ships `xdg-desktop-portal-wlr`. Add `-gnome` (keep `-gtk`); decide whether to
  also remove `-wlr` or leave it (Zirconium ships gnome + gtk).
- Confirm a **polkit auth agent actually prompts under niri** — the base has one for
  Sway, but verify it (or DMS's) shows a dialog on a niri session; if not, add a
  standalone agent.

## Verify the inherited plumbing (don't reinstall)

At build/boot time confirm the base already gives: `wpctl status` (audio), a portal
on the session bus (`busctl`), `nmcli` (network), keyring unlock, no font tofu,
`flatpak` present. Add **only** what's genuinely missing. Also confirm `/opt`,
`/usr/local`, `/home` are `/var`-backed symlinks (they are on every Fedora ostree
base) so the 0006/0008 relocations apply unchanged.

## Login manager note

The base ships some display manager (SDDM/greetd/other). Steen replaces it with
greetd + dms-greeter in **0004** — disable/mask the base's DM there, not here.

## Fonts

Base fonts cover Latin + emoji. Bake a **Nerd Font** (JetBrainsMono Nerd — rheniite
got it via a brew cask; bake it so it's present at boot for kitty/DMS glyphs).

## Verification

- After 0003/0004: log into niri, DMS comes up, screencast works (portal-gnome),
  audio/network/keyring all functional, and none of the removed Sway tools linger
  (no stray waybar/dunst). Nautilus opens and loads its extensions.
