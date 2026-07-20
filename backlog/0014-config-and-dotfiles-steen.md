# Own the config: dotfiles-steen (derived from dotfiles-rheniite)

- **Status:** in-progress (repo created + pushed 2026-07-20; real-boot validation pending, [0018](0018-first-boot-checklist.md) §G)
- **Created:** 2026-07-19 (seed corrected 2026-07-20 → dotfiles-rheniite; base-config approach revised 2026-07-20 → DMS defaults)
- **Repo:** `ssh://forgejo@forge.personalos.nl:1982/reinierladan/dotfiles-steen.git` (checked out at `../../dotfiles-steen`)
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

## Resolved (2026-07-20): DMS generates the base, dotfiles ship only overrides

The earlier plan was to vendor bluefin's `config.kdl` + `dms/*.kdl`. **Rejected in favour
of `dms setup`** — vendoring a copy of DMS's defaults drifts against the installed DMS
version (the 1.4→1.5 skew), which is exactly the trap this whole item exists to avoid.

Instead (implemented in the repo):

- `dotfiles-steen` ships **only** `local.kdl` + `local/*.kdl` (the overrides), same as
  rheniite.
- `run_once_after_niri-dms-config.sh` runs **`dms setup --non-interactive`**, which
  deploys the version-correct `config.kdl` + the required `dms/*.kdl` **non-destructively**
  ("only writes files that don't already exist or are empty"), then **appends
  `include "local.kdl"`** to `config.kdl` (DMS's default doesn't include a user file), so
  overrides load last. Idempotent, so it's correct regardless of DMS's include behaviour.
- Verified from the `dms` binary: `dms setup` exists with a `--non-interactive` flag and
  deploys the niri "main config" + defaults; still to confirm on real hardware that the
  generated config.kdl + our appended include validate under DMS 1.5.2 ([0018](0018-first-boot-checklist.md) §G).

## What was copied vs adapted

Copied from `dotfiles-rheniite` wholesale: niri `local/*.kdl`, dank-lader, matugen,
fish/kitty/starship, `rl-*` helpers, keyd mapping, network/udev, web-app launchers, ssh
config. **Adapted:** dropped the brew PATH drop-in + the whole brew block in
firstrun-setup (no Homebrew); dropped the dead Nextcloud autostart and Firefox refs
(Steen has neither); added Bazaar to the Flatpak list; swept rheniite→steen wording.

## Known image gaps surfaced by the dotfiles

The firstrun dependency check expects `fzf` and `xdg-terminal-exec`, which the first
image cut didn't include. **Added to 0007** (both are in Fedora main).

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
