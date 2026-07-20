# System updates: two streams, updated manually and separately

- **Status:** accepted
- **Created:** 2026-07-19 (decision revised 2026-07-19 — manual, no uupd)
- **Area:** image (systemd preset: ensure auto-update timers are **off**)
- **Depends:** 0001; interacts with 0011 (Flatpak), 0015 (no brew)
- **Related:** Zirconium's presets enable `uupd.timer` + disable bootc auto-update
  ([`inspiration/zirconium`](../../conium/inspiration/zirconium) `01-zirconium.preset`);
  [`../notes/zirconium-vs-steen-deltas.md`](../notes/zirconium-vs-steen-deltas.md) §2.

## Decision

Steen has **two independent update streams**, each driven **manually** by the user,
on its own cadence — **no unified updater**:

- **OS (bootc):** `sudo bootc upgrade` → reboot.
- **Flatpaks:** `flatpak update`.

No `uupd`, and **no bundled wrapper** that runs both — they stay separate on purpose.
(There is no brew stream — Steen ships no Homebrew, [0015](0015-no-homebrew.md); any
distrobox containers self-update via their own package manager inside.)

## Why (changed from the earlier uupd recommendation)

The first pass recommended porting `uupd` to match Zirconium's unified,
timer-driven update UX. Revised: **manual + separate** is preferred.

- **Control / no surprises.** Nothing updates or stages a new deployment
  unattended; you choose when each stream moves, and can hold one back (e.g. pin the
  OS while still updating Flatpaks).
- **Independent cadence.** The OS and app streams have genuinely different risk
  profiles; decoupling them makes a regression easy to localize and roll back
  (`bootc rollback` for the OS alone).
- **One less upstream.** No ublue `uupd` dependency — consistent with Steen's
  "nothing between you and Fedora" ethos.

## Implementation sketch

- **Do not** install `uupd`; **do not** enable `uupd.timer`.
- **Ensure no auto-update timer is enabled** in the image — the Sway Atomic base may
  ship an rpm-ostree/bootc auto-update timer on by default. Explicitly **mask/disable**
  `bootc-fetch-apply-updates.timer` (and any `rpm-ostreed-automatic.timer`) in the
  system preset so updates only happen when invoked.
- Optional, if wanted later: **per-stream** aliases/functions in `dotfiles-steen`
  (e.g. `rl-os-update` and a Flatpak-update alias) — but keep them distinct commands,
  not one aggregate, per this decision.

## Verification

- Fresh boot: `systemctl list-timers` shows **no** OS auto-update timer active, and
  `uupd` is absent.
- Each stream updates on its own: `sudo bootc upgrade` stages a new signed image
  (reboot to apply); `flatpak update` runs independently. No `brew` present.
