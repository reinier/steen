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

## Resolved (2026-07-20, the hard way): vendor the config — `dms setup` can't run on atomic

Two wrong turns before landing here, both instructive:

1. Planned to vendor bluefin's config → **switched to `dms setup`** on the theory it'd
   generate a version-correct base at first launch, avoiding drift.
2. On real hardware `dms setup` **failed outright**: DMS's CLI policy
   (`/usr/share/dms/cli-policy.json`) **disables it on ostree/immutable systems** —
   *"Detected immutable system: /run/ostree-booted is present … disabled on image-based
   systems. Use your distro-native workflow for system-level changes."* There is **no
   runtime config generation on Steen at all.**

So the config **must be shipped statically** — which is precisely what bluefin's
"vendored because `dms setup` can't run on the atomic base" comment meant all along.

Implemented: `dotfiles-steen` **vendors** `config.kdl` + `dms/binds.kdl` +
`dms/create_{colors,layout,alttab}.kdl` (from bluefin); chezmoi deploys them; the
dms-setup script is deleted. The 1.4→1.5 drift is handled by patching known deltas
(`Mod+Y`: `dankdash` → `dash toggle wallpaper`, confirmed against the 1.5.2 binary) and
flagged for validation — a dead DMS keybind = another renamed IPC verb to fix in
`dms/binds.kdl`. The DMS-owned dynamic includes are `optional=true` so a not-yet-
generated file never breaks niri startup.

**Open alternative if drift becomes a maintenance burden:** `/run/ostree-booted` is
*absent* during the container build, so `dms setup` might run at **image build time** —
letting the image bake version-correct defaults on every DMS bump. Unverified (needs
compositor detection at build); parked.

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
