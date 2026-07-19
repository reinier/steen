# Steen

A personal [bootc](https://bootc-dev.github.io/bootc/) atomic Fedora image —
a **niri + [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)**
desktop built **directly on plain Fedora**, from Fedora's own stable packages.

> **Status: planning.** Nothing is built yet. The build is being scoped one item
> at a time in [`backlog/`](backlog/); start with
> [`backlog/0001-bootstrap-signed-image.md`](backlog/0001-bootstrap-signed-image.md).
> Cross-cutting analysis (e.g. the end-user delta vs. Zirconium) lives in
> [`notes/`](notes/).

## What Steen is (and why it exists)

Steen is the **successor to [rheniite](../rheniite/rheniite)**. Rheniite layers on
top of the community **Zirconium** base image, which pulls niri, DMS and quickshell
from rolling git COPRs (`yalter/niri-git`, `avengemedia/danklinux`,
`avengemedia/dms-git`) — the churn documented in rheniite's
[`backlog/stabilize-git-packages.md`](../rheniite/rheniite/backlog/stabilize-git-packages.md).

Two upstream changes make a clean break possible, so Steen drops **both** the
Zirconium base **and** every rolling desktop COPR:

- **niri** is now in Fedora main (`26.04`, F44/F45) —
  <https://packages.fedoraproject.org/pkgs/niri/niri/>
- **DankMaterialShell** is now an official Fedora package (landed via the
  [DankFedoraMiracleWM Change](https://fedoraproject.org/wiki/Changes/DankFedoraMiracleWM)),
  built on Fedora's already-packaged `quickshell` —
  <https://packages.fedoraproject.org/pkgs/DankMaterialShell/>

The whole desktop stack is therefore **co-tested Fedora stable**, not rolling git.

## Shape of the build (decided)

- **Base:** `quay.io/fedora-ostree-desktops/sway-atomic:44` — **Fedora Sway Atomic**,
  a GNOME-free wlroots/Wayland atomic desktop. **niri-only, no GNOME.** The
  base-desktop plumbing (network, portals, pipewire, polkit, fonts, flatpak) is
  inherited co-tested from Fedora; Steen only subtracts the few Sway defaults DMS
  replaces and adds niri/DMS. See
  [`backlog/0000-base-image-choice.md`](backlog/0000-base-image-choice.md) for why
  this over `fedora-bootc` or a stripped Silverblue.
- **Login:** `greetd + dms-greeter`, boots straight into niri (no picker) — the
  Zirconium experience. `dms-greeter` is a `avengemedia/danklinux` COPR package:
  the **one deliberate desktop-layer COPR exception** to Steen's no-COPR goal.
- **App set** (carried from rheniite): native firefox/chromium + codecs, native
  1Password, CLI toolkit, kitty, Synology Drive, keyd, Tailscale,
  system-config-printer. **Bazaar** replaces native VSCodium — apps come as
  Flatpaks from Flathub.
- **Signing:** Steen verifies its own update stream (baked pubkey + `policy.json`),
  same mechanism as rheniite but established from scratch on the bare base.
- **Install / rebase:** install a stock Fedora atomic desktop, then
  `sudo bootc switch ghcr.io/reinier/steen:latest`.
- **Config:** paired with a `dotfiles-steen` (chezmoi), seeded from
  [`dotfiles-bluefin-niri`](../conium/dotfiles-bluefin-niri) — the only existing
  dotfiles already authored against **stable** Fedora niri/DMS.

## Prior art in this workspace (read-only references)

- [`../rheniite/rheniite`](../rheniite/rheniite) — the image Steen succeeds
  (Containerfile, signing, `/opt` relocations, backlog conventions).
- [`../conium/inspiration/zirconium`](../conium/inspiration/zirconium) — the base
  Steen replaces; its `mkosi.conf.d/base-desktop.conf` + `theme.conf` are the
  package-list source of truth for what a niri/DMS base needs.
- [`../conium/dotfiles-bluefin-niri`](../conium/dotfiles-bluefin-niri) — the
  proven "niri+DMS from stable Fedora, no COPR" layering.
