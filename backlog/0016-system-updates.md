# System updates: two streams, updated manually and separately

- **Status:** done (implemented 2026-07-20; boot check in [0018](0018-first-boot-checklist.md) §F)
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

## Implemented (2026-07-20)

Audited the base's timers first (`dnf repoquery -l` on `bootc` + `rpm-ostree`): it
ships **`bootc-fetch-apply-updates.timer`** and **`rpm-ostreed-automatic.timer`** (plus
`rpm-ostree-countme.timer`, which is install-count telemetry, not an updater — left
alone). The Containerfile now **masks both** update timers:

```dockerfile
RUN systemctl mask bootc-fetch-apply-updates.timer rpm-ostreed-automatic.timer
```

Mask, not disable: masking symlinks the unit to `/dev/null` so it can't start even if
something pulls it in — the hard guarantee that nothing updates unattended. A guard
asserts both symlinks resolve to `/dev/null`, so a base that renamed a timer would fail
the build rather than silently ship with auto-updates live. `uupd` is not installed.

Optional, if wanted later: **per-stream** aliases in `dotfiles-steen` (e.g.
`rl-os-update` and a Flatpak-update alias) — kept as distinct commands, not one
aggregate, per this decision.

## Verification

- Fresh boot: `systemctl list-timers` shows **no** OS auto-update timer active, and
  `uupd` is absent.
- Each stream updates on its own: `sudo bootc upgrade` stages a new signed image
  (reboot to apply); `flatpak update` runs independently. No `brew` present.
