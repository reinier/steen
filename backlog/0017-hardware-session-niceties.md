# Hardware & session niceties: audit and re-add what matters

- **Status:** done (distrobox added + CI-green 2026-07-20; hardware verified in [0018](0018-first-boot-checklist.md))
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
| **Fingerprint** | `fprintd` 1.94.5 | **PRESENT** ✅ | nothing to install — just verify enroll works on hardware |
| **Firmware updates** | `fwupd` 2.1.6 | **PRESENT** ✅ | nothing to install; set `DisableCapsuleUpdateOnDisk=true` in `/etc/fwupd/uefi_capsule.conf` for Framework BIOS |
| **Thunderbolt** | `bolt` 0.9.11 | **PRESENT** ✅ | nothing to install — verify device authorization |
| **Dev containers** | `distrobox` | **ABSENT** (base has `podman` 5.8.4 + `toolbox`) | **add `distrobox`** — with no brew ([0015](0015-no-homebrew.md)) it's *the* path for ad-hoc CLI tooling |
| **External-monitor brightness** | `ddcutil` | **ABSENT** | add **only if** you drive external displays over DDC |
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

**The audit (2026-07-20) shrank this item a lot:** `fprintd`, `fwupd` and `bolt` —
the three Framework must-haves — are **already in the base**, so nothing to install.
What's left: **add `distrobox`** (the no-brew ad-hoc-tooling path, 0015),
**add-if-used** `ddcutil`, **default-skip** `framework_tool` and `iio-niri`
autorotate. Verify the present services are enabled in the system preset, and confirm
fingerprint/thunderbolt actually work once the desktop boots.

## Verification

- `fprintd-enroll` registers a fingerprint and it unlocks login/sudo.
- `fwupdmgr get-devices` lists the Framework's updatable firmware.
- (If added) `distrobox create` works; `ddcutil detect` sees an external monitor.
