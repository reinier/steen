# backlog

The build plan for **Steen** — one Markdown item per piece of work. These are
image-level concerns (the `Containerfile`, baked packages, repos, signing,
first-boot defaults). Per-user config lives in the separate `dotfiles-steen`
repo, not here (see [`0014-config-and-dotfiles-steen.md`](0014-config-and-dotfiles-steen.md)).

Convention borrowed wholesale from
[rheniite's backlog](../../rheniite/rheniite/backlog/README.md).

## Conventions

- **One item per file**, `NNNN-kebab-case.md`. The `NNNN` prefix is a **rough
  build order**, not a hard dependency graph — read `Depends` in each item.
- Start each item with a short frontmatter-style block:
  - `Status:` proposed | accepted | in-progress | done | dropped
  - `Created:` `YYYY-MM-DD` (absolute dates — no "last week")
  - `Area:` what it touches (e.g. `image (Containerfile)`)
  - `Depends:` earlier items that must land first
  - `Related:` links to the rheniite/Zirconium precedent, upstream issues
- Then the body: **Problem → Options (with trade-offs) → Recommendation →
  Implementation sketch → Verification.** Include concrete commands/package
  names so the item is actionable, not aspirational.
- When an item ships, set `Status: done` (with the implementing commit) or delete
  it — don't leave stale plans lying around.

## Where the work already exists

Most items are a **translation**, not a fresh design:

- **Carryover from rheniite** (browsers, 1Password, Synology, keyd, Tailscale,
  printer, signing): the analysis is already done in
  [`../../rheniite/rheniite`](../../rheniite/rheniite) — the item's job is to port
  the Containerfile stanza onto Steen's Sway Atomic base and note what changes.
- **Base + desktop adaptation**: the base is **Fedora Sway Atomic** (see
  [`0000`](0000-base-image-choice.md)), which already ships the desktop plumbing —
  so `0002` *subtracts* the Sway defaults DMS replaces and *adds* niri's two
  missing bits, rather than building a desktop from bare metal. Zirconium's
  `theme.conf` `Remove=` list is the precedent for the subtraction.

## Items (rough build order)

0. [0000-base-image-choice.md](0000-base-image-choice.md) — **decision record**:
   why `FROM quay.io/fedora-ostree-desktops/sway-atomic` over `fedora-bootc` or a
   stripped Silverblue. Everything below rests on this.
1. [0001-bootstrap-signed-image.md](0001-bootstrap-signed-image.md) — a **signed,
   bootable** image `FROM sway-atomic` + CI. The foundation (boots to the inherited
   desktop before the niri swap).
2. [0002-base-desktop-plumbing.md](0002-base-desktop-plumbing.md) — adapt the base:
   subtract the Sway defaults DMS replaces (waybar/rofi/dunst/swaylock…), swap
   Thunar→nautilus, add `xdg-desktop-portal-gnome`; verify the inherited plumbing.
3. [0003-niri-dms-desktop.md](0003-niri-dms-desktop.md) — niri + DankMaterialShell
   + quickshell + kitty + xwayland-satellite. niri from Fedora; **dms 1.5.2 +
   quickshell 0.3.0 as a matched pair from upstream's stable COPRs**.
4. [0004-greetd-dms-greeter-login.md](0004-greetd-dms-greeter-login.md) — greetd +
   dms-greeter, boot straight into niri (the one desktop COPR exception).
5. [0005-browsers-and-codecs.md](0005-browsers-and-codecs.md) — native chromium +
   `libavcodec-freeworld` (RPM Fusion); Firefox dropped (and removed from the base).
6. [0006-1password-native.md](0006-1password-native.md) — native 1Password + CLI,
   `/opt` relocation, setuid/setgid, `ptrace_scope=1`.
7. [0007-cli-toolkit-terra.md](0007-cli-toolkit-terra.md) — fish/eza/bat/jq/… +
   starship/lazygit/yazi; wire Terra ourselves (no Zirconium base to inherit it).
8. [0008-synology-drive.md](0008-synology-drive.md) — native Synology Drive (COPR)
   with the `/opt` relocation.
9. [0009-keyd-tap-hold-super.md](0009-keyd-tap-hold-super.md) — keyd built from
   source (pinned tag), tap-hold Super key.
10. [0010-tailscale.md](0010-tailscale.md) — Tailscale baked and `tailscaled` enabled.
11. [0011-bazaar-flatpak-appstore.md](0011-bazaar-flatpak-appstore.md) — Flatpak +
    Flathub + **Bazaar** app store (replaces native VSCodium).
12. [0012-printer-gui.md](0012-printer-gui.md) — `system-config-printer` GUI.
13. [0013-first-boot-defaults.md](0013-first-boot-defaults.md) — **dropped**: timezone → dotfiles, NTP → verify (Fedora default).
    any first-boot sysctl/tmpfiles.
14. [0014-config-and-dotfiles-steen.md](0014-config-and-dotfiles-steen.md) — own the
    stable-targeted niri/DMS config; derive `dotfiles-steen` from `dotfiles-rheniite` (the current daily-driver config).
15. [0015-no-homebrew.md](0015-no-homebrew.md) — **no** Homebrew: toolkit baked from
    Fedora/Terra (0007), Nerd Font baked (0002), ad-hoc tooling via distrobox (0017).
16. [0016-system-updates.md](0016-system-updates.md) — two independent update streams
    (bootc / Flatpak), updated manually and separately; no uupd, no auto-update timer.
17. [0017-hardware-session-niceties.md](0017-hardware-session-niceties.md) — audit +
    re-add fingerprint/firmware/thunderbolt/etc.; OpenRGB and CJK dropped.
18. [0018-first-boot-checklist.md](0018-first-boot-checklist.md) — **living**
    collection point for everything that can only be verified on real hardware.
19. [0019-file-indexer-localsearch.md](0019-file-indexer-localsearch.md) — **decision
    deferred**: leave the tracker/`localsearch` indexer running, exclude heavy dirs, or
    mask it. Currently at the upstream default (runs).
20. [0020-fork-upstream-artifacts.md](0020-fork-upstream-artifacts.md) — pull keyd /
    Nerd Font / lazygit from personal forks (supply-chain control), not upstream URLs.

## Closing items

CI going green proves packages resolve and the image lints — not that niri starts or
the fingerprint reader enrolls. So: **an item may be closed once it's implemented and
CI-green, provided its real-hardware checks are migrated to
[`0018`](0018-first-boot-checklist.md).** That keeps the build moving without quietly
losing track of what hasn't actually been proven.
