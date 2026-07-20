# Hardware & session niceties: audit and re-add what matters

- **Status:** proposed
- **Created:** 2026-07-19
- **Area:** image (`Containerfile` packages, systemd preset, udev)
- **Depends:** 0002 (base plumbing audit is where "what does the base already give"
  gets answered)
- **Related:** Zirconium presets enable these across
  [`inspiration/zirconium`](../../conium/inspiration/zirconium) (`theme.conf`,
  `base-desktop.conf`, presets); Steen's input remapping is keyd
  ([0009](0009-keyd-tap-hold-super.md), replaces `input-remapper`);
  [`../notes/zirconium-vs-steen-deltas.md`](../notes/zirconium-vs-steen-deltas.md) §3.

## Problem

Zirconium's presets quietly enable a set of hardware/session niceties. Some come
free with the Sway Atomic base; others are Terra/extra packages that would
**silently vanish** on Steen. End-user symptom: "feature X that worked on Zirconium
is gone." This item is an **audit** (what does the base already provide, checked in
0002) followed by re-adding only what's actually used.

## In scope — audit, then re-add if missing

| Feature | Package | Expected on base | Action |
|---|---|---|---|
| **Fingerprint** | `fprintd` | likely yes | **must-have (Framework)** — verify + enable; enroll must work |
| **Firmware updates** | `fwupd` | likely yes | **must-have (Framework)** — verify `fwupdmgr get-devices`; set `DisableCapsuleUpdateOnDisk=true` in `/etc/fwupd/uefi_capsule.conf` for Framework BIOS |
| **Thunderbolt** | `bolt` | likely yes | verify device authorization works; add if missing |
| **Dev containers** | `distrobox` / `podman` | podman likely; distrobox maybe | **include** — with no brew ([0015](0015-no-homebrew.md)), distrobox is *the* path for ad-hoc CLI tooling; add `distrobox` (Fedora pkg), confirm `podman` |
| **External-monitor brightness** | `ddcutil` | probably not | add **only if** you drive external displays over DDC |
| **Screen autorotate** | `iio-niri` (Terra) | no | add **only if** on a convertible/tablet — a Framework 13 clamshell doesn't need it; default **drop** |

Input remapping is **not** here — keyd (0009) covers the Super remap; Zirconium's
`input-remapper` is not carried.

## Framework EC tool (`framework_tool`) — optional, not from Fedora

`framework_tool` / [`framework-system`](https://github.com/FrameworkComputer/framework-system)
is **not packaged in Fedora**. You don't need it for firmware — `fwupd`/LVFS (above) is
the supported update path. It only adds EC control (battery charge limits, fingerprint
LED, no-restart brightness/telemetry). If wanted, **source-build it** (pinned tag, the
keyd pattern in [0009](0009-keyd-tap-hold-super.md); build deps `systemd-devel
hidapi-devel`) — otherwise skip. Default: **skip**, revisit if you want EC tweaks.

## Explicitly dropped (decided 2026-07-19)

- **OpenRGB** (`openrgb`, `openrgb-udev-rules`) — no RGB peripherals to control.
- **CJK input** (`fcitx5` + `chinese-addons`/`mozc`/`rime`) — Dutch/English
  workflow; the whole IME stack is dead weight. (Re-add later if that changes.)

## Recommendation

Fold the "what does the base already ship" check into **0002**'s verify pass, then
here: **must-add** `fprintd` + `fwupd` + `bolt` if any are missing (Framework
essentials), **include** `distrobox` (the no-brew ad-hoc-tooling path, 0015),
**add-if-used** `ddcutil`, **default-skip** `framework_tool` and `iio-niri`
autorotate. Enable the relevant services in the system preset.

## Verification

- `fprintd-enroll` registers a fingerprint and it unlocks login/sudo.
- `fwupdmgr get-devices` lists the Framework's updatable firmware.
- (If added) `distrobox create` works; `ddcutil detect` sees an external monitor.
