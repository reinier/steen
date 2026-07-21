# Adapt the Sway Atomic base for niri/DMS

- **Status:** done (CI-green 2026-07-20; real-boot checks in [0018](0018-first-boot-checklist.md))
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
  Synology Drive Nautilus extension (0008). Install `nautilus` (+ `nautilus-python`
  if the extension needs it).
- **`firefox` → remove.** The base ships Firefox; Steen ships a single native browser
  (Chromium, 0005). `dnf5 remove firefox` (or `systemctl mask` any base autostart)
  so it doesn't linger.
- **Keep** `kanshi` (display hotplug config is still useful under niri — Zirconium
  keeps it) and brightness/`light`/`playerctl`/`wl-clipboard`-type utilities.

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

The base's display manager is **`sddm` 0.21.0** (audit-confirmed; the only wayland
session was `sway.desktop`). Steen replaces it with greetd + dms-greeter in **0004** —
remove/mask `sddm` there, not here. `sddm-wayland-sway` is already gone with sway.

## Fonts

Base fonts cover Latin + emoji, but not the **Nerd Font** icon glyphs kitty/DMS use.
Fedora ships only plain `jetbrains-mono-fonts` (no Nerd glyphs), so bake the
**JetBrainsMono Nerd Font from the upstream release archive** (pinned version):
download it in the `Containerfile`, unpack into `/usr/share/fonts/`, `fc-cache`. This
is brew-free and repo-free (the keyd source-build pattern). rheniite got this via a
brew cask; Steen ships no brew (see [0015](0015-no-homebrew.md)). *(Alternative: the
`che/nerd-fonts` COPR — rejected to avoid another third-party repo.)*

## Implemented (2026-07-20)

Base audited in CI first — findings in
[`../notes/base-audit-sway-atomic-44.md`](../notes/base-audit-sway-atomic-44.md).
The `Containerfile` now:

- **Removes** `sway`, `sddm-wayland-sway`, `waybar`, `rofi`, `dunst`, `swaylock`,
  `swayidle`, `swaybg`, `foot`, `Thunar`, `firefox`, `xdg-desktop-portal-wlr`.
- **Keeps** `kanshi`, `brightnessctl`, `playerctl`, `wl-clipboard`, `imv` — and
  `sddm` (0004 swaps it for greetd + dms-greeter).
- **Adds** `xdg-desktop-portal-gnome`, `nautilus`, and the JetBrainsMono **Nerd
  Font** baked from the upstream release (pinned `v3.4.0`, `ARG NERD_FONT_VERSION`).
- **Guards** the removals with an assertion (naming any missing package) so a
  dependency cascade that takes out pipewire/NetworkManager/portals/polkit/keyring/
  fwupd/etc. fails the build instead of shipping a quietly broken image.

**The guard immediately earned its keep.** The first build failed on it: `dnf` removes
orphaned dependencies as well as reverse-dependencies, so the subtraction pulled **21**
packages, not the 12 named — including `system-config-printer` (an orphan of the Sway
desktop; 0012 now reinstalls it), `sddm` (orphaned with its sway session — harmless,
0004 replaced it anyway), `blueman` (it required `dunst` as its notification daemon;
DMS provides the Bluetooth UI), plus `grimshot`, `sway-config-fedora`, `sway-systemd`,
`thunar-archive-plugin` and `firefox-langpacks`. Without the guard this would have
shipped as a silently degraded image.

Audit corrections worth noting: most base-desktop plumbing was already present
(so nothing was reinstalled), the polkit agent is **`lxqt-policykit`**, and the
keyring ships **`gcr3`** rather than `gcr`.

### Second leftover sweep (2026-07-21) — surfaced on real hardware

The first cut removed the obvious Sway *desktop* (waybar/rofi/etc.), but a lot of
Sway-spin **apps/agents** remained and showed up on the running system: a redundant
`nm-applet` wifi tray icon, and launcher entries the user never chose. An image audit
(`audit-leftovers.yaml`, since removed) enumerated `/etc/xdg/autostart` + the
`.desktop` set. Removed (guarded, skip-if-absent):

- `network-manager-applet` + `nm-connection-editor` (the wifi tray icon; DMS owns network)
- `xfce4-panel`, `tuned-switcher`, `xarchiver`, `imv` (stray launcher entries)
- `ibus` + CJK engines (typing-booster/m17n/anthy/hangul/chewing/libpinyin) — CJK dropped in 0017
- `orca` (screen-reader autostart)
- masked the `geoclue-demo-agent` autostart (kept geoclue2)

`localsearch` (the tracker file indexer) is **kept and left running** — nautilus
hard-`Requires` it, and whether to stop its background indexing is deferred to
[0019](0019-file-indexer-localsearch.md).

**Cascade caught (again):** the first attempt also `dnf remove`d `localsearch`, but
**nautilus hard-`Requires: localsearch`** (GNOME 50 wired tracker into Files' search), so
that dragged nautilus out — and the plumbing guard failed the build. That's why it's kept
(and the running/exclude/mask decision is parked in 0019). The guard doing its job — third
time it's caught a cascade.

Kept deliberately: `pavucontrol` (advanced audio routing DMS's basic controls lack),
`lxqt-policykit`, `gnome-keyring`, `grim`/`slurp`/`wlr-randr`. The absence guard asserts
the leftovers are gone *and* the base plumbing survived the cascade.

## Regression found on first boot (2026-07-20) — the removals didn't stick

The subtraction here removed waybar/etc., but the image booted with **waybar running
alongside the DMS bar** anyway. Cause: **Fedora's `niri` package
`Recommends: waybar, fuzzel, swaylock, alacritty`**, so 0003's `dnf install niri` (weak
deps on) re-added them after 0002 removed them. This item's guard only asserted that
*wanted* plumbing survived — it never checked the *removed* set stayed gone, so the
regression built green.

Fixed in **0003**: install niri with `--setopt=install_weak_deps=False`, then a purge +
**absence guard** that fails the build if any Sway/menu UI (incl. `dmenu`, which the
base shipped) is still present. Lesson: **guard both presence and absence.**

### …but that was only *half* the cause (learned from the real config)

The install's `~/.config/niri/config.kdl` turned out to be **niri's own stock default**
— which contains `spawn-at-startup "waybar"` and the stock alacritty/fuzzel/swaylock
binds, *not* DMS's config. niri writes that default to disk on first launch when no
config exists, so the double bar had **two independent sources**:

1. the waybar **package** (this item / 0003) — fixed here, and
2. niri's **default config** literally spawning waybar — a **dotfiles** concern, not an
   image one.

The image fix (removing the package) means the default's `spawn-at-startup "waybar"`
now just fails silently. The *real* fix — replacing niri's default with DMS's config — is
in `dotfiles-steen`'s `run_once_after_niri-dms-config.sh`, which backs up niri's default
before `dms setup` (because `dms setup` is non-destructive and would otherwise skip it).
See [0014](0014-config-and-dotfiles-steen.md). Broader lesson: a "package present"
symptom can have a parallel "config references it" cause; check both.

## Resolved on hardware (2026-07-21)

- **Polkit agent under niri:** ✅ `lxqt-policykit` **does** prompt under niri (`pkexec true`
  pops a password dialog). No change needed.
- **`gcr3` vs `gcr`:** ✅ the keyring/ssh-agent path works with `gcr3` — no `gcr4` needed.

## Still open

- `nautilus-python` is deferred to 0008 (only if the Synology extension needs it).

## Verification

- After 0003/0004: log into niri, DMS comes up, screencast works (portal-gnome),
  audio/network/keyring all functional, and none of the removed Sway tools linger
  (no stray waybar/dunst). Nautilus opens and loads its extensions. Nerd Font glyphs
  render in kitty/DMS (`fc-list | grep -i jetbrainsmono`).
