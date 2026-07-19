# Homebrew — bake it in (thin), for the tools Fedora doesn't package

- **Status:** proposed
- **Created:** 2026-07-19
- **Area:** image (`Containerfile`, `brew-setup` service + baked tarball), dotfiles (PATH, casks)
- **Depends:** 0001; interacts with 0007 (baked CLI toolkit) and 0014 (dotfiles: PATH + casks)
- **Related:** Zirconium bakes brew (baked Homebrew tarball + `brew-setup.service`,
  fetched in `mkosi.prepare.chroot` — [`inspiration/zirconium`](../../conium/inspiration/zirconium));
  rheniite [`README.md`](../../rheniite/rheniite/README.md) ("Moved here off the
  per-user Homebrew install the dotfiles used to do"); `dotfiles-rheniite`
  `environment.d/20-brew-path.conf` + the residual brew casks;
  `dotfiles-bluefin-niri` `run_once_after_firstrun-setup.sh` (brew formulae/casks);
  [ublue-os](https://github.com/ublue-os) brew-install pattern.

## Problem

rheniite got Homebrew **from the Zirconium base**, not by setting it up itself.
Steen's base — **Fedora Sway Atomic (0000)** — ships no brew (only ublue/Zirconium
images do). So unless Steen adds it, `brew` won't exist, and every dotfiles step
that shells out to it fails on first `chezmoi apply`.

Brew itself is base-agnostic: it lives in `/home/linuxbrew/.linuxbrew`
(`/var`-backed, user-writable), never in read-only `/usr` — so this is purely a
"do we bake it in" decision, not a compatibility one.

## What actually still needs brew

The toolkit is baked in the image (0007), the Nerd Font in 0002, GUI apps come via
Bazaar/Flatpak (0011). That leaves the brew-shaped residue:

- **`claude-code`** — not in Fedora; brew/npm/official installer are the paths.
- **`framework-tool`** — not in Fedora main; brew cask (as Bluefin uses).
- Ad-hoc dev CLIs wanted without an image rebuild.

## Options

1. **Bake brew, keep it thin** *(recommended)* — replicate the ublue/Zirconium
   mechanism (baked Homebrew tarball + a first-boot `brew-setup` service that
   extracts/chowns it to `/var/home/linuxbrew`, + the `linuxbrew` group). Image owns
   the core toolkit; brew is a thin layer for the unpackaged few. Familiar, low risk,
   keeps your `claude-code`/`framework-tool` workflow intact.
2. **Opt-in only** — don't bake; user runs the official brew installer per machine
   (works on atomic since it targets `/home/linuxbrew`). Leanest image, but brew is
   absent by default and any dotfiles assuming it must guard on its presence.
3. **Eliminate brew** — replace `claude-code` (npm global or official installer
   baked another way) and `framework-tool` (COPR/manual), drop brew entirely. Purest,
   but loses the easy path for tools Fedora doesn't package and adds bespoke installs.

## Recommendation

**Option 1**, thin. The whole point of baking the toolkit in 0007 was to stop brew
being load-bearing for the *core* CLI experience — but keep brew present for the
long tail Fedora/Flatpak don't cover.

## Implementation sketch

- Port Zirconium's approach to a `Containerfile`: fetch the Homebrew tarball at build
  time, `COPY` it under `/usr/share`, ship a `brew-setup.service` (+ tmpfiles / the
  `linuxbrew` group) that materializes `/var/home/linuxbrew` on first boot, and enable
  it in the system preset. Cross-check against ublue-os's current brew-install image
  code (the canonical reference for doing this on a plain Fedora bootc image).
- **dotfiles-steen (0014):** ship `environment.d/20-brew-path.conf` (PATH, from
  rheniite) and the residual cask/formula list (`claude-code`, `framework-tool`, …).

## Verification

- Fresh boot → `brew` on PATH in a login shell, `brew doctor` clean, `brew install`
  of a formula works, and `claude-code` + `framework-tool` install and run.
- Core toolkit (`eza`/`bat`/`lazygit`/…) resolves to the **image** copies, not brew
  (confirm 0007 wins on PATH order).
