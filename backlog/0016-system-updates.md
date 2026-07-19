# System updates: three streams, updated manually and separately

- **Status:** accepted
- **Created:** 2026-07-19 (decision revised 2026-07-19 — manual, no uupd)
- **Area:** image (systemd preset: ensure auto-update timers are **off**)
- **Depends:** 0001; interacts with 0011 (Flatpak), 0015 (brew)
- **Related:** Zirconium's presets enable `uupd.timer` + disable bootc auto-update
  ([`inspiration/zirconium`](../../conium/inspiration/zirconium) `01-zirconium.preset`);
  [`../notes/zirconium-vs-steen-deltas.md`](../notes/zirconium-vs-steen-deltas.md) §2.

## Decision

Steen has **three independent update streams**, each driven **manually** by the user,
on its own cadence — **no unified updater**:

- **OS (bootc):** `sudo bootc upgrade` → reboot.
- **Flatpaks:** `flatpak update`.
- **Homebrew:** `brew upgrade`.

No `uupd`, and **no bundled wrapper** that runs all three — they stay separate on
purpose.

## Why (changed from the earlier uupd recommendation)

The first pass recommended porting `uupd` to match Zirconium's unified,
timer-driven update UX. Revised: **manual + separate** is preferred.

- **Control / no surprises.** Nothing updates or stages a new deployment
  unattended; you choose when each stream moves, and can hold one back (e.g. pin the
  OS while still updating Flatpaks).
- **Independent cadence.** The OS, app, and CLI-tool streams have genuinely
  different risk profiles; decoupling them makes a regression easy to localize and
  roll back (`bootc rollback` for the OS alone).
- **One less upstream.** No ublue `uupd` dependency — consistent with Steen's
  "nothing between you and Fedora" ethos.

## Implementation sketch

- **Do not** install `uupd`; **do not** enable `uupd.timer`.
- **Ensure no auto-update timer is enabled** in the image — the Sway Atomic base may
  ship an rpm-ostree/bootc auto-update timer on by default. Explicitly **mask/disable**
  `bootc-fetch-apply-updates.timer` (and any `rpm-ostreed-automatic.timer`) in the
  system preset so updates only happen when invoked.
- Optional, if wanted later: **per-stream** aliases/functions in `dotfiles-steen`
  (e.g. `rl-os-update`, and shell aliases for the Flatpak/brew ones) — but keep them
  distinct commands, not one aggregate, per this decision.

## Verification

- Fresh boot: `systemctl list-timers` shows **no** OS auto-update timer active, and
  `uupd` is absent.
- Each stream updates on its own: `sudo bootc upgrade` stages a new signed image
  (reboot to apply); `flatpak update` and `brew upgrade` run independently.
