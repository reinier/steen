# Native Chromium + free codecs

- **Status:** accepted
- **Created:** 2026-07-19 (Firefox dropped 2026-07-19)
- **Area:** image (`Containerfile`), `docs/third-party-repos.md`
- **Depends:** 0003 (chrome-* app_ids used by niri window-rules / dank-lader)
- **Related:** **carryover** from rheniite —
  [`Containerfile`](../../rheniite/rheniite/Containerfile) "Web browsers" stanza,
  [`backlog/chromium-free-codecs.md`](../../rheniite/rheniite/backlog/chromium-free-codecs.md).

## Port, not redesign

Native (non-Flatpak) `chromium` so it integrates with 1Password's native-messaging
and keeps the `chrome-*` app_ids niri window-rules and dank-lader (and the web-app
launchers) rely on. Fedora's chromium links the system ffmpeg (`ffmpeg-free`,
H.264/AAC stripped), so add **`libavcodec-freeworld`** from RPM Fusion **free**
(additive, no base-package swap) or Teams WebRTC video and `<video>` mp4 break.

```dockerfile
RUN dnf5 -y install "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
 && dnf5 -y install chromium libavcodec-freeworld \
 && rm -f /etc/yum.repos.d/rpmfusion-*.repo \
 && dnf5 clean all
```

## No Firefox

Firefox is **not** installed. The Sway Atomic base ships Firefox by default, so
**0002 removes it** — Steen ships a single native browser (Chromium). If a second
browser is ever wanted, it goes via Flatpak/Bazaar (0011), not the image.

## Changes vs rheniite

- Firefox dropped (rheniite shipped both `firefox` + `chromium`).
- Only the **free** RPM Fusion release is added, then removed (same as rheniite).
- Start `docs/third-party-repos.md` here (Steen's own version of rheniite's doc),
  since this is the first non-Fedora source. Also record the `dms-greeter` COPR
  from 0004 in it.
- Conscious call carried over: this bakes proprietary H.264/AAC into a hosted
  image (redistribution caveat) — same trade-off rheniite already accepted.

## Verification

- `chromium` plays an H.264 `<video>` and Teams shows video; 1Password native
  messaging works with no wrappers.
- No `firefox` binary on the system (confirm the base's copy was removed in 0002).
