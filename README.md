# Steen

Steen is a personal, atomic Fedora desktop image built around
**[niri](https://github.com/YaLTeR/niri)** — a scrollable-tiling Wayland
compositor — and **[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)**,
which provides the bar, launcher, notifications, and settings. It boots straight
into a complete, ready-to-use desktop.

Everything is built from **stable, tagged releases** — niri from Fedora, and
DankMaterialShell from its upstream stable channel — so the desktop stays
predictable rather than chasing nightly builds.

> ## 🚧 Work in progress — not usable yet
>
> **Current state:** design/planning only. This repo holds the *plan* for Steen —
> see [`backlog/`](backlog/) for the build items and [`notes/`](notes/) for
> background. **No image has been built or published**, there is nothing to install
> yet, and the steps below will not work until a first release exists. Everything
> below describes what Steen is intended to become.

## Install (once released)

Steen is image-based: you install a Fedora atomic desktop and then rebase onto it.

**Start from the [Fedora Sway Atomic](https://fedoraproject.org/atomic-desktops/sway/)
ISO.** Steen is built directly on top of that image, so the rebase is a minimal,
same-lineage delta (only Steen's layers download — no throwaway GNOME as you'd get
from Silverblue), and stock Sway Atomic doubles as a known-good reference desktop if
you need to isolate a hardware issue. Any Fedora atomic desktop *works* — `bootc
switch` replaces the whole image — but Sway Atomic is the efficient choice.

```sh
sudo bootc switch ghcr.io/reinier/steen:latest
sudo systemctl reboot
```

## What you get

- **Desktop** — niri + DankMaterialShell with the kitty terminal; boots straight
  in, no session picker.
- **Browser** — Chromium, with full media codecs.
- **Apps** — 1Password, Synology Drive, and **Bazaar** for installing Flatpaks
  from Flathub.
- **Terminal toolkit** — fish, starship, eza, bat, yazi, and friends.

## Updating

You update each part yourself, whenever you want — nothing changes unattended:

```sh
sudo bootc upgrade     # the OS
flatpak update         # your apps
```

## Configuration

Steen provides the desktop and apps, not a personal setup. Bring your own dotfiles
for the tailored experience — niri keybinds, DMS theming, shell config, key remaps,
and the like.

## Notes

Steen is a personal project, not an official Fedora product. niri and
DankMaterialShell are independent upstream projects.
