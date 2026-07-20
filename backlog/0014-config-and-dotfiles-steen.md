# Own the config: dotfiles-steen (seeded from bluefin-niri)

- **Status:** proposed
- **Created:** 2026-07-19
- **Area:** new repo `dotfiles-steen` (chezmoi) + image (default config, if baked)
- **Depends:** 0003 (desktop), 0004 (session) — needs installed binaries to target
- **Related:** rheniite
  [`backlog/own-desktop-config.md`](../../rheniite/rheniite/backlog/own-desktop-config.md)
  (the "own the config, don't inherit zdots" argument, applied here);
  [`dotfiles-bluefin-niri`](../../conium/dotfiles-bluefin-niri) (the seed);
  [`dotfiles-rheniite`](../../rheniite/dotfiles-rheniite) (keyd/Synology deltas to graft).

## Problem

Steen runs **stable** Fedora niri/DMS. Zirconium's `zdots` config is authored
against **git-HEAD** DMS/niri and re-applied daily — pointing Steen at it would
skew config against the installed binaries (niri refusing a post-`26.04` option,
`dms ipc` calling renamed verbs). Steen must **own its config**, targeted at the
stable stack. This is rheniite's `own-desktop-config` problem, and Steen must
solve it from the start (it has no zdots to fall back on).

## The seed already exists

`dotfiles-bluefin-niri` is the **only** dotfiles repo authored against **stable**
Fedora niri/DMS — it vendors a full DMS-generated `config.kdl` (because `dms setup`
can't run atomically) with a final `include "local.kdl"`, plus the dank-lader
leader menu, matugen theming, fish/kitty/starship, and the `rl-*` helpers. Seed
`dotfiles-steen` from it, then graft the **rheniite deltas** that fit Steen's image:

- **keyd** (root system service) instead of bluefin's kanata — matches 0009.
- **Synology Drive** wrapper + HiDPI fixup — matches 0008.
- **Drop** bluefin's 1Password-via-distrobox (Steen has native 1Password, 0006)
  and its GNOME-coexistence notes (Steen is niri-only).
- **Own the Flatpak app list**, including **Bazaar** (`io.github.kolunmi.Bazaar`) —
  the image ships Flatpak + the Flathub remote, the dotfiles decide which apps get
  installed ([0011](0011-bazaar-flatpak-appstore.md)). Bazaar is the app store itself,
  so put it first in the list.
- **Drop** the bluefin `rpm-ostree` layer + DMS-autostart script (the image bakes
  the desktop; DMS autostart comes from 0004's user preset).

## Decision to make: baked defaults vs dotfiles-only

- **A. Bake a default config into `/usr/share/steen/...`** (Zirconium's model) and
  have chezmoi lay personal overrides on top — a usable desktop even before
  `chezmoi apply`.
- **B. Dotfiles-only** — image ships binaries, all config comes from
  `dotfiles-steen`. Simpler image; a bare first boot until chezmoi runs.
- **Recommend B to start** (image stays a clean package layer; config iterates
  without image rebuilds — the split rheniite/bluefin already use), revisiting A
  only if a pre-`chezmoi` usable desktop becomes necessary (e.g. for the greeter,
  which already vendors its own config in 0004).

## Verification

- Fresh Steen install + `chezmoi apply` from `dotfiles-steen` → niri/DMS come up
  themed and bound, dank-lader works, keyd active, no config-schema errors in
  `niri validate` / DMS logs.
