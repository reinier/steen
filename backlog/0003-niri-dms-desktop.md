# niri from Fedora; DMS + quickshell from upstream's stable COPRs

- **Status:** in-progress (implemented 2026-07-20; real-boot checks in
  [0018](0018-first-boot-checklist.md))
- **Created:** 2026-07-19 (DMS source revised 2026-07-20 — see "Revision" below)
- **Area:** image (`Containerfile`, `files/avengemedia-*.repo`)
- **Depends:** 0002
- **Related:** the stable-Fedora layering in
  [`dotfiles-bluefin-niri`](../../conium/dotfiles-bluefin-niri) and its
  `notes/gnome-coexistence.md` (the 2026-06-12 breakage that motivates the version
  guard below); rheniite
  [`backlog/stabilize-git-packages.md`](../../rheniite/rheniite/backlog/stabilize-git-packages.md).

## What's installed

```dockerfile
# Fedora:  niri kitty xwayland-satellite
# COPR:    dms (avengemedia/dms) + quickshell (avengemedia/danklinux)
```

**`xwayland-satellite` is not optional.** niri has *no* built-in Xwayland — unlike
sway/Hyprland it delegates X11 entirely to the satellite, which drives the
`xorg-x11-server-Xwayland` already in the base. Installing it is necessary but not
sufficient: something must *start* it (niri config / dotfiles), which is why "an X11
app actually displays" is a first-boot check.

## Revision (2026-07-20): why DMS no longer comes from Fedora

The item originally took the whole desktop from Fedora main — the headline win of
basing on Fedora. That held for niri and still does (**26.04**, current). It did
**not** hold for DMS:

| | Fedora 44 | Upstream stable |
|---|---|---|
| DankMaterialShell / dms | **1.4.4** (2026-03-21) | **1.5.2** (2026-07-18) |
| quickshell | **0.2.1^git20260209** | **0.3.0** (2026-05-04) |

Fedora is ~4 months and five releases behind, so Steen takes DMS from upstream.

**The trap this item now guards against:** DMS 1.5.x is built against quickshell
0.3.x. Installing COPR `dms` 1.5 on top of Fedora's quickshell 0.2.1 is precisely the
skew that crashed the shell on 2026-06-12 and pushed `dotfiles-bluefin-niri` off the
DMS COPR. So dms and quickshell are taken **as a matched pair** from upstream's
**stable, tagged-release** COPRs (`avengemedia/dms` + `avengemedia/danklinux`) —
explicitly *not* the rolling `dms-git`/`quickshell-git`.

The Containerfile guard **enforces** this: it fails the build unless `dms` is 1.5.x
*and* `quickshell` is 0.3.x, and unless Fedora's `DankMaterialShell` is absent (two
shells installed side by side would be worse than either alone). The pairing can
therefore never silently regress.

## Consequences

- **Steen's desktop core is no longer COPR-free.** `avengemedia/danklinux` was already
  going to be pulled in for `dms-greeter` (0004), so this adds one repo
  (`avengemedia/dms`) rather than a whole new class of dependency — but the "100%
  Fedora desktop" claim in the README and 0000 is retired. Both repos are added for the
  one transaction and **deleted afterwards**; the booted system has no COPRs configured.
- **We now own version-matching.** When DMS releases, check quickshell's required
  version before bumping. The guard turns a mismatch into a failed build, not a broken
  desktop.
- **Escape hatch:** if the COPR pairing proves unstable, drop back to Fedora's
  `DankMaterialShell` + `quickshell` (older but co-tested) by reverting this layer.

## The `dms` CLI

`dms` is the Go CLI/daemon behind `dms ipc`, theming and shell control — every
dank-lader entry and niri keybind depends on it. Fedora's `DankMaterialShell` shipped
`/usr/bin/dms` directly (confirmed in the build log). The COPR historically split
`dms` and `dms-cli`, so the install tolerantly adds `dms-cli` if such a package exists
and the guard hard-fails if `command -v dms` comes up empty either way.

## Verification

CI (done): packages resolve, versions match the guarded pairing, `niri`/`dms` binaries
exist, image lints and signs.

Real hardware ([0018](0018-first-boot-checklist.md)): DMS bar/launcher/notifications
come up, matugen theming applies, `niri msg` and `dms ipc` respond, an X11 app displays.
