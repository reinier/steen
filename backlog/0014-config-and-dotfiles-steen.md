# Own the config: dotfiles-steen (derived from dotfiles-rheniite)

- **Status:** proposed
- **Created:** 2026-07-19 (seed corrected 2026-07-20 → dotfiles-rheniite)
- **Area:** new repo `dotfiles-steen` (chezmoi)
- **Depends:** 0003 (desktop), 0004 (session) — needs installed binaries to target
- **Related:**
  **[`/home/reinier/dev/rheniite/dotfiles-rheniite`](../../rheniite/dotfiles-rheniite)
  — the primary seed** (the latest, daily-driven niri + DMS personal config);
  [`dotfiles-bluefin-niri`](../../conium/dotfiles-bluefin-niri) (only for the one thing
  rheniite delegates to its image — see the gap below); rheniite
  [`backlog/own-desktop-config.md`](../../rheniite/rheniite/backlog/own-desktop-config.md).

## Seed: dotfiles-rheniite (authoritative)

`dotfiles-steen` is **derived from `/home/reinier/dev/rheniite/dotfiles-rheniite`** —
the current, actively-used niri + DankMaterialShell config, and the best-matched
starting point Steen has. It already fits Steen far better than bluefin-niri did in the
earlier plan, because it was written for the *same* image conventions Steen adopts:

- **keyd** (root system service), not bluefin's kanata — matches [0009](0009-keyd-tap-hold-super.md).
- **native 1Password** assumptions, not bluefin's distrobox workaround — matches [0006](0006-1password-native.md).
- **Synology Drive** wrapper + HiDPI fixup — matches [0008](0008-synology-drive.md).
- plus dank-lader, matugen theming, fish/kitty/starship, the `rl-*` helpers, and the
  `local/*.kdl` niri overrides.

**Version fit is good now.** An earlier draft worried that rheniite's config (written
against Zirconium's git-HEAD DMS/niri) would skew against Steen's *stable* binaries.
That concern has mostly evaporated: Steen runs **dms 1.5.2 / quickshell 0.3.0** (0003)
— near-HEAD, released two days before this was written — so it's very close to what
rheniite's config already targets, not the months-stale Fedora 1.4.4 the old draft
assumed. Still validate against the installed versions (`niri validate`, DMS logs), but
expect small deltas, not a rewrite.

## The one gap: the base niri config

`dotfiles-rheniite` ships **only the override layer** — `local.kdl` and
`local/{settings,startup,input,layout,binds,window-rules}.kdl`. It has **no top-level
`config.kdl`** and **no `dms/*.kdl`**, because on rheniite those come from the Zirconium
**image** (`/usr/share/zirconium/zdots`, applied to `$HOME`). Steen bakes **no** config
([decision below]), so niri would have nothing to load — `local/*.kdl` are includes,
not a standalone config.

So `dotfiles-steen` must additionally supply the base rheniite delegates to its image:
the top-level `config.kdl` (the include chain that pulls in `dms.kdl` + the base binds/
input/layout + `local.kdl` last) and the `dms/*.kdl`. Fill it from one of:

1. **`dotfiles-bluefin-niri`'s vendored copy** *(recommended)* — bluefin is also
   imageless and already vendors a full DMS-generated `config.kdl` + `dms/*.kdl` for
   exactly this reason. Take that base, drop rheniite's `local/*.kdl` on top. Cleanest,
   and both repos already share most of the rest.
2. **`dms setup`** on first run — regenerate the base per-user. Fewer vendored files to
   maintain, but it's a first-run step, and 0003's build showed `dms` is the COPR CLI
   whose `setup` behaviour should be verified on real hardware first.

Drop bluefin's kanata, 1Password-via-distrobox, GNOME-coexistence notes, and its
`rpm-ostree` layer / DMS-autostart script — all obsolete on Steen (keyd, native
1Password, niri-only, and 0004's preset handle those).

## Also owned here

- **The Flatpak app list**, incl. **Bazaar** (`io.github.kolunmi.Bazaar`, first in the
  list — it's the store itself). Image ships Flatpak + the Flathub remote;
  dotfiles pick the apps ([0011](0011-bazaar-flatpak-appstore.md)).
- **Timezone**, only if a machine needs it — a one-line `timedatectl set-timezone`
  ([0013](0013-first-boot-defaults.md) was dropped; the installer sets it).

## Decision: baked defaults vs dotfiles-only

- **A. Bake a default config into `/usr/share/steen/…`** (Zirconium's model), overrides
  on top — usable desktop before `chezmoi apply`.
- **B. Dotfiles-only** — image ships binaries, all config from `dotfiles-steen`.
- **Recommend B** (image stays a clean package layer; config iterates without image
  rebuilds). The greeter already vendors its own config in 0004, so a bare pre-`chezmoi`
  desktop is acceptable. This is *why* the gap above exists and must be closed in the
  dotfiles rather than the image.

## Verification

- Fresh Steen install + `chezmoi apply` from `dotfiles-steen` → niri/DMS come up themed
  and bound, dank-lader works, keyd active, `niri validate` clean, no DMS schema errors.
