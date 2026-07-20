# Zirconium → Steen: end-user deltas

What actually *changes for the person using the machine* when moving off the
Zirconium-based [rheniite](../../rheniite/rheniite) to Steen. This is analysis /
reference — decisions and implementation live in [`../backlog/`](../backlog/).
Where a delta needs work, the target backlog item is named.

Steen's base and stack are decided in
[`../backlog/0000-base-image-choice.md`](../backlog/0000-base-image-choice.md):
**Fedora Sway Atomic** base, **niri + DMS from Fedora stable** (not git COPRs).

---

## 1. The headline: stable vs git *feel*

The delta you notice most. Zirconium runs niri/DMS from git-HEAD COPRs
(`yalter/niri-git`, `avengemedia/{danklinux,dms-git}`) — thousands of commits ahead
of Steen's Fedora stable (**DMS `1.4.4`, niri `26.04`, quickshell** as F44 ships).

- **Fast → calm.** No same-day DMS features/fixes, but also none of the "woke up to
  a broken shell" churn — the `2026-06-12` breakage that pushed `dotfiles-bluefin-niri`
  off the git COPR can't happen. Features can lag Fedora's cadence by weeks–months.
- **Config schema is pinned.** `config.kdl` options and `dms ipc` verb names must
  match the stable versions; a dank-lader entry or keybind calling a git-only verb
  silently no-ops until reworked. → owned in
  [`0014`](../backlog/0014-config-and-dotfiles-steen.md).
- **DMS plugins** must be version-matched to `1.4.x`.

*Status: partly covered (0003 pins the packages, 0014 owns the config).*

---

## 2. GAP — how you update the machine

Captured in [`0016`](../backlog/0016-system-updates.md). A daily-touch surface that
changes shape.

- **Zirconium:** enables **uupd** (Universal Blue's unified updater — image +
  Flatpaks + brew in one timer-driven pass) and *disables* bootc auto-update.
- **Steen (Sway Atomic base):** no uupd, and no brew either. Two streams updated
  **separately**: the OS and Flatpaks. "Keep my system current" goes from one thing
  to two.

**Decided:** two independent streams (`bootc upgrade` / `flatpak update`), updated
**manually and separately** — no uupd, no auto-update timer, no brew stream. The
fragmentation is intentional: independent cadence, easy rollback, one less upstream.
→ [`0016-system-updates.md`](../backlog/0016-system-updates.md).

---

## 3. GAP — hardware & session niceties Zirconium's presets enabled

Captured in [`0017`](../backlog/0017-hardware-session-niceties.md). Zirconium's
system/user presets quietly turn on a pile of things; some would **silently vanish**
on Steen because they're Terra/extra packages, not part of the Sway Atomic base.

| Feature | Package | On Sway Atomic base? | Symptom if dropped |
|---|---|---|---|
| Fingerprint | `fprintd` | likely yes | fingerprint login/sudo gone |
| Firmware updates | `fwupd` | likely yes | no `fwupd` firmware updates |
| Thunderbolt | `bolt` | likely yes | TB device authorization gone |
| Containers | `distrobox` / `podman` | podman likely, distrobox maybe | `distrobox`/`podman` missing |
| External-monitor brightness | `ddcutil` | probably not | can't dim an external display |
| Screen autorotate | `iio-niri` (Terra) | no — must add | tablet/convertible won't rotate |
| Key remapping | `input-remapper` | n/a — keyd ([0009](../backlog/0009-keyd-tap-hold-super.md)) covers the Super remap | — |

End-user symptom if missed: "feature X that worked on Zirconium is gone." On the
**Framework** specifically, `fprintd` + `fwupd` are the ones not to lose silently.

**Dropped (decided 2026-07-19):** OpenRGB (`openrgb`, no RGB gear) and CJK input
(`fcitx5` + addons, Dutch/English workflow). Both are re-addable later if needs
change.

---

## Covered elsewhere (no surprise)

- **Login experience** — identical (greetd + dms-greeter, straight into niri):
  [`0004`](../backlog/0004-greetd-dms-greeter-login.md).
- **Homebrew** — Zirconium supplied it via its base; Steen ships **none**. The
  toolkit is baked from Fedora/Terra and ad-hoc tooling moves to distrobox:
  [`0015`](../backlog/0015-no-homebrew.md).
- **App set** — deliberate ([`0005`](../backlog/0005-browsers-and-codecs.md)–
  [`0012`](../backlog/0012-printer-gui.md)); notably Bazaar/Flatpak replaces native
  VSCodium ([`0011`](../backlog/0011-bazaar-flatpak-appstore.md)).
- **First-boot readiness** — usable-out-of-the-box (Zirconium bakes `zdots` + a daily
  re-apply timer) vs. bare-until-`chezmoi`; the open A/B in
  [`0014`](../backlog/0014-config-and-dotfiles-steen.md).

---

## What actually gets *better*

- **Fedora-supported desktop.** niri/DMS bugs go to Fedora's tracker; you stop being
  the COPR-git tester.
- **No config drift.** Zirconium re-applies its baked `zdots` to `$HOME` on a daily
  timer — the desktop can shift under you. Steen's config is yours, changing only when
  you run chezmoi.
- **One less upstream.** Nothing sits between you and Fedora — no Zirconium project to
  track, fork, or fall back from.
