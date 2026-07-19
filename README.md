# Steen

Steen is a personal, atomic Fedora desktop image built around
**[niri](https://github.com/YaLTeR/niri)** — a scrollable-tiling Wayland
compositor — and **[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)**,
which provides the bar, launcher, notifications, and settings. It boots straight
into a complete, ready-to-use desktop.

Everything is built from **stable Fedora packages**, so the desktop stays
co-tested and predictable rather than chasing bleeding-edge builds.

> **Status:** early / in development — the image isn't published yet.

## Install

Steen is image-based: you install a Fedora atomic desktop and then rebase onto it.

```sh
sudo bootc switch ghcr.io/reinier/steen:latest
sudo systemctl reboot
```

## What you get

- **Desktop** — niri + DankMaterialShell with the kitty terminal; boots straight
  in, no session picker.
- **Browsers** — Firefox and Chromium, with full media codecs.
- **Apps** — 1Password, Nextcloud, Synology Drive, and **Bazaar** for installing
  Flatpaks from Flathub.
- **Terminal toolkit** — fish, starship, eza, bat, lazygit, yazi, and friends,
  plus Homebrew for anything else.
- **Tap-hold Super key** — tap for the app menu, hold as the window modifier.

## Updating

You update each part yourself, whenever you want — nothing changes unattended:

```sh
sudo bootc upgrade     # the OS
flatpak update         # your apps
brew upgrade           # CLI tools
```

## Notes

Steen is a personal project, not an official Fedora product. niri and
DankMaterialShell are independent upstream projects.
