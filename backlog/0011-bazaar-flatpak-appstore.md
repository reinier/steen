# Bazaar + Flatpak/Flathub (replaces native VSCodium)

- **Status:** in-progress (image side done 2026-07-20; Bazaar delegated to dotfiles, 0014)
- **Created:** 2026-07-19
- **Area:** image (`Containerfile`, flatpak preinstall, systemd unit)
- **Depends:** 0002
- **Related:** rheniite bakes native `codium` from the VSCodium repo —
  **Steen drops that**; Zirconium's `flatpak-add-flathub-repos` /
  `flatpak-preinstall` presets are the precedent for wiring Flathub in an image.

## Decision

Steen does **not** bake native VSCodium. Instead it ships **Bazaar**
([github.com/kolunmi/bazaar](https://github.com/kolunmi/bazaar), the Flatpak-first
app store Bazzite popularized) and apps are installed as **Flatpaks from Flathub**
(VSCodium included, if wanted, as `com.vscodium.codium`). This trades native-host
integration (real host terminal in VSCodium — rheniite's stated reason for going
native) for a simpler, sandboxed, self-service app model.

> Consequence to accept: a Flatpak VSCodium's integrated terminal is **sandboxed**,
> not the host shell — `op`/podman/distrobox won't be on its `PATH` the way
> rheniite's native codium had them. If that matters, either keep a Flatpak
> `--talk-name`/`flatpak-spawn` shim in dotfiles or reconsider native codium. Note
> it and move on.

## Implemented (2026-07-20) — image side complete

**The image ships the Flathub remote**, configured via
`/etc/flatpak/remotes.d/flathub.flatpakrepo` rather than `flatpak remote-add`, because
the latter writes to `/var/lib/flatpak` — machine-local state a bootc image can't ship.
So Flathub is present on first boot with no per-user step, and `flatpak install` works
immediately.

## Decision (2026-07-20): Bazaar comes from the dotfiles

**Bazaar is not in Fedora 44** (verified), so a native RPM isn't an option — it can
only come from Flathub as a Flatpak, which can't be installed at image build time for
the same `/var` reason.

Settled: **`io.github.kolunmi.Bazaar` goes in `dotfiles-steen`'s Flatpak list**
([0014](0014-config-and-dotfiles-steen.md)), alongside the rest of the personal app
set. The alternative — a first-boot oneshot unit that installs it after
network-online — is **rejected**: it's boot-time machinery CI can't verify, for an app
the dotfiles install anyway on the same first-run pass.

This keeps the split clean and consistent with every other app:

| Layer | Owns |
|---|---|
| **Image** | Flatpak itself + the Flathub remote (system plumbing) |
| **Dotfiles** | the app list, Bazaar included (personal choice, changes without an image rebuild) |

So nothing further is needed here; the remaining work is a line in the dotfiles repo.

## Implementation sketch

- Ensure `flatpak` is installed (0002) and add the **Flathub** remote in the image
  (Zirconium's `flatpak-add-flathub-repos` approach — system remote, so it's there
  at first boot without a per-user step).
- The Flatpak app set (Bazaar, plus the list rheniite's dotfiles install: Slack,
  Mattermost, Obsidian, LibreOffice, gThumb, DejaDup, smile, Gradia, …) lives in
  `dotfiles-steen` — see the decision above and [0014](0014-config-and-dotfiles-steen.md).

## Verification

- Bazaar launches, sees Flathub, installs/removes a Flatpak. Flathub remote is
  present on a fresh boot with no manual `flatpak remote-add`.
