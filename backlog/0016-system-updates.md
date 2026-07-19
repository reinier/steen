# System updates: keep the unified updater (uupd)

- **Status:** proposed
- **Created:** 2026-07-19
- **Area:** image (systemd preset, `uupd` package via Terra)
- **Depends:** 0001; interacts with 0007 (Terra wiring), 0011 (Flatpak), 0015 (brew)
- **Related:** Zirconium's presets enable `uupd.timer` and **disable** bootc
  auto-updates ([`inspiration/zirconium`](../../conium/inspiration/zirconium)
  `01-zirconium.preset`); Zirconium's `terra.conf` ships `uupd`;
  [ublue-os/uupd](https://github.com/ublue-os/uupd);
  [`../notes/zirconium-vs-steen-deltas.md`](../notes/zirconium-vs-steen-deltas.md) §2.

## Problem

rheniite got a **unified update experience from the Zirconium base**: `uupd`
(Universal Blue's updater) refreshes the bootc image **+ Flatpaks + brew** in one
timer-driven pass, with bootc's own auto-update disabled. The Sway Atomic base has
no uupd — left alone, "keep my system current" fragments into three separate
things: `bootc upgrade` (OS), `flatpak update`, `brew upgrade`.

## Options

1. **Port uupd** *(recommended)* — it's a **Terra** package, and Steen already
   wires Terra in [0007](0007-cli-toolkit-terra.md), so this is nearly free: install
   `uupd`, enable `uupd.timer` in the system preset, and disable bootc auto-update —
   mirroring Zirconium exactly. Keeps the update UX you already have muscle memory
   for; unified across image/Flatpak/brew.
2. **bootc timer + separate app updates** — enable
   `bootc-fetch-apply-updates.timer` for the OS and wire our own Flatpak/brew update
   units. Fedora-native, no extra tool, but not unified and more moving parts.
3. **Manual** — user runs the three commands when they want (wrap them in an
   `rl-update` helper in dotfiles). Most control, no surprise reboots staged, but
   nothing happens unattended.

## Recommendation

**Option 1.** uupd via Terra is cheap here and preserves the exact update behavior
rheniite/Zirconium have — the least-surprise choice, and it keeps brew (0015) and
Flatpaks (0011) in the same pass instead of drifting. Disable bootc auto-update so
the two mechanisms don't both stage updates.

> If Steen's "fewer upstream dependencies" ethos later wins out over continuity,
> option 3's `rl-update` wrapper is the clean fallback — no daemon, no ublue tool.

## Implementation sketch

- `dnf5 install uupd` (Terra, already enabled in 0007).
- System preset: `enable uupd.timer`; ensure bootc auto-update units are **disabled**
  (match Zirconium's preset).
- Confirm uupd's F44 defaults cover image + Flatpak + brew; adjust its config if the
  brew path differs from ublue's assumption (Steen bakes brew per 0015).

## Verification

- `systemctl is-enabled uupd.timer` → enabled; bootc auto-update disabled.
- A manual `uupd` run pulls a new signed image, updates Flatpaks, and runs
  `brew upgrade` in one pass; reboot lands on the new deployment.
