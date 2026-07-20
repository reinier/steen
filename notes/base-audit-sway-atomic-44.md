# Base audit — `quay.io/fedora-ostree-desktops/sway-atomic:44`

Ground truth for what Steen's base actually ships, probed in CI on **2026-07-20**
(1432 packages). This is what [`0002`](../backlog/0002-base-desktop-plumbing.md) and
[`0017`](../backlog/0017-hardware-session-niceties.md) mean by "verify, don't
reinstall" — the numbers below replace the earlier "likely yes / probably not"
guesses.

> Re-run the probe by restoring `.github/workflows/audit-base.yaml` from git history
> and dispatching it, if the base changes materially.

## Already there — do NOT reinstall

| Area | Present |
|---|---|
| Audio | `pipewire` 1.6.8, `wireplumber` 0.5.14 |
| Network | `NetworkManager` 1.56.1 (+`-wifi`), `systemd-resolved`, `firewalld` |
| Session | `xdg-desktop-portal` 1.22.1, `-gtk`, `-wlr`; `polkit` 127 + **`lxqt-policykit`** agent; `gnome-keyring` 50.0 + **`gcr3`** |
| Boot/power | `plymouth`, `tuned`, `zram-generator` |
| Hardware | **`fwupd` 2.1.6, `fprintd` 1.94.5, `bolt` 0.9.11** — all three of 0017's Framework must-haves |
| Printing | `cups` 2.4.19, **`system-config-printer` 1.5.18**, `avahi`, `nss-mdns` |
| Containers | `podman` 5.8.4, `toolbox` |
| Apps/X11 | `flatpak` 1.18.0, `xorg-x11-server-Xwayland` |
| Fonts | Extensive Noto/Liberation/urw set incl. `google-noto-color-emoji-fonts` |

## Absent — Steen must add

`xdg-desktop-portal-gnome` (0002) · `nautilus` (0002) · **Nerd Font** (0002; only
non-Nerd `jetbrains-mono-fonts` exists in Fedora, and it isn't installed either) ·
`niri`, `DankMaterialShell`, `quickshell`, `kitty`, `xwayland-satellite` (0003) ·
`greetd` (0004) · `chromium` (0005) · `distrobox` (0017 — base has only `toolbox`) ·
`cups-pk-helper` (0012) · `ddcutil` (0017) · `tailscale` (0010) · `keyd` (0009) ·
`xdg-terminal-exec`

## The Sway stack to subtract

`sway` 1.11, `waybar`, `rofi` 2.0, `dunst`, `swaylock`, `swayidle`, `swaybg`,
`foot`, `Thunar` — DMS/niri replace every one. Keep `kanshi`, `brightnessctl`,
`playerctl`, `wl-clipboard`, `imv`. `firefox` 152 is present and removed by decision
(0005: Chromium only).

## Findings that changed the plan

1. **The display manager is `sddm` 0.21.0** (with `sddm-wayland-sway`), not greetd.
   → 0004 must remove/mask **sddm** specifically. Only wayland session is `sway.desktop`.
2. **`system-config-printer` is already installed** → 0012 shrinks to adding
   `cups-pk-helper` (absent), which is what makes polkit-based printer admin work.
3. **`fprintd` + `fwupd` + `bolt` already present** → 0017's must-haves need no action;
   it reduces to adding `distrobox` (+ `ddcutil` if wanted).
4. **Polkit agent is `lxqt-policykit`** — a Qt agent wired for Sway. Verify it actually
   autostarts and prompts under niri, or replace/autostart it from the dotfiles.
5. **`gcr3`, not `gcr`** — Zirconium used `gcr` (v4) for `gcr-ssh-agent`. If DMS or the
   keyring/ssh-agent path expects gcr4, that's an explicit add.
6. **Portals:** base has `-wlr` + `-gtk`. niri wants `-gnome` for screencast; Steen adds
   `-gnome` and removes `-wlr` so backend selection is unambiguous.
